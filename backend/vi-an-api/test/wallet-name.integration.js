import test from "node:test";
import assert from "node:assert/strict";
import { MongoClient } from "mongodb";
import { MongoMemoryReplSet } from "mongodb-memory-server";
import { initialize } from "../src/migrate.js";
import { buildApp } from "../src/app.js";
import { randomUUID } from "node:crypto";

const CASH = "000000000000000000000002",
  BANK = "000000000000000000000003";

test(
  "Không cho tạo hai ví trùng tên; đổi tên cũng bị chặn",
  { timeout: 300000 },
  async (t) => {
    const repl = await MongoMemoryReplSet.create({
      binary: {
        version: process.env.MONGOMS_VERSION || "8.0.13",
        downloadDir:
          process.env.MONGOMS_DOWNLOAD_DIR || "/tmp/vi-an-mongodb-binaries",
      },
      replSet: { count: 1 },
    });
    const client = new MongoClient(repl.getUri(), { promoteLongs: false });
    await client.connect();
    const db = client.db("vi_an_wallet_name_test");
    let app;
    t.after(async () => {
      await app?.close();
      await client.close();
      await repl.stop();
    });
    await initialize(db, { seed: true });
    app = await buildApp(
      { client, db, transactionCapable: true, backupSecret: "wallet-secret" },
      {
        allowDemo: true,
        jwtSecret: "integration-only-secret-at-least-32-characters",
      },
    );
    const token = (
      await app.inject({ method: "POST", url: "/api/v1/auth/demo", payload: {} })
    ).json().data.accessToken;

    async function call(method, url, body, expected = 200) {
      const res = await app.inject({
        method,
        url: "/api/v1" + url,
        headers: {
          authorization: "Bearer " + token,
          "idempotency-key": randomUUID(),
        },
        ...(body ? { payload: body } : {}),
      });
      assert.equal(res.statusCode, expected, res.body);
      return res.json().data;
    }

    const create = (name, expected = 200) =>
      call(
        "POST",
        "/wallets",
        {
          name,
          type: "cash",
          openingBalance: "0",
          openingAt: new Date(Date.now() - 86400000).toISOString(),
        },
        expected,
      );

    await t.test("seed sẵn hai ví khác tên", async () => {
      const wallets = await call("GET", "/wallets");
      assert.equal(wallets.length, 2);
      assert.deepEqual(
        wallets.map((w) => w.name).sort(),
        ["Tài khoản thanh toán", "Ví tiền mặt"],
      );
    });

    await t.test("tạo ví trùng tên chính xác bị chặn 409", async () => {
      const res = await app.inject({
        method: "POST",
        url: "/api/v1/wallets",
        headers: {
          authorization: "Bearer " + token,
          "idempotency-key": randomUUID(),
        },
        payload: {
          name: "Ví tiền mặt",
          type: "cash",
          openingBalance: "0",
          openingAt: new Date(Date.now() - 86400000).toISOString(),
        },
      });
      assert.equal(res.statusCode, 409, res.body);
      assert.equal(res.json().error.code, "DUPLICATE_WALLET_NAME");
      const wallets = await call("GET", "/wallets");
      assert.equal(wallets.length, 2, "không tạo thêm ví");
    });

    await t.test("trùng tên không phân biệt hoa/thường và khoảng trắng",
      async () => {
        const res = await app.inject({
          method: "POST",
          url: "/api/v1/wallets",
          headers: {
            authorization: "Bearer " + token,
            "idempotency-key": randomUUID(),
          },
          payload: {
            name: "  ví TIỀN mặt  ",
            type: "cash",
            openingBalance: "0",
            openingAt: new Date(Date.now() - 86400000).toISOString(),
          },
        });
        assert.equal(res.statusCode, 409, res.body);
        assert.equal(res.json().error.code, "DUPLICATE_WALLET_NAME");
      },
    );

    await t.test("tên khác thì tạo bình thường", async () => {
      const w = await create("Ví dự phòng");
      assert.equal(w.name, "Ví dự phòng");
      assert.equal((await call("GET", "/wallets")).length, 3);
    });

    await t.test("đổi tên sang tên ví khác bị chặn, giữ nguyên tên cũ",
      async () => {
        const created = (await call("GET", "/wallets")).find(
          (w) => w.name === "Ví dự phòng",
        );
        const res = await app.inject({
          method: "PATCH",
          url: "/api/v1/wallets/" + created._id,
          headers: {
            authorization: "Bearer " + token,
            "idempotency-key": randomUUID(),
          },
          payload: { name: "Tài khoản thanh toán",  },
        });
        assert.equal(res.statusCode, 409, res.body);
        assert.equal(res.json().error.code, "DUPLICATE_WALLET_NAME");
        const after = (await call("GET", "/wallets")).find(
          (w) => w._id === created._id,
        );
        assert.equal(after.name, "Ví dự phòng", "tên không bị đổi");
      },
    );

    await t.test("đổi tên chỉ khác hoa/thường của chính nó thì được phép",
      async () => {
        const created = (await call("GET", "/wallets")).find(
          (w) => w.name === "Ví dự phòng",
        );
        const updated = await call(
          "PATCH",
          "/wallets/" + created._id,
          { name: "VÍ DỰ PHÒNG" },
        );
        assert.equal(updated.name, "VÍ DỰ PHÒNG");
      },
    );

    await t.test("ví đã lưu trữ không chặn tên mới", async () => {
      const created = (await call("GET", "/wallets")).find(
        (w) => w.name === "VÍ DỰ PHÒNG",
      );
      // Số dư 0 nên lưu trữ được.
      await call("PATCH", "/wallets/" + created._id, {
        status: "archived",
      });
      const reused = await create("VÍ DỰ PHÒNG");
      assert.equal(reused.name, "VÍ DỰ PHÒNG");
      const all = await call("GET", "/wallets");
      assert.equal(
        all.filter((w) => w.name === "VÍ DỰ PHÒNG").length,
        2,
        "một lưu trữ, một đang hoạt động",
      );
    });

    await t.test("tên rỗng (chỉ khoảng trắng) bị từ chối", async () => {
      const res = await app.inject({
        method: "POST",
        url: "/api/v1/wallets",
        headers: {
          authorization: "Bearer " + token,
          "idempotency-key": randomUUID(),
        },
        payload: {
          name: "   ",
          type: "cash",
          openingBalance: "0",
          openingAt: new Date(Date.now() - 86400000).toISOString(),
        },
      });
      assert.equal(res.statusCode, 422, res.body);
      const active = (await call("GET", "/wallets")).filter(
        (w) => w.status === "active",
      );
      assert.equal(active.length, 3, "không tạo ví mới");
    });

    await t.test("ví của người khác không ảnh hưởng kiểm tra trùng tên",
      async () => {
        // Người dùng thứ hai có ví cùng tên với seed của người đầu.
        const other = await app.inject({
          method: "POST",
          url: "/api/v1/auth/register",
          payload: {
            email: "other-" + Date.now() + "@example.com",
            password: "matkhau123",
            displayName: "Bình",
          },
        });
        assert.equal(other.statusCode, 200, other.body);
        const otherToken = other.json().data.accessToken;
        const res = await app.inject({
          method: "POST",
          url: "/api/v1/wallets",
          headers: {
            authorization: "Bearer " + otherToken,
            "idempotency-key": randomUUID(),
          },
          payload: {
            name: "Ví tiền mặt",
            type: "cash",
            openingBalance: "0",
            openingAt: new Date(Date.now() - 86400000).toISOString(),
          },
        });
        assert.equal(res.statusCode, 200, res.body);
        assert.equal(res.json().data.name, "Ví tiền mặt");
      },
    );

    await t.test("ví seed vẫn còn dùng được giao dịch sau khi thêm kiểm tra",
      async () => {
        await call("POST", "/transactions", {
          type: "expense",
          amount: "10000",
          walletId: CASH,
          categoryId: "00000000000000000000000a",
          occurredAt: new Date().toISOString(),
          note: "Kiểm tra ví sau thay đổi",
        });
        const overview = await call("GET", "/dashboard");
        assert(overview.total !== "0");
        // BANK không bị ảnh hưởng.
        assert(overview.wallets.some((w) => w._id === BANK));
      },
    );
  },
);
