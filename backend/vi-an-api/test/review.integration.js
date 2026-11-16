import test from "node:test";
import assert from "node:assert/strict";
import { MongoClient, ObjectId } from "mongodb";
import { MongoMemoryReplSet } from "mongodb-memory-server";
import { initialize } from "../src/migrate.js";
import { buildApp } from "../src/app.js";
import { randomUUID } from "node:crypto";
import { weekBounds } from "../src/review.js";

const FOOD = "00000000000000000000000a",
  LEARNING = "00000000000000000000000f",
  SHOPPING = "00000000000000000000000c",
  BANK = "000000000000000000000003",
  CASH = "000000000000000000000002",
  INCOME_CAT = "000000000000000000000010";

const iso = (d) => new Date(d).toISOString();
const daysAgo = (n) => new Date(Date.now() - n * 86400000).toISOString();

test(
  "Nhật ký Đáng tiền: tự động ghi nhận, nhắc sau 7 ngày, đồng bộ khi sửa/xóa",
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
    const db = client.db("vi_an_review_test");
    let app;
    t.after(async () => {
      await app?.close();
      await client.close();
      await repl.stop();
    });
    await initialize(db, { seed: true });
    app = await buildApp(
      { client, db, transactionCapable: true, backupSecret: "review-secret" },
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

    const expense = (amount, categoryId, occurredAt, note, walletId = BANK) =>
      call("POST", "/transactions", {
        type: "expense",
        amount: String(amount),
        walletId,
        categoryId,
        occurredAt,
        note,
      });
    const journalOf = async () => call("GET", "/reflections?status=all");

    const week = weekBounds(new Date(), "Asia/Ho_Chi_Minh");
    const inWeek = new Date(week.start.getTime() + 86400000).toISOString();
    const lastWeek = new Date(week.start.getTime() - 3 * 86400000).toISOString();

    await t.test("seed: mọi khoản chi cũ đã có nhật ký, không trùng", async () => {
      const items = await journalOf();
      // Seed có 5 giao dịch chi (100,101,102,105,106) → đúng 5 mục nhật ký.
      assert.equal(items.length, 5, "mỗi giao dịch chi đúng một bản ghi");
      const ids = items.map((x) => x.transactionId);
      assert.equal(new Set(ids).size, ids.length, "không có transactionId trùng");

      const counts = await db
        .collection("reflections")
        .aggregate([
          { $group: { _id: "$transactionId", n: { $sum: 1 } } },
          { $match: { n: { $gt: 1 } } },
        ])
        .toArray();
      assert.equal(counts.length, 0, "database không có bản ghi nhật ký trùng");
    });

    await t.test("thu nhập, chuyển ví và điều chỉnh không vào nhật ký", async () => {
      const before = (await journalOf()).length;
      await call("POST", "/transactions", {
        type: "income",
        amount: "500000",
        walletId: BANK,
        categoryId: INCOME_CAT,
        occurredAt: daysAgo(1),
        note: "Lương tháng",
      });
      await call("POST", "/transactions", {
        type: "transfer",
        amount: "200000",
        fromWalletId: BANK,
        toWalletId: CASH,
        occurredAt: daysAgo(1),
        note: "Rút tiền mặt",
      });
      const wallet = await call("GET", "/wallets");
      const cash = wallet.find((w) => w._id === CASH);
      const reconciled = await call(
        "POST",
        `/wallets/${CASH}/reconcile`,
        {
          actualBalance: String(BigInt(cash.balance) + 5000n),
          expectedVersion: cash.version,
          note: "Đối chiếu",
        },
        200,
      );
      assert.equal(reconciled.type, "adjustment");
      const after = await journalOf();
      assert.equal(after.length, before, "chỉ khoản chi mới vào nhật ký");
      assert(
        !after.some((x) => x.transaction.type !== "expense"),
        "nhật ký chỉ chứa giao dịch chi",
      );
      assert(!after.some((x) => (x.transaction.note || "") === "Lương tháng"));
      assert(!after.some((x) => (x.transaction.note || "") === "Rút tiền mặt"));
    });

    const created = {};
    await t.test("giao dịch chi mới tự động vào nhật ký (chưa đủ 7 ngày)",
      async () => {
        const t0 = await expense(120000, LEARNING, daysAgo(1), "Sách kỹ năng");
        created.learning = t0;
        const items = await journalOf();
        const entry = items.find((x) => x.transactionId === t0._id);
        assert(entry, "phải xuất hiện ngay sau khi tạo, không cần thao tác");
        assert.equal(entry.state, "tracking");
        assert.equal(entry.isDue, false);
        assert.equal(entry.rating, null);
        assert.equal(entry.daysRemaining, 6, "còn 6 ngày là đủ 7 ngày");
        assert.equal(entry.transaction.amount, "120000");
        assert.equal(entry.transaction.note, "Sách kỹ năng");
        assert.equal(entry.categoryName, "Học tập");
        assert.equal(
          new Date(entry.dueAt).getTime(),
          new Date(t0.occurredAt).getTime() + 7 * 86400000,
          "hạn đánh giá = ngày chi + 7 ngày",
        );

        // Giao dịch chi khác không sinh trùng bản ghi của giao dịch này.
        created.coffee = await expense(30000, FOOD, daysAgo(1), "Cà phê");
        const entries = (await journalOf()).filter(
          (x) => x.transactionId === t0._id,
        );
        assert.equal(entries.length, 1, "không nhân bản bản ghi nhật ký");
      },
    );

    await t.test("đủ 7 ngày thì chuyển sang chờ đánh giá", async () => {
      created.old = await expense(90000, SHOPPING, daysAgo(8), "Áo cũ 8 ngày");
      const items = await journalOf();
      const entry = items.find((x) => x.transactionId === created.old._id);
      assert(entry);
      assert.equal(entry.state, "awaiting_review", "đã đủ 7 ngày");
      assert.equal(entry.isDue, true);
      assert.equal(entry.daysRemaining, 0);

      const summary = (await call("GET", "/screens/review")).journalSummary;
      assert(summary.awaitingReview >= 1);
      // Chưa đánh giá thì không được coi là đã xử lý hết nhật ký.
      assert(summary.tracking + summary.awaitingReview > 0);
    });

    await t.test("đánh giá được ngay cả trước hạn, chỉ một bản ghi", async () => {
      const target = created.learning;
      const entry = (await journalOf()).find(
        (x) => x.transactionId === target._id,
      );
      const rated = await call("PUT", `/reflections/${entry._id}`, {
        status: "rated",
        rating: "worth_it",
        note: "Rất đáng tiền",
      });
      assert.equal(rated.status, "rated");
      assert.equal(rated.rating, "worth_it");

      const after = await journalOf();
      const same = after.filter((x) => x.transactionId === target._id);
      assert.equal(same.length, 1);
      assert.equal(same[0].state, "rated");

      const history = await call("GET", "/reflections/history?status=rated");
      assert.equal(history.length, 1);
      assert.equal(history[0].transaction.note, "Sách kỹ năng");
      assert.equal(history[0].categoryName, "Học tập");
    });

    await t.test("sửa giao dịch: nhật ký đồng bộ, giữ đánh giá, không trùng",
      async () => {
        const target = created.learning;
        const edited = await call("PUT", `/transactions/${target._id}`, {
          type: "expense",
          amount: "150000",
          walletId: BANK,
          categoryId: FOOD,
          occurredAt: daysAgo(2),
          note: "Sách kỹ năng (đã sửa)",
          expectedVersion: target.version,
        });
        assert.equal(edited.amount, "150000");

        const items = await journalOf();
        const entries = items.filter((x) => x.transactionId === target._id);
        assert.equal(entries.length, 1, "không tạo bản ghi thứ hai");
        const entry = entries[0];
        assert.equal(entry.transaction.amount, "150000", "số tiền đồng bộ");
        assert.equal(entry.categoryName, "Ăn uống", "danh mục đồng bộ");
        assert.equal(entry.transaction.note, "Sách kỹ năng (đã sửa)");
        assert.equal(entry.state, "rated", "giữ nguyên đánh giá của người dùng");
        assert.equal(entry.rating, "worth_it");
        assert.equal(
          new Date(entry.dueAt).getTime(),
          new Date(edited.occurredAt).getTime() + 7 * 86400000,
          "hạn đánh giá tính lại theo ngày chi mới",
        );
      },
    );

    await t.test("xóa giao dịch: gỡ khỏi nhật ký và lời nhắc", async () => {
      const target = created.coffee; // đang tracking
      const entry = (await journalOf()).find(
        (x) => x.transactionId === target._id,
      );
      assert(entry);
      const pendingBefore = await db
        .collection("notifications")
        .countDocuments({ entityId: new ObjectId(entry._id), type: "review_due" });
      assert.equal(pendingBefore, 1);

      await call("POST", `/transactions/${target._id}/void`, {
        expectedVersion: target.version,
      });
      const after = await journalOf();
      assert(
        !after.some((x) => x.transactionId === target._id),
        "giao dịch đã hủy không còn trong nhật ký",
      );
      const pendingAfter = await db
        .collection("notifications")
        .countDocuments({ entityId: new ObjectId(entry._id), type: "review_due" });
      assert.equal(pendingAfter, 0, "không còn lời nhắc mồ côi");
    });

    await t.test("khôi phục giao dịch: nhật ký trở lại, không trùng", async () => {
      const target = created.coffee;
      const voided = await call("GET", "/transactions/" + target._id);
      await call("POST", `/transactions/${target._id}/restore`, {
        expectedVersion: voided.version,
      });
      const entries = (await journalOf()).filter(
        (x) => x.transactionId === target._id,
      );
      assert.equal(entries.length, 1);
      assert.equal(entries[0].state, "tracking", "mới 1 ngày nên vẫn theo dõi");
    });

    await t.test("bỏ qua không tạo đánh giá thay người dùng", async () => {
      const items = await journalOf();
      const pending = items.find((x) => x.state === "tracking");
      assert(pending, "cần một mục đang theo dõi");
      const skipped = await call("PUT", `/reflections/${pending._id}`, {
        status: "skipped",
      });
      assert.equal(skipped.status, "skipped");
      assert.equal(skipped.rating, undefined);

      const after = (await journalOf()).find(
        (x) => x.transactionId === pending.transactionId,
      );
      assert.equal(after.state, "skipped");
      assert.equal(after.rating, null);
    });

    await t.test("tổng hợp tuần vẫn đúng và không tự sinh đánh giá", async () => {
      // Bảo đảm có ít nhất một khoản chi trong tuần hiện tại, nếu không test sẽ
      // hỏng mỗi khi sang tuần mới (dữ liệu mẫu đều nằm ở tuần trước).
      // `inWeek` chỉ dùng khi đã ở trong tuần; nếu tuần vừa bắt đầu thì lấy mốc
      // an toàn giữa tuần start và hiện tại để không tạo ngày trong tương lai.
      const inWeekSafe = new Date(
        Math.min(
          week.start.getTime() + 86400000,
          Math.max(week.start.getTime() + 60000, Date.now() - 3600000),
        ),
      ).toISOString();
      await expense(45000, FOOD, inWeekSafe, "Ăn sáng đầu tuần");
      const screen = await call("GET", "/screens/review");
      assert.equal(screen.week.hasData, true);
      assert(screen.week.expense !== "0");
      // Chỉ đánh giá do người dùng tạo mới được tính vào thấu hiểu.
      assert.equal(screen.selfInsight.sampleCount, 1);
      assert.equal(screen.selfInsight.hasEnoughData, false);
      assert.deepEqual(screen.selfInsight.statements, []);
      assert.equal(
        screen.journalSummary.total,
        screen.journal.length,
        "summary khớp danh sách nhật ký",
      );
    });

    await t.test("đánh giá không đồng bộ sai sang thu nhập/chuyển ví",
      async () => {
        const all = await journalOf();
        assert(all.every((x) => x.transaction.type === "expense"));
        const counts = await db
          .collection("reflections")
          .aggregate([
            { $group: { _id: "$transactionId", n: { $sum: 1 } } },
            { $match: { n: { $gt: 1 } } },
          ])
          .toArray();
        assert.equal(counts.length, 0, "luôn có tối đa một bản ghi mỗi giao dịch");
        const orphan = await db
          .collection("reflections")
          .countDocuments({
            transactionId: {
              $in: (
                await db
                  .collection("transactions")
                  .find({ status: "voided" })
                  .project({ _id: 1 })
                  .toArray()
              ).map((x) => x._id),
            },
            status: { $ne: "rated" },
          });
        assert.equal(orphan, 0, "không giữ nhật ký chưa đánh giá của giao dịch hủy");
      },
    );

    await t.test("gợi ý ngân sách dựa trên chi thực tế, không cần đánh giá",
      async () => {
        const screen = await call("GET", "/screens/review");
        const set = screen.budgetSuggestions;
        assert.equal(set.hasBudget, true);
        // Chỉ có 1 đánh giá nên chưa thể dựa vào đánh giá — gợi ý phải đến từ
        // mức chi thực tế so với hạn mức, và luôn có căn cứ giao dịch thật.
        assert(set.suggestions.length >= 1, "phải có gợi ý từ dữ liệu thật");
        for (const s of set.suggestions) {
          assert(["increase_limit", "decrease_limit"].includes(s.kind));
          assert(
            s.proposedLimit !== s.currentLimit,
            "đề xuất phải khác hạn mức hiện tại",
          );
          assert(s.reason.length > 0, "có lý do cụ thể");
          assert(
            s.evidenceTransactionIds.length > 0,
            "có giao dịch căn cứ thật",
          );
        }
        // Không tự áp dụng: hạn mức trong DB vẫn giữ nguyên.
        const plan = await db
          .collection("budget_plans")
          .findOne({ status: "active" });
        const before = plan.limits.map((l) => l.limit.toString());
        const after = (
          await db.collection("budget_plans").findOne({ _id: plan._id })
        ).limits.map((l) => l.limit.toString());
        assert.deepEqual(after, before, "gợi ý không tự sửa ngân sách");
      },
    );

    await t.test("mức dùng hạn mức luôn kèm số liệu thật cho UI", async () => {
      const set = (await call("GET", "/screens/review")).budgetSuggestions;
      assert(set.usage.length >= 1);
      for (const u of set.usage) {
        assert(u.categoryName);
        assert(u.limit !== "0");
        assert(typeof u.percent === "number");
      }
    });

    await t.test("emptyReason nêu đúng việc cần làm khi không có gợi ý",
      async () => {
        // Không có kỳ ngân sách đang mở → phải giải thích cụ thể, không im lặng.
        await db
          .collection("budget_plans")
          .updateMany({ status: "active" }, { $set: { status: "closed" } });
        const set = (await call("GET", "/screens/review")).budgetSuggestions;
        assert.equal(set.hasBudget, false);
        assert.deepEqual(set.suggestions, []);
        assert.equal(set.emptyReason.code, "no_budget");
        assert(set.emptyReason.reason.length > 0);
        assert(set.emptyReason.nextStep.length > 0);
        await db
          .collection("budget_plans")
          .updateMany({ status: "closed" }, { $set: { status: "active" } });
      },
    );

    await t.test("chọn tuần khác chỉ đổi số liệu tuần, nhật ký giữ nguyên",
      async () => {
        const weeks = await call("GET", "/screens/review/weeks");
        assert(weeks.length >= 1);
        const before = await journalOf();
        const w = weeks[0];
        const screen = await call(
          "GET",
          `/screens/review?startAt=${encodeURIComponent(iso(w.startAt))}&endAt=${encodeURIComponent(iso(w.endAt))}`,
        );
        assert.equal(screen.journal.length, before.length);
        assert.equal(screen.week.hasData, true);
      },
    );
  },
);
