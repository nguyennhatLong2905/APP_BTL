import test from "node:test";
import assert from "node:assert/strict";
import { MongoClient, ObjectId } from "mongodb";
import { MongoMemoryReplSet } from "mongodb-memory-server";
import { initialize } from "../src/migrate.js";
import { buildApp } from "../src/app.js";
import { randomUUID } from "node:crypto";

const DEMO = "000000000000000000000001",
  CASH = "000000000000000000000002",
  BANK = "000000000000000000000003",
  FOOD = "00000000000000000000000a",
  BILLS_CAT = "00000000000000000000000e";

// Kỳ lương gốc của dữ liệu mẫu (16/10/2026) — cố định để ví dụ 8.000.000đ
// luôn có đúng 3.500.000đ hóa đơn chưa trả trong kỳ.
const CYCLE_PAYDAY = "2026-10-16T00:00:00+07:00";
const daysFromNow = (n) =>
  new Date(Date.now() + n * 86400000).toISOString();

test(
  "Hóa đơn định kỳ: trạng thái, 3 lớp tiền, chống trùng, lịch lặp",
  { timeout: 240000 },
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
    const db = client.db("vi_an_bills_test");
    let app;
    t.after(async () => {
      await app?.close();
      await client.close();
      await repl.stop();
    });
    await initialize(db, { seed: true });
    app = await buildApp(
      {
        client,
        db,
        transactionCapable: true,
        backupSecret: "integration-only-secret",
      },
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

    async function call(
      method,
      url,
      body,
      key = randomUUID(),
      tok = token,
      expected = 200,
    ) {
      const response = await app.inject({
        method,
        url: "/api/v1" + url,
        headers: { authorization: "Bearer " + tok, "idempotency-key": key },
        ...(body ? { payload: body } : {}),
      });
      assert.equal(response.statusCode, expected, response.body);
      return response.json().data;
    }
    const dash = async (tok = token) => call("GET", "/dashboard", undefined, undefined, tok);
    const billsScreen = async (tok = token) =>
      call("GET", "/screens/bills", undefined, undefined, tok);

    // Cố định kỳ lương để kịch bản 3 lớp có số liệu xác định.
    await call("PATCH", "/me", { nextPayday: CYCLE_PAYDAY });

    await t.test("ví dụ 8.000.000đ: trả 3.000.000 giữ nguyên Còn để chi",
      async () => {
        const before = await dash();
        assert.equal(before.total, "8000000");
        assert.equal(before.unpaidBills, "3500000");
        assert.equal(before.protectedMoney, "2400000");
        assert.equal(before.available, "2100000");

        const screen = await billsScreen();
        const rent = screen.bills.find(
          (b) => b.name === "Tiền nhà" && b.status === "unpaid",
        );
        assert.equal(rent.amount, "3000000");
        assert.equal(rent.frequency, "monthly");

        const preview = await call("POST", `/bills/${rent._id}/pay-preview`, {});
        assert.equal(preview.releasedReservation, "3000000");
        assert.equal(preview.excessOverReserved, "0");
        assert.equal(preview.after.total, "5000000");
        assert.equal(preview.after.unpaidBills, "500000");
        assert.equal(preview.after.protectedMoney, "2400000");
        assert.equal(preview.after.available, "2100000");
        assert.equal(preview.requiresConfirmation, false);

        const settled = await call("POST", `/bills/${rent._id}/settle`, {
          walletId: BANK,
          occurredAt: new Date().toISOString(),
        });
        assert.equal(settled.transaction.amount, "3000000");
        assert.equal(settled.transaction.type, "expense");
        assert.equal(settled.bill.status, "paid");
        assert.equal(settled.bill.paidAmount, "3000000");
        assert.equal(settled.bill.paymentMethod, "new_transaction");
        // Giao dịch chi phải gắn với đúng kỳ hóa đơn.
        assert.equal(settled.transaction.billOccurrenceId, rent._id);

        const after = await dash();
        assert.equal(after.total, "5000000");
        assert.equal(after.unpaidBills, "500000");
        assert.equal(after.protectedMoney, "2400000", "Quỹ bảo vệ không đổi");
        assert.equal(after.available, "2100000", "Còn để chi không đổi");
      },
    );

    await t.test("trả thực tế thấp hơn dự kiến giải phóng phần chênh lệch",
      async () => {
        const screen = await billsScreen();
        const power = screen.bills.find(
          (b) => b.name === "Điện nước sinh hoạt" && b.status === "unpaid",
        );
        assert.equal(power.amount, "500000");

        const preview = await call(
          "POST",
          `/bills/${power._id}/pay-preview`,
          { amount: "400000" },
        );
        assert.equal(preview.releasedReservation, "500000");
        assert.equal(preview.after.available, "2200000");

        const settled = await call("POST", `/bills/${power._id}/settle`, {
          walletId: BANK,
          occurredAt: new Date().toISOString(),
          amount: "400000",
        });
        assert.equal(settled.transaction.amount, "400000");

        const after = await dash();
        assert.equal(after.total, "4600000");
        assert.equal(after.unpaidBills, "0");
        assert.equal(after.protectedMoney, "2400000");
        assert.equal(after.available, "2200000", "tăng đúng 100.000đ");
      },
    );

    await t.test("nhấn thanh toán nhiều lần không tạo giao dịch trùng",
      async () => {
        const screen = await billsScreen();
        const paidRent = screen.bills.find(
          (b) => b.name === "Tiền nhà" && b.status === "paid",
        );
        assert(paidRent);
        const expenseCountBefore = await db
          .collection("transactions")
          .countDocuments({
            userId: new ObjectId(DEMO),
            billOccurrenceId: new ObjectId(paidRent._id),
          });
        assert.equal(expenseCountBefore, 1);

        // Key mới nhưng hóa đơn đã trả → phải bị từ chối.
        await call(
          "POST",
          `/bills/${paidRent._id}/settle`,
          { walletId: BANK, occurredAt: new Date().toISOString() },
          undefined,
          token,
          409,
        );
        // Cùng key cũ → vẫn từ chối vì trạng thái đã đổi.
        await call(
          "POST",
          `/bills/${paidRent._id}/settle`,
          { walletId: BANK, occurredAt: new Date().toISOString() },
          "retry-same-key",
          token,
          409,
        );
        assert.equal(
          await db
            .collection("transactions")
            .countDocuments({
              userId: new ObjectId(DEMO),
              billOccurrenceId: new ObjectId(paidRent._id),
            }),
          1,
        );
        assert.equal(
          await db
            .collection("bill_occurrences")
            .countDocuments({ _id: new ObjectId(paidRent._id), status: "paid" }),
          1,
        );
      },
    );

    await t.test("thanh toán vượt dự kiến trừ phần vượt vào Còn để chi",
      async () => {
        // Kỳ trong chu kỳ lương → được giữ riêng ở Lớp 2.
        const created = await call("POST", "/bill-templates", {
          name: "Internet",
          estimatedAmount: "1000000",
          categoryId: BILLS_CAT,
          frequency: "once",
          startAt: "2026-10-01T00:00:00+07:00",
        });
        const screen = await billsScreen();
        const occ = screen.bills.find(
          (b) => b.templateId === created._id && b.status === "unpaid",
        );
        assert(occ, "kỳ hóa đơn phải được sinh");

        const before = await dash();
        assert.equal(before.unpaidBills, "1000000");

        const preview = await call(
          "POST",
          `/bills/${occ._id}/pay-preview`,
          { amount: "1100000" },
        );
        assert.equal(preview.excessOverReserved, "100000");
        assert.equal(
          BigInt(preview.after.available),
          BigInt(before.available) - 100000n,
        );

        const settled = await call("POST", `/bills/${occ._id}/settle`, {
          walletId: BANK,
          occurredAt: new Date().toISOString(),
          amount: "1100000",
        });
        assert.equal(settled.transaction.amount, "1100000");
        const after = await dash();
        assert.equal(BigInt(after.total), BigInt(before.total) - 1100000n);
        assert.equal(
          BigInt(after.available),
          BigInt(before.available) - 100000n,
          "chỉ phần vượt 100.000đ trừ vào Còn để chi",
        );
        assert.equal(after.protectedMoney, "2400000");
      },
    );

    await t.test("liên kết giao dịch có sẵn không trừ ví lần nữa",
      async () => {
        const created = await call("POST", "/bill-templates", {
          name: "Học phí",
          estimatedAmount: "300000",
          categoryId: FOOD,
          frequency: "once",
          startAt: "2026-10-02T00:00:00+07:00",
        });
        const screen = await billsScreen();
        const occ = screen.bills.find(
          (b) => b.templateId === created._id && b.status === "unpaid",
        );
        assert(occ);

        const txn = await call("POST", "/transactions", {
          type: "expense",
          amount: "300000",
          walletId: CASH,
          categoryId: FOOD,
          occurredAt: new Date().toISOString(),
          note: "Học phí đã trả",
        });
        const totalBefore = (await dash()).total;

        const candidates = await call(
          "GET",
          `/bills/${occ._id}/candidate-transactions`,
        );
        assert(candidates.some((c) => c._id === txn._id));

        const linked = await call("POST", `/bills/${occ._id}/link`, {
          transactionId: txn._id,
          expectedVersion: txn.version,
        });
        assert.equal(linked.status, "paid");
        assert.equal(linked.transactionId, txn._id);
        assert.equal(linked.paymentMethod, "linked_transaction");

        assert.equal((await dash()).total, totalBefore, "không trừ ví lần nữa");
        assert.equal(
          await db.collection("transactions").countDocuments({
            userId: new ObjectId(DEMO),
            note: "Học phí đã trả",
          }),
          1,
        );

        // Liên kết lại phải bị chặn.
        await call(
          "POST",
          `/bills/${occ._id}/link`,
          { transactionId: txn._id, expectedVersion: txn.version + 1 },
          undefined,
          token,
          409,
        );
      },
    );

    await t.test("trạng thái suy ra đúng theo ngày hiện tại", async () => {
      const mk = async (name, startAt) => {
        const b = await call("POST", "/bill-templates", {
          name,
          estimatedAmount: "10000",
          categoryId: BILLS_CAT,
          frequency: "once",
          startAt,
        });
        return b._id;
      };
      const dueId = await mk("Due today", daysFromNow(0));
      const overdueId = await mk("Overdue", daysFromNow(-3));
      const upcomingId = await mk("Upcoming", daysFromNow(5));

      const screen = await billsScreen();
      const byTemplate = (id) =>
        screen.bills.find((b) => b.templateId === id && b.status === "unpaid");
      assert.equal(byTemplate(dueId).derivedStatus, "due");
      assert.equal(byTemplate(overdueId).derivedStatus, "overdue");
      assert.equal(byTemplate(upcomingId).derivedStatus, "upcoming");
      assert.equal(byTemplate(overdueId).daysUntilDue, -3);
      assert(screen.summary.overdueCount >= 1);
      assert(screen.summary.dueCount >= 1);
      assert(screen.summary.upcomingCount >= 1);
      assert.equal(
        BigInt(screen.summary.unpaidTotal),
        screen.bills
          .filter((b) => b.status === "unpaid")
          .reduce((s, b) => s + BigInt(b.amount), 0n),
      );
    });

    await t.test("lịch lặp weekly/quarterly sinh kỳ đúng và tôn trọng endAt",
      async () => {
        const weekly = await call("POST", "/bill-templates", {
          name: "Weekly",
          estimatedAmount: "1000",
          categoryId: BILLS_CAT,
          frequency: "weekly",
          startAt: daysFromNow(-7),
        });
        let rows = await db
          .collection("bill_occurrences")
          .find({ templateId: new ObjectId(weekly._id) })
          .sort({ dueAt: 1 })
          .toArray();
        assert(rows.length >= 3);
        for (let i = 1; i < Math.min(rows.length, 5); i++)
          assert.equal(
            Math.round((rows[i].dueAt - rows[i - 1].dueAt) / 86400000),
            7,
          );

        const quarterly = await call("POST", "/bill-templates", {
          name: "Quarterly",
          estimatedAmount: "2000",
          categoryId: BILLS_CAT,
          frequency: "quarterly",
          startAt: daysFromNow(0),
          endAt: daysFromNow(200),
        });
        rows = await db
          .collection("bill_occurrences")
          .find({ templateId: new ObjectId(quarterly._id) })
          .sort({ dueAt: 1 })
          .toArray();
        assert.equal(rows.length, 3);
        assert(rows[2].dueAt <= new Date(daysFromNow(200)));

        const count = rows.length;
        await call("POST", "/jobs/run", {});
        assert.equal(
          await db
            .collection("bill_occurrences")
            .countDocuments({ templateId: new ObjectId(quarterly._id) }),
          count,
          "job chạy lại không sinh trùng",
        );
      },
    );

    await t.test("kỳ tiếp theo được tạo sau khi trả kỳ hiện tại", async () => {
      const b = await call("POST", "/bill-templates", {
        name: "Recurring rent",
        estimatedAmount: "100000",
        categoryId: BILLS_CAT,
        frequency: "monthly",
        startAt: "2026-09-20T00:00:00+07:00",
      });
      const before = await db
        .collection("bill_occurrences")
        .find({ templateId: new ObjectId(b._id) })
        .sort({ dueAt: 1 })
        .toArray();
      assert(before.length >= 2);
      const first = before[0];
      await call("POST", `/bills/${first._id}/settle`, {
        walletId: CASH,
        occurredAt: new Date().toISOString(),
      });
      const after = await db
        .collection("bill_occurrences")
        .find({ templateId: new ObjectId(b._id) })
        .sort({ dueAt: 1 })
        .toArray();
      assert(
        after.find(
          (x) => x._id.toString() === first._id.toString(),
        ).status === "paid",
      );
      const nextUnpaid = after.find(
        (x) =>
          x.status === "unpaid" && x._id.toString() !== first._id.toString(),
      );
      assert(nextUnpaid, "phải có kỳ kế tiếp chưa trả");
      const gapDays = Math.round((nextUnpaid.dueAt - first.dueAt) / 86400000);
      assert(gapDays >= 28 && gapDays <= 31, `gap=${gapDays}`);
      // Không có hai kỳ trùng ngày.
      const keys = after.map((x) => x.dueAt.toISOString());
      assert.equal(new Set(keys).size, keys.length);
    });

    await t.test("xóa kỳ chưa trả và ngừng định kỳ", async () => {
      const b = await call("POST", "/bill-templates", {
        name: "To delete",
        estimatedAmount: "10000",
        categoryId: BILLS_CAT,
        frequency: "monthly",
        startAt: daysFromNow(3),
      });
      const screen = await billsScreen();
      const occ = screen.bills.find(
        (x) => x.templateId === b._id && x.status === "unpaid",
      );
      assert(occ);
      await call("DELETE", `/bills/${occ._id}`);
      assert.equal(
        await db
          .collection("bill_occurrences")
          .countDocuments({ _id: new ObjectId(occ._id) }),
        0,
      );

      const c = await call("POST", "/bill-templates", {
        name: "To stop",
        estimatedAmount: "10000",
        categoryId: BILLS_CAT,
        frequency: "monthly",
        startAt: daysFromNow(5),
      });
      await call("POST", `/bill-templates/${c._id}/stop`, {
        cancelFutureUnpaid: true,
      });
      assert.equal(
        await db.collection("bill_occurrences").countDocuments({
          templateId: new ObjectId(c._id),
          status: "unpaid",
        }),
        0,
      );
      assert.equal(
        (
          await db
            .collection("bill_templates")
            .findOne({ _id: new ObjectId(c._id) })
        ).active,
        false,
      );
    });

    await t.test("sửa hóa đơn cập nhật kỳ tương lai và không nhân bản",
      async () => {
        const b = await call("POST", "/bill-templates", {
          name: "Editable",
          estimatedAmount: "20000",
          categoryId: BILLS_CAT,
          frequency: "monthly",
          startAt: daysFromNow(6),
        });
        await call("PUT", `/bill-templates/${b._id}`, {
          name: "Editable renamed",
          estimatedAmount: "25000",
        });
        const rows = await db
          .collection("bill_occurrences")
          .find({ templateId: new ObjectId(b._id), status: "unpaid" })
          .toArray();
        assert(rows.length >= 1);
        for (const r of rows) {
          assert.equal(r.name, "Editable renamed");
          assert.equal(r.amount.toString(), "25000");
        }
        const refreshed = await billsScreen();
        const match = refreshed.bills.filter((x) => x.templateId === b._id);
        const dueKeys = match.map((x) => new Date(x.dueAt).toISOString());
        assert.equal(new Set(dueKeys).size, dueKeys.length);
      },
    );

    await t.test("không cho thanh toán làm Còn để chi âm nếu chưa xác nhận",
      async () => {
        const other = await call("POST", "/auth/register", {
          email: "bills-negative@example.test",
          password: "a-very-long-password",
          displayName: "Negative",
        });
        const tok = other.accessToken;
        await call(
          "POST",
          "/wallets",
          {
            name: "Small",
            type: "cash",
            openingBalance: "100000",
            openingAt: new Date().toISOString(),
          },
          undefined,
          tok,
        );
        await call(
          "PATCH",
          "/me",
          { nextPayday: daysFromNow(10) },
          undefined,
          tok,
        );
        const cats = await call("GET", "/categories", undefined, undefined, tok);
        const expenseCat = cats.find((c) => c.kind === "expense");
        const tmpl = await call(
          "POST",
          "/bill-templates",
          {
            name: "Big bill",
            estimatedAmount: "200000",
            categoryId: expenseCat._id,
            frequency: "once",
            startAt: daysFromNow(2),
          },
          undefined,
          tok,
        );
        const bills = await billsScreen(tok);
        const occ = bills.bills.find(
          (x) => x.templateId === tmpl._id && x.status === "unpaid",
        );
        assert(occ);
        const preview = await call(
          "POST",
          `/bills/${occ._id}/pay-preview`,
          {},
          undefined,
          tok,
        );
        assert.equal(preview.requiresConfirmation, true);
        assert(BigInt(preview.after.available) < 0n);

        const wallets = await call("GET", "/wallets", undefined, undefined, tok);
        await call(
          "POST",
          `/bills/${occ._id}/settle`,
          {
            walletId: wallets[0]._id,
            occurredAt: new Date().toISOString(),
          },
          undefined,
          tok,
          409,
        );

        // Xác nhận rõ ràng thì được phép, nhưng ví vẫn không được âm.
        const confirmed = await app.inject({
          method: "POST",
          url: `/api/v1/bills/${occ._id}/settle`,
          headers: {
            authorization: "Bearer " + tok,
            "idempotency-key": randomUUID(),
          },
          payload: {
            walletId: wallets[0]._id,
            occurredAt: new Date().toISOString(),
            allowNegativeAvailable: true,
          },
        });
        assert.equal(confirmed.statusCode, 409, confirmed.body);
        assert.equal(confirmed.json().error.code, "INSUFFICIENT_BALANCE");
      },
    );

    await t.test("dữ liệu vẫn nhất quán sau khi đọc lại", async () => {
      const a = await dash();
      const b = await dash();
      assert.equal(a.total, b.total);
      assert.equal(a.unpaidBills, b.unpaidBills);
      assert.equal(a.available, b.available);
      const screen = await billsScreen();
      // unpaidBills trong overview = tổng hóa đơn chưa trả đến hạn trong kỳ.
      const inCycle = screen.bills
        .filter(
          (x) =>
            x.status === "unpaid" && new Date(x.dueAt) < new Date(CYCLE_PAYDAY),
        )
        .reduce((s, x) => s + BigInt(x.amount), 0n);
      assert.equal(BigInt(screen.overview.unpaidBills), inCycle);

      // Mỗi hóa đơn đã trả có đúng 1 giao dịch thanh toán.
      for (const bill of screen.bills.filter((x) => x.status === "paid")) {
        assert.equal(
          await db
            .collection("transactions")
            .countDocuments({
              userId: new ObjectId(DEMO),
              billOccurrenceId: new ObjectId(bill._id),
              status: "posted",
            }),
          1,
        );
      }
    });
  },
);
