import test from "node:test";
import assert from "node:assert/strict";
import { Long, MongoClient, ObjectId } from "mongodb";
import { MongoMemoryReplSet } from "mongodb-memory-server";
import { initialize } from "../src/migrate.js";
import { buildApp } from "../src/app.js";
import { randomUUID } from "node:crypto";

const CASH = "000000000000000000000002",
  BANK = "000000000000000000000003",
  FOOD = "00000000000000000000000a",
  SALARY = "000000000000000000000010";

/**
 * Ba lớp tiền minh bạch phải lấy trực tiếp từ MongoDB:
 *   Lớp 1 = tổng số dư ví đang hoạt động
 *   Lớp 2 = hóa đơn chưa trả + quỹ bảo vệ
 *   Lớp 3 = Lớp 1 − Lớp 2
 * Mọi thao tác ghi (giao dịch, hóa đơn, quỹ, ví) đều phải phản ánh ngay.
 */
test(
  "3 lớp tiền minh bạch: đồng bộ từ MongoDB, không hardcode, không trùng",
  { timeout: 300000 },
  async (t) => {
    const repl = await MongoMemoryReplSet.create({
      binary: {
        version: process.env.MONGOMS_VERSION || "8.0.13",
        downloadDir:
          process.env.MONGOMS_DOWNLOAD_DIR || "/tmp/vi-an-mongodb-binaries",
      },
      replSet: { count: 1, configSettings: { electionTimeoutMillis: 2500 } },
    });
    const client = new MongoClient(repl.getUri(), { promoteLongs: false });
    await client.connect();
    const db = client.db("vi_an_layers_test");
    let app;
    t.after(async () => {
      await app?.close();
      await client.close();
      await repl.stop();
    });
    await initialize(db, { seed: true });
    app = await buildApp(
      { client, db, transactionCapable: true, backupSecret: "layers-secret" },
      {
        allowDemo: true,
        jwtSecret: "integration-only-secret-at-least-32-characters",
      },
    );
    const login = await app.inject({
      method: "POST",
      url: "/api/v1/auth/demo",
      payload: {},
    });
    assert.equal(login.statusCode, 200, login.body);
    const token = login.json().data.accessToken;
    const owner = new ObjectId(login.json().data.user._id);

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
      if (method === "GET" && url === "/dashboard")
        assert.equal(res.headers["cache-control"], "private, no-store");
      return res.json().data;
    }
    const dash = () => call("GET", "/dashboard");

    /** Tính lại 3 lớp trực tiếp bằng aggregate trên MongoDB. */
    async function expectedLayers() {
      const user = await db.collection("users").findOne({ _id: owner });
      const wallets = await db
        .collection("wallets")
        .find({ userId: owner, status: "active" })
        .toArray();
      const total = wallets.reduce((s, w) => s + BigInt(w.balance.toString()), 0n);
      const goals = await db
        .collection("goals")
        .find({ userId: owner, status: "active", protect: true })
        .project({ _id: 1 })
        .toArray();
      const allocs = await db
        .collection("goal_allocations")
        .find({ userId: owner, goalId: { $in: goals.map((g) => g._id) } })
        .toArray();
      const protectedMoney = allocs.reduce(
        (s, a) => s + BigInt(a.amount.toString()),
        0n,
      );
      const bills = await db
        .collection("bill_occurrences")
        .find({
          userId: owner,
          status: "unpaid",
          dueAt: { $lt: new Date(user.nextPayday) },
        })
        .toArray();
      const unpaidBills = bills.reduce(
        (s, b) => s + BigInt(b.amount.toString()),
        0n,
      );
      return {
        total,
        protectedMoney,
        unpaidBills,
        available: total - protectedMoney - unpaidBills,
        walletCount: wallets.length,
      };
    }

    /** Dashboard phải khớp chính xác số liệu tính trực tiếp từ DB. */
    async function assertMatchesDb(label) {
      const o = await dash();
      const e = await expectedLayers();
      assert.equal(o.total, e.total.toString(), `${label}: Lớp 1 = tổng ví`);
      assert.equal(
        o.protectedMoney,
        e.protectedMoney.toString(),
        `${label}: quỹ bảo vệ`,
      );
      assert.equal(
        o.unpaidBills,
        e.unpaidBills.toString(),
        `${label}: hóa đơn chưa trả`,
      );
      assert.equal(
        o.available,
        e.available.toString(),
        `${label}: Lớp 3 = Lớp 1 − Lớp 2`,
      );
      assert.equal(o.spendableAmount, (e.available > 0n ? e.available : 0n).toString());
      assert.equal(o.shortfallAmount, (e.available < 0n ? -e.available : 0n).toString());
      // Khối `layers` phản chiếu đúng các trường phẳng, không tính khác đi.
      assert.equal(o.layers.total, o.total);
      assert.equal(o.layers.protectedMoney, o.protectedMoney);
      assert.equal(o.layers.unpaidBills, o.unpaidBills);
      assert.equal(o.layers.available, o.available);
      assert.equal(
        o.layers.obligations,
        (BigInt(o.protectedMoney) + BigInt(o.unpaidBills)).toString(),
      );
      assert.equal(o.layers.walletCount, e.walletCount);
      assert.equal(
        BigInt(o.total) - BigInt(o.protectedMoney) - BigInt(o.unpaidBills),
        BigInt(o.available),
        `${label}: công thức Lớp 3`,
      );
      return o;
    }

    await t.test("dữ liệu mẫu: 3 lớp khớp MongoDB, không hardcode",
      async () => {
        const o = await assertMatchesDb("seed");
        assert.equal(o.total, "8000000");
        assert.equal(o.protectedMoney, "2400000");
        assert.equal(o.unpaidBills, "3500000");
        assert.equal(o.available, "2100000");
        assert.equal(o.layers.walletCount, 2);
        assert.equal(o.layers.protectedGoalCount, 1);
      },
    );

    await t.test("thiếu tiền: phần có thể chi bằng 0 và khoản thiếu được trả riêng", async () => {
      const before = await dash();
      const bills = db.collection("bill_occurrences");
      const id = new ObjectId(before.bills[0]._id);
      const original = await bills.findOne({ _id: id });
      const increase = Long.fromString((BigInt(before.available) + 500000n).toString());

      try {
        await bills.updateOne({ _id: id }, { $inc: { amount: increase } });
        const after = await assertMatchesDb("thiếu tiền dành riêng");
        assert.equal(after.available, "-500000");
        assert.equal(after.spendableAmount, "0");
        assert.equal(after.shortfallAmount, "500000");
      } finally {
        await bills.updateOne({ _id: id }, { $set: { amount: original.amount } });
      }
    });

    await t.test("phát sinh giao dịch chi: Lớp 1 và Lớp 3 giảm đúng số tiền",
      async () => {
        const before = await dash();
        await call("POST", "/transactions", {
          type: "expense",
          amount: "200000",
          walletId: CASH,
          categoryId: FOOD,
          occurredAt: new Date().toISOString(),
          note: "ăn trưa layers",
        });
        const after = await assertMatchesDb("sau chi");
        assert.equal(
          BigInt(after.total),
          BigInt(before.total) - 200000n,
          "Lớp 1 giảm",
        );
        assert.equal(
          BigInt(after.available),
          BigInt(before.available) - 200000n,
          "Lớp 3 giảm cùng số tiền",
        );
        assert.equal(after.protectedMoney, before.protectedMoney);
        assert.equal(after.unpaidBills, before.unpaidBills);
      },
    );

    await t.test("thu nhập và chuyển ví không phá công thức 3 lớp",
      async () => {
        const before = await dash();
        await call("POST", "/transactions", {
          type: "income",
          amount: "1000000",
          walletId: BANK,
          categoryId: SALARY,
          occurredAt: new Date().toISOString(),
          note: "thưởng layers",
        });
        const afterIncome = await assertMatchesDb("sau thu nhập");
        assert.equal(
          BigInt(afterIncome.total),
          BigInt(before.total) + 1000000n,
          "Lớp 1 tăng",
        );
        assert.equal(
          BigInt(afterIncome.available),
          BigInt(before.available) + 1000000n,
          "Lớp 3 tăng tương ứng",
        );

        await call("POST", "/transactions", {
          type: "transfer",
          amount: "300000",
          fromWalletId: BANK,
          toWalletId: CASH,
          occurredAt: new Date().toISOString(),
          note: "chuyển nội bộ layers",
        });
        const afterTransfer = await assertMatchesDb("sau chuyển ví");
        assert.equal(
          afterTransfer.total,
          afterIncome.total,
          "chuyển ví không đổi tổng",
        );
        assert.equal(
          afterTransfer.available,
          afterIncome.available,
          "chuyển ví không đổi Lớp 3",
        );
      },
    );

    await t.test("xóa giao dịch: 3 lớp trở về đúng số cũ", async () => {
      const before = await dash();
      const tx = await call("POST", "/transactions", {
        type: "expense",
        amount: "150000",
        walletId: CASH,
        categoryId: FOOD,
        occurredAt: new Date().toISOString(),
        note: "sẽ hủy layers",
      });
      const middle = await dash();
      assert.equal(BigInt(middle.total), BigInt(before.total) - 150000n);

      await call("POST", `/transactions/${tx._id}/void`, {
        expectedVersion: tx.version,
      });
      const after = await assertMatchesDb("sau hủy");
      assert.equal(after.total, before.total, "Lớp 1 hoàn lại");
      assert.equal(after.available, before.available, "Lớp 3 hoàn lại");
    });

    await t.test("quỹ bảo vệ: gán tiền làm Lớp 2 tăng, Lớp 3 giảm, Lớp 1 giữ nguyên",
      async () => {
        const before = await dash();
        const goals = await call("GET", "/goals");
        const goal = goals[0];
        assert(goal, "seed phải có mục tiêu bảo vệ");

        // Gán thêm 300.000đ từ ví ngân hàng vào mục tiêu đang bảo vệ.
        await call("PUT", `/goals/${goal._id}/allocation`, {
          walletId: BANK,
          amount: String(BigInt(goal.allocated) + 300000n),
        });
        const after = await assertMatchesDb("sau tăng quỹ");
        assert.equal(after.total, before.total, "Lớp 1 không đổi");
        assert.equal(
          BigInt(after.protectedMoney),
          BigInt(before.protectedMoney) + 300000n,
          "Lớp 2 tăng đúng phần gán thêm",
        );
        assert.equal(
          BigInt(after.available),
          BigInt(before.available) - 300000n,
          "Lớp 3 giảm tương ứng",
        );

        // Rút toàn bộ phần vừa gán: Lớp 2 và Lớp 3 trở lại.
        await call("PUT", `/goals/${goal._id}/allocation`, {
          walletId: BANK,
          amount: goal.allocated,
        });
        const reverted = await assertMatchesDb("sau rút quỹ");
        assert.equal(reverted.protectedMoney, before.protectedMoney);
        assert.equal(reverted.available, before.available);
      },
    );

    await t.test("thanh toán hóa đơn: hóa đơn giảm, số dư giảm, Lớp 3 không đổi",
      async () => {
        const before = await dash();
        const bills = await call("GET", "/screens/bills");
        const unpaid = bills.bills.find((b) => b.status === "unpaid");
        assert(unpaid, "seed phải còn hóa đơn chưa trả");

        // Trả từ ví có đủ tiền; số chi đúng bằng số hóa đơn nên Lớp 3 giữ nguyên.
        await call("POST", `/bills/${unpaid._id}/pay`, {
          walletId: BANK,
          occurredAt: new Date().toISOString(),
        });
        const after = await assertMatchesDb("sau trả hóa đơn");
        assert.equal(
          BigInt(after.unpaidBills),
          BigInt(before.unpaidBills) - BigInt(unpaid.amount),
          "Lớp 2 giảm đúng số hóa đơn đã trả",
        );
        assert.equal(
          BigInt(after.total),
          BigInt(before.total) - BigInt(unpaid.amount),
          "Lớp 1 giảm đúng số tiền đã trả",
        );
        assert.equal(after.available, before.available, "Lớp 3 giữ nguyên");
      },
    );

    await t.test("số dư ví đổi (đối chiếu): Lớp 1 và Lớp 3 cập nhật",
      async () => {
        const before = await dash();
        const wallets = await call("GET", "/wallets");
        const cash = wallets.find((w) => w._id === CASH);
        await call("POST", `/wallets/${CASH}/reconcile`, {
          actualBalance: String(BigInt(cash.balance) - 50000n),
          expectedVersion: cash.version,
          note: "đối chiếu layers",
        });
        const after = await assertMatchesDb("sau đối chiếu");
        assert.equal(
          BigInt(after.total),
          BigInt(before.total) - 50000n,
          "Lớp 1 theo số dư thật",
        );
        assert.equal(
          BigInt(after.available),
          BigInt(before.available) - 50000n,
          "Lớp 3 theo số dư thật",
        );
      },
    );

    await t.test("đọc lại nhiều lần: số liệu ổn định, không cộng dồn trùng",
      async () => {
        const a = await dash();
        const b = await dash();
        const c = await dash();
        for (const o of [b, c]) {
          assert.equal(o.total, a.total);
          assert.equal(o.protectedMoney, a.protectedMoney);
          assert.equal(o.unpaidBills, a.unpaidBills);
          assert.equal(o.available, a.available);
        }
        await assertMatchesDb("đọc lặp");
      },
    );

    await t.test("không có ngày lương kế tiếp: Lớp 3 = null, không bịa số",
      async () => {
        await db
          .collection("users")
          .updateOne({ _id: owner }, { $unset: { nextPayday: "" } });
        const o = await dash();
        assert.equal(o.available, null, "không bịa Lớp 3 khi thiếu dữ liệu");
        assert.equal(o.layers.available, null);
        assert(o.missingData.includes("nextPayday"));
        // Lớp 1 và Lớp 2 vẫn đúng dù thiếu ngày lương.
        const e = await expectedLayers();
        assert.equal(o.total, e.total.toString());
        assert.equal(o.protectedMoney, e.protectedMoney.toString());
      },
    );
  },
);
