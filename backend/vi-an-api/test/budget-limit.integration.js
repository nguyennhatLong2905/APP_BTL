import test from "node:test";
import assert from "node:assert/strict";
import { MongoClient, ObjectId, Long, Int32 } from "mongodb";
import { MongoMemoryReplSet } from "mongodb-memory-server";
import { initialize } from "../src/migrate.js";
import { buildApp } from "../src/app.js";
import { randomUUID } from "node:crypto";

const FOOD = "00000000000000000000000a",
  TRAVEL = "00000000000000000000000e",
  CASH = "000000000000000000000002",
  BANK = "000000000000000000000003";

test(
  "Ngân sách: hard spending limit theo danh mục, đồng bộ và không phá 3 lớp",
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
    const db = client.db("vi_an_budget_limit_test");
    let app;
    t.after(async () => {
      await app?.close();
      await client.close();
      await repl.stop();
    });
    await initialize(db);
    // Dữ liệu tối thiểu, tự dựng để kiểm soát chính xác từng con số.
    const userId = new ObjectId("000000000000000000000001");
    const now = new Date();
    await db.collection("users").insertOne({
      _id: userId,
      authSubject: "demo:an",
      displayName: "An",
      timezone: "Asia/Ho_Chi_Minh",
      currency: "VND",
      nextPayday: new Date(now.getTime() + 20 * 86400000),
      settings: { hideAmounts: false, reviewDelayDays: 7 },
      tokenversion: new Int32(0),
      createdAt: now,
      updatedAt: now,
    });
    await db.collection("wallets").insertMany([
      {
        _id: new ObjectId(CASH),
        userId,
        name: "Tiền mặt",
        type: "cash",
        currency: "VND",
        openingBalance: Long.fromNumber(20000000),
        openingAt: new Date(now.getTime() - 200 * 86400000),
        balance: Long.fromNumber(20000000),
        status: "active",
        version: new Int32(0),
        createdAt: now,
        updatedAt: now,
      },
      {
        _id: new ObjectId(BANK),
        userId,
        name: "Ngân hàng",
        type: "bank",
        currency: "VND",
        openingBalance: Long.fromNumber(20000000),
        openingAt: new Date(now.getTime() - 200 * 86400000),
        balance: Long.fromNumber(20000000),
        status: "active",
        version: new Int32(0),
        createdAt: now,
        updatedAt: now,
      },
    ]);
    await db.collection("categories").insertMany([
      {
        _id: new ObjectId(FOOD),
        userId,
        name: "Ăn uống",
        kind: "expense",
        status: "active",
        createdAt: now,
        updatedAt: now,
      },
      {
        _id: new ObjectId(TRAVEL),
        userId,
        name: "Đi lại",
        kind: "expense",
        status: "active",
        createdAt: now,
        updatedAt: now,
      },
      {
        _id: new ObjectId("000000000000000000000010"),
        userId,
        name: "Lương",
        kind: "income",
        status: "active",
        createdAt: now,
        updatedAt: now,
      },
    ]);
    app = await buildApp(
      { client, db, transactionCapable: true, backupSecret: "budget-secret" },
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
    // demo token trỏ tới user …0001 nên dùng thẳng tài khoản đó.
    const token = login.json().data.accessToken;

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
    const raw = (method, url, body) =>
      app.inject({
        method,
        url: "/api/v1" + url,
        headers: {
          authorization: "Bearer " + token,
          "idempotency-key": randomUUID(),
        },
        ...(body ? { payload: body } : {}),
      });

    const occurredAt = new Date(now.getTime() - 3600000).toISOString();
    const spend = (amount, categoryId = FOOD, walletId = CASH, at = occurredAt) =>
      call("POST", "/transactions", {
        type: "expense",
        amount: String(amount),
        walletId,
        categoryId,
        occurredAt: at,
        note: "chi " + amount,
      });
    const screen = () => call("GET", "/screens/plans");
    const budgetLine = async (categoryId = FOOD) => {
      const s = await screen();
      const views = s.budgets || s.plans || [];
      const plan = views[0];
      assert(plan, "phải có kỳ ngân sách");
      return plan.limits.find((l) => l.categoryId === categoryId);
    };

    let planId;
    let txn1600;
    let txn400;

    await t.test("1. Tạo ngân sách 2 triệu: đã chi 0, còn 2 triệu", async () => {
      const start = new Date(now.getTime() - 10 * 86400000).toISOString();
      const end = new Date(now.getTime() + 20 * 86400000).toISOString();
      const plan = await call("POST", "/budgets", {
        name: "Kỳ kiểm thử",
        periodType: "month",
        startAt: start,
        endAt: end,
        warningPercent: 80,
        limits: [{ categoryId: FOOD, limit: "2000000" }],
      });
      planId = plan._id;
      const line = plan.limits.find((l) => l.categoryId === FOOD);
      assert.equal(line.limit, "2000000");
      assert.equal(line.spent, "0");
      assert.equal(line.remaining, "2000000");
      assert.equal(line.locked, false);

      // Tạo ngân sách không đụng tới 3 lớp tài chính.
      const s = await screen();
      assert.equal(s.overview.total, "40000000", "tổng ví không đổi");
      assert.equal(s.overview.available, "40000000", "còn để chi không bị trừ");
    });

    await t.test("2. Chi 1,6 triệu: còn 400 nghìn", async () => {
      txn1600 = await spend(1600000);
      const line = await budgetLine();
      assert.equal(line.spent, "1600000");
      assert.equal(line.remaining, "400000");
      assert.equal(line.status, "near");
      assert.equal(line.locked, false);
    });

    await t.test("3. Chi thêm 400 nghìn: hết ngân sách, khóa danh mục",
      async () => {
        txn400 = await spend(400000);
        const line = await budgetLine();
        assert.equal(line.spent, "2000000");
        assert.equal(line.remaining, "0");
        assert.equal(line.locked, true);
        assert.equal(line.status, "exhausted");

        // Danh mục đã khóa: mọi khoản chi mới đều bị từ chối, không tự giảm tiền.
        const res = await raw("POST", "/transactions", {
          type: "expense",
          amount: "10000",
          walletId: CASH,
          categoryId: FOOD,
          occurredAt,
        });
        assert.equal(res.statusCode, 422, res.body);
        assert.equal(res.json().error.code, "BUDGET_LIMIT_EXCEEDED");
        assert.equal(res.json().error.details.remaining, "0");
      },
    );

    await t.test("4. Còn 200 nghìn, nhập 300 nghìn: từ chối và báo vượt 100 nghìn",
      async () => {
        // Hủy khoản 400k để còn lại 200k.
        await call("POST", `/transactions/${txn400._id}/void`, {
          expectedVersion: txn400.version,
        });
        let line = await budgetLine();
        assert.equal(line.remaining, "400000");
        assert.equal(line.locked, false, "hủy giao dịch phải mở khóa");

        // Chi 200k → còn đúng 200k.
        await spend(200000);
        line = await budgetLine();
        assert.equal(line.remaining, "200000");

        const res = await raw("POST", "/transactions", {
          type: "expense",
          amount: "300000",
          walletId: CASH,
          categoryId: FOOD,
          occurredAt,
        });
        assert.equal(res.statusCode, 422, res.body);
        const err = res.json().error;
        assert.equal(err.code, "BUDGET_LIMIT_EXCEEDED");
        assert.equal(err.details.remaining, "200000");
        assert.equal(err.details.requested, "300000");
        assert.equal(err.details.overBy, "100000");
        assert.match(err.message, /vượt/);
        // Không tự giảm số tiền: giao dịch không được ghi.
        assert.equal(
          await db.collection("transactions").countDocuments({ note: "chi 300000" }),
          0,
        );
      },
    );

    await t.test("5. Xóa giao dịch: hoàn lại hạn mức", async () => {
      const line = await budgetLine();
      const target = await db.collection("transactions").findOne({
        userId,
        note: "chi 1600000",
        status: "posted",
      });
      await call("POST", `/transactions/${target._id}/void`, {
        expectedVersion: target.version,
      });
      const after = await budgetLine();
      assert.equal(
        BigInt(after.spent),
        BigInt(line.spent) - 1600000n,
        "số đã chi giảm đúng bằng khoản bị hủy",
      );
      assert.equal(after.locked, false);
      // Bộ đếm nội bộ cũng đã đồng bộ.
      const counter = await db
        .collection("budget_spend")
        .findOne({ userId, categoryId: new ObjectId(FOOD) });
      assert.equal(counter.used.toString(), after.spent);
    });

    await t.test("6. Tăng hạn mức: tự động mở khóa", async () => {
      // Chi cho tới khi hết hạn mức hiện tại.
      const line = await budgetLine();
      if (BigInt(line.remaining) > 0n)
        await spend(line.remaining, FOOD, BANK);
      let locked = await budgetLine();
      assert.equal(locked.locked, true);
      assert.equal(
        (await raw("POST", "/transactions", {
          type: "expense",
          amount: "1000",
          walletId: CASH,
          categoryId: FOOD,
          occurredAt,
        })).statusCode,
        422,
      );

      const plan = await call("GET", `/budgets/${planId}`).catch(() => null);
      const current = plan || (await screen()).budgets[0];
      await call("PUT", `/budgets/${planId}`, {
        name: current.name,
        periodType: current.periodType,
        startAt: current.startAt,
        endAt: current.endAt,
        warningPercent: current.warningPercent,
        limits: [{ categoryId: FOOD, limit: "3000000" }],
      });
      const reopened = await budgetLine();
      assert.equal(reopened.locked, false, "tăng hạn mức phải mở khóa");
      const ok = await spend(1000);
      assert.equal(ok.amount, "1000");
    });

    await t.test("7. Chuyển tiền giữa ví: ngân sách không thay đổi", async () => {
      const before = await budgetLine();
      const overviewBefore = (await screen()).overview;
      await call("POST", "/transactions", {
        type: "transfer",
        amount: "500000",
        fromWalletId: BANK,
        toWalletId: CASH,
        occurredAt,
        note: "chuyển nội bộ",
      });
      const after = await budgetLine();
      assert.equal(after.spent, before.spent, "chuyển ví không vào chi ngân sách");
      const overviewAfter = (await screen()).overview;
      assert.equal(overviewAfter.total, overviewBefore.total);
      assert.equal(overviewAfter.available, overviewBefore.available);
    });

    await t.test("8. Thu nhập không vào ngân sách", async () => {
      const before = await budgetLine();
      await call("POST", "/transactions", {
        type: "income",
        amount: "3000000",
        walletId: BANK,
        categoryId: "000000000000000000000010",
        occurredAt,
        note: "lương",
      });
      const after = await budgetLine();
      assert.equal(after.spent, before.spent);
    });

    await t.test("9. Tải lại: dữ liệu và trạng thái khóa vẫn chính xác", async () => {
      // Mô phỏng mở lại app: đọc lại từ API, không dùng cache.
      const s = await screen();
      const plan = s.budgets[0];
      const line = plan.limits.find((l) => l.categoryId === FOOD);
      const dbSpent = await db
        .collection("transactions")
        .aggregate([
          {
            $match: {
              userId,
              status: "posted",
              type: "expense",
              categoryId: new ObjectId(FOOD),
              occurredAt: { $gte: new Date(plan.startAt), $lt: new Date(plan.endAt) },
            },
          },
          { $group: { _id: null, total: { $sum: "$amount" } } },
        ])
        .toArray();
      const expected = (dbSpent[0]?.total ?? 0).toString();
      assert.equal(line.spent, expected, "số đã chi khớp giao dịch thật");
      assert.equal(line.remaining, (3000000n - BigInt(expected)).toString());
      assert.equal(line.locked, BigInt(expected) >= 3000000n);

      // Danh mục chưa thiết lập ngân sách vẫn chi bình thường.
      const travel = await spend(150000, TRAVEL);
      assert.equal(travel.amount, "150000");
    });

    await t.test("đồng thời: nhiều khoản chi song song không thể cùng vượt hạn mức",
      async () => {
        const s = await screen();
        const plan = s.budgets[0];
        await call("PUT", `/budgets/${plan._id}`, {
          name: plan.name,
          periodType: plan.periodType,
          startAt: plan.startAt,
          endAt: plan.endAt,
          warningPercent: plan.warningPercent,
          limits: [
            { categoryId: FOOD, limit: "3000000" },
            { categoryId: TRAVEL, limit: "500000" },
          ],
        });
        // Đi lại đang có 150k → còn 350k: chỉ 1 trong 3 khoản 200k được qua.
        const results = await Promise.all(
          [1, 2, 3].map((n) =>
            app.inject({
              method: "POST",
              url: "/api/v1/transactions",
              headers: {
                authorization: "Bearer " + token,
                "idempotency-key": "parallel-budget-" + n,
              },
              payload: {
                type: "expense",
                amount: "200000",
                walletId: CASH,
                categoryId: TRAVEL,
                occurredAt: new Date().toISOString(),
                note: "song song " + n,
              },
            }),
          ),
        );
        const okCount = results.filter((r) => r.statusCode === 200).length;
        assert.equal(okCount, 1, JSON.stringify(results.map((r) => r.statusCode)));
        const line = await budgetLine(TRAVEL);
        assert(
          BigInt(line.spent) <= 500000n,
          "tổng chi không vượt hạn mức: " + line.spent,
        );
      },
    );
    await t.test("ngưỡng cảnh báo tùy chọn được lưu và dùng để bật cảnh báo",
      async () => {
        const s = await screen();
        const plan = s.budgets[0];
        await call("PUT", `/budgets/${plan._id}`, {
          name: plan.name,
          periodType: plan.periodType,
          startAt: plan.startAt,
          endAt: plan.endAt,
          warningPercent: 50,
          limits: plan.limits.map((l) => ({
            categoryId: l.categoryId,
            limit: l.limit,
          })),
        });
        const after = (await screen()).budgets[0];
        assert.equal(after.warningPercent, 50, "ngưỡng được lưu");
        for (const line of after.limits) {
          const pct = Number(line.percent ?? 0);
          assert.equal(
            line.warning,
            pct >= 50,
            "cảnh báo bật đúng theo ngưỡng người dùng chọn",
          );
        }
      },
    );

    await t.test("xóa ngân sách chỉ xóa kế hoạch, không đụng ví/giao dịch",
      async () => {
        const beforeOverview = (await screen()).overview;
        const beforeTxns = await db
          .collection("transactions")
          .countDocuments({ userId, status: "posted" });
        const plan = (await screen()).budgets[0];
        await call("DELETE", `/budgets/${plan._id}`);
        const after = await screen();
        assert.equal(after.budgets.length, 0, "kỳ ngân sách đã xóa");
        assert.equal(
          await db.collection("budget_spend").countDocuments({ userId }),
          0,
          "bộ đếm của kỳ cũng bị xóa",
        );
        assert.equal(
          after.overview.total,
          beforeOverview.total,
          "tổng tiền ví không đổi",
        );
        assert.equal(
          after.overview.available,
          beforeOverview.available,
          "còn để chi không đổi",
        );
        assert.equal(
          await db
            .collection("transactions")
            .countDocuments({ userId, status: "posted" }),
          beforeTxns,
          "giao dịch không bị xóa",
        );
        // Không còn ngân sách: mọi khoản chi đều được phép.
        const free = await spend(999999, FOOD);
        assert.equal(free.amount, "999999");
      },
    );

  },
);
