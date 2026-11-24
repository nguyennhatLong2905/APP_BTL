import { DateTime } from "luxon";
import {
  B,
  L,
  I,
  oid,
  now,
  base,
  fail,
  owned,
  bounds,
  localDay,
  daysBetween,
  fraction,
} from "./common.js";
import * as S from "./schemas.js";
import {
  overview,
  simulate,
  report,
  budgetView,
  goalView,
  listEntries,
  entryMatch,
} from "./views.js";
import { createEntry, notify, autoTrackReview } from "./ledger.js";
import {
  reviewWindow,
  weekBounds,
  weekStats,
  weekNarrative,
  selfInsight,
  budgetSuggestions,
  evidenceTransactions,
  reviewWeeks,
  journal,
  journalSummary,
} from "./review.js";

export function experienceRoutes(app, ctx, r) {
  const db = ctx.db;
  async function enrich(userId, items) {
    const cats = await db.collection("categories").find({ userId }).toArray(),
      wallets = await db.collection("wallets").find({ userId }).toArray();
    const names = (rows, id) =>
      rows.find((x) => id && x._id.equals(id)) || null;
    return items.map((t) => ({
      ...t,
      category: names(cats, t.categoryId),
      wallet: names(wallets, t.walletId),
      fromWallet: names(wallets, t.fromWalletId),
      toWallet: names(wallets, t.toWalletId),
    }));
  }
  async function reviews(userId) {
    return db
      .collection("reflections")
      .aggregate([
        { $match: { userId } },
        {
          $lookup: {
            from: "transactions",
            localField: "transactionId",
            foreignField: "_id",
            as: "transaction",
          },
        },
        { $unwind: "$transaction" },
        {
          $match: {
            "transaction.userId": userId,
            "transaction.status": "posted",
            "transaction.type": "expense",
          },
        },
        { $sort: { dueAt: 1 } },
        { $limit: 100 },
      ])
      .toArray();
  }
  async function patterns(userId) {
    const ratings = await db
      .collection("reflections")
      .aggregate([
        { $match: { userId, status: "rated" } },
        {
          $lookup: {
            from: "transactions",
            localField: "transactionId",
            foreignField: "_id",
            as: "t",
          },
        },
        { $unwind: "$t" },
        {
          $match: {
            "t.userId": userId,
            "t.status": "posted",
            "t.type": "expense",
          },
        },
        {
          $group: {
            _id: { categoryId: "$t.categoryId", rating: "$rating" },
            count: { $sum: 1 },
          },
        },
      ])
      .toArray();
    return {
      sampleCount: ratings.reduce((s, x) => s + x.count, 0),
      byCategory: ratings,
      hasEnoughData: ratings.reduce((s, x) => s + x.count, 0) >= 5,
    };
  }
  const period = S.obj({ startAt: S.timestamp, endAt: S.timestamp });
  // Màn Nhìn lại mặc định tuần hiện tại nên hai mốc đều không bắt buộc.
  const optionalPeriod = S.obj({
    startAt: S.timestamp.optional(),
    endAt: S.timestamp.optional(),
  });
  r(
    "GET",
    "/dashboard",
    {
      tag: "Screens",
      summary: "Tổng quan, cách tính, hóa đơn và giao dịch gần đây",
    },
    async (req) => {
      const o = await overview(db, req.owner),
        recent = await listEntries(db, req.owner, { limit: 3 }),
        user = await db.collection("users").findOne({ _id: req.owner });
      return {
        ...o,
        displayName: user.displayName,
        hideAmounts: user.settings?.hideAmounts || false,
        recentTransactions: await enrich(req.owner, recent.items),
        unreadNotifications: await db
          .collection("notifications")
          .countDocuments({
            userId: req.owner,
            scheduledAt: { $lte: now() },
            status: { $ne: "cancelled" },
            readAt: { $exists: false },
          }),
      };
    },
  );
  r(
    "GET",
    "/screens/add-transaction",
    { tag: "Screens", summary: "Dữ liệu form thêm giao dịch" },
    async (req) => {
      const user = await db.collection("users").findOne({ _id: req.owner });
      return {
        wallets: await db
          .collection("wallets")
          .find({ userId: req.owner, status: "active" })
          .toArray(),
        categories: await db
          .collection("categories")
          .find({ userId: req.owner, status: "active" })
          .toArray(),
        defaultWalletId: user.settings?.defaultWalletId || null,
        defaultOccurredAt: now(),
        quickAmounts: ["10000", "50000", "100000"],
        overview: await overview(db, req.owner),
      };
    },
  );
  r(
    "GET",
    "/screens/transactions",
    {
      query: S.entryQuery,
      tag: "Screens",
      summary: "Giao dịch với tên ví/danh mục và nhóm theo ngày",
    },
    async (req) => {
      const page = await listEntries(db, req.owner, req.filters),
        items = await enrich(req.owner, page.items),
        user = await db.collection("users").findOne({ _id: req.owner }),
        groups = {};
      for (const t of items) {
        const day = localDay(t.occurredAt, user.timezone).toISODate();
        groups[day] ||= {
          date: day,
          items: [],
          pageExpense: 0n,
          pageIncome: 0n,
        };
        groups[day].items.push(t);
        if (t.status === "posted" && t.type === "expense")
          groups[day].pageExpense += B(t.amount);
        if (t.status === "posted" && t.type === "income")
          groups[day].pageIncome += B(t.amount);
      }
      const totals = await db
        .collection("transactions")
        .aggregate([
          { $match: entryMatch(req.owner, req.filters, false) },
          {
            $group: {
              _id: {
                day: {
                  $dateToString: {
                    date: "$occurredAt",
                    format: "%Y-%m-%d",
                    timezone: user.timezone,
                  },
                },
                type: "$type",
                status: "$status",
              },
              amount: { $sum: "$amount" },
            },
          },
        ])
        .toArray();
      for (const g of Object.values(groups)) {
        g.totalExpense = 0n;
        g.totalIncome = 0n;
        for (const row of totals)
          if (row._id.day === g.date && row._id.status === "posted") {
            if (row._id.type === "expense") g.totalExpense += B(row.amount);
            if (row._id.type === "income") g.totalIncome += B(row.amount);
          }
      }
      return {
        ...page,
        items,
        groups: Object.values(groups),
        totalsScope: "allMatchingTransactionsPerDay",
        wallets: await db
          .collection("wallets")
          .find({ userId: req.owner })
          .toArray(),
        categories: await db
          .collection("categories")
          .find({ userId: req.owner })
          .toArray(),
      };
    },
  );
  r(
    "GET",
    "/screens/plans",
    { tag: "Screens", summary: "Ba tab ngân sách, mục tiêu, hóa đơn" },
    async (req) => {
      const budgets = await db
          .collection("budget_plans")
          .find({ userId: req.owner, status: "active" })
          .toArray(),
        goals = await db
          .collection("goals")
          .find({ userId: req.owner, status: "active" })
          .toArray();
      return {
        overview: await overview(db, req.owner),
        budgets: await Promise.all(
          budgets.map((p) => budgetView(db, req.owner, p)),
        ),
        goals: await Promise.all(goals.map((g) => goalView(db, req.owner, g))),
        bills: await db
          .collection("bill_occurrences")
          .find({ userId: req.owner, status: "unpaid" })
          .sort({ dueAt: 1 })
          .toArray(),
        categories: await db
          .collection("categories")
          .find({ userId: req.owner })
          .toArray(),
      };
    },
  );
  r(
    "GET",
    "/reports",
    {
      query: period,
      tag: "Reports",
      summary: "Thu chi theo kỳ và so sánh kỳ trước",
    },
    (req) => {
      const { a, b } = bounds(req.filters.startAt, req.filters.endAt);
      return report(db, req.owner, a, b);
    },
  );
  r(
    "GET",
    "/screens/review",
    {
      query: optionalPeriod,
      tag: "Screens",
      summary: "Báo cáo tuần, nhật ký đáng tiền, thấu hiểu bản thân và gợi ý",
    },
    async (req) => {
      const user = await db
        .collection("users")
        .findOne({ _id: req.owner }, { projection: { timezone: 1 } });
      const zone = user?.timezone || "Asia/Ho_Chi_Minh";

      let wins;
      if (req.filters.startAt && req.filters.endAt) {
        wins = reviewWindow(
          { startAt: req.filters.startAt, endAt: req.filters.endAt },
          zone,
        );
      } else {
        const curWeek = weekBounds(new Date(), zone);
        // Kiểm tra xem tuần hiện tại có giao dịch chi tiêu không
        const curExpense = await db.collection("transactions").findOne({
          userId: req.owner,
          status: "posted",
          type: "expense",
          occurredAt: { $gte: curWeek.start, $lt: curWeek.end },
        });

        if (curExpense) {
          wins = curWeek;
        } else {
          // Tuần hiện tại chưa có chi tiêu: tìm tuần gần nhất có chi tiêu để hiển thị
          const latestExpense = await db.collection("transactions").findOne(
            { userId: req.owner, status: "posted", type: "expense" },
            { sort: { occurredAt: -1 } },
          );
          if (latestExpense && latestExpense.occurredAt) {
            wins = weekBounds(latestExpense.occurredAt, zone);
          } else {
            wins = curWeek;
          }
        }
      }

      const [stats, reflections, insight, suggestions, weeks, categories, entries] =
        await Promise.all([
          weekStats(db, req.owner, wins, zone),
          reviews(req.owner),
          selfInsight(db, req.owner),
          budgetSuggestions(db, req.owner, zone, wins.end || wins.start || new Date()),
          reviewWeeks(db, req.owner, zone),
          db.collection("categories").find({ userId: req.owner }).toArray(),
          journal(db, req.owner),
        ]);

      return {
        // Hình dạng cũ (report) vẫn giữ để không phá hợp đồng hiện có.
        report: await report(db, req.owner, wins.start, wins.end),
        week: {
          ...stats,
          narrative: weekNarrative(stats),
        },
        reflections,
        // Nhật ký tự động: mọi giao dịch chi đều có bản ghi, kèm trạng thái
        // suy ra (tracking / awaiting_review / rated / skipped) và số ngày còn
        // lại trước khi được mời đánh giá.
        journal: entries,
        journalSummary: journalSummary(entries),
        patterns: await patterns(req.owner),
        selfInsight: insight,
        budgetSuggestions: suggestions,
        weeks,
        hasData: stats.hasData,
        minimumSamples: insight.minimumSamples,
        insights: await db
          .collection("insights")
          .find({ userId: req.owner, status: "new" })
          .limit(50)
          .toArray(),
        categories,
      };
    },
  );
  r(
    "GET",
    "/screens/review/weeks",
    {
      query: S.obj({ limit: S.z.coerce.number().int().min(1).max(52).default(12) }),
      tag: "Screens",
      summary: "Danh sách tuần có giao dịch để chọn xem báo cáo",
    },
    async (req) => {
      const user = await db
        .collection("users")
        .findOne({ _id: req.owner }, { projection: { timezone: 1 } });
      return reviewWeeks(
        db,
        req.owner,
        user?.timezone || "Asia/Ho_Chi_Minh",
        req.filters.limit,
      );
    },
  );
  r(
    "GET",
    "/reflections",
    {
      query: S.obj({
        status: S.z
          .enum(["tracking", "awaiting_review", "rated", "skipped", "all"])
          .default("all"),
        limit: S.z.coerce.number().int().min(1).max(500).default(200),
      }),
      tag: "Reflection",
      summary: "Nhật ký Đáng tiền (tự động ghi nhận mọi khoản chi)",
    },
    async (req) => {
      const items = await journal(db, req.owner);
      const status = req.filters.status;
      const filtered =
        status === "all" ? items : items.filter((x) => x.state === status);
      return filtered.slice(0, req.filters.limit);
    },
  );
  r(
    "GET",
    "/reflections/history",
    {
      query: S.obj({
        status: S.z
          .enum(["tracking", "awaiting_review", "rated", "skipped", "all"])
          .default("rated"),
        limit: S.z.coerce.number().int().min(1).max(200).default(50),
      }),
      tag: "Reflection",
      summary: "Lịch sử đánh giá nhật ký (đã đánh giá / bỏ qua / đang chờ)",
    },
    async (req) => {
      const items = await journal(db, req.owner);
      const status = req.filters.status;
      const filtered =
        status === "all" ? items : items.filter((x) => x.state === status);
      return filtered.slice(0, req.filters.limit);
    },
  );
  r(
    "POST",
    "/insights/evidence",
    {
      body: S.obj({
        transactionIds: S.z.array(S.id).min(1).max(50),
      }),
      tag: "Reflection",
      summary: "Chi tiết các giao dịch làm căn cứ cho một nhận xét",
    },
    (req) => evidenceTransactions(db, req.owner, req.input.transactionIds),
  );
  r(
    "POST",
    "/simulations/purchase",
    {
      body: S.obj({ price: S.positive, billOccurrenceId: S.id.optional() }),
      tag: "Simulation",
      summary: "Mua hay chờ: tính tác động, không ghi chi",
    },
    (req) => simulate(db, req.owner, req.input),
  );
  r(
    "POST",
    "/simulations/salary-delay",
    {
      body: S.obj({ delayDays: S.z.number().int().min(1).max(90) }),
      tag: "Simulation",
      summary: "Mô phỏng lương về muộn",
    },
    (req) =>
      simulate(db, req.owner, { price: "0", delayDays: req.input.delayDays }),
  );
  r(
    "POST",
    "/simulations/work-hours",
    {
      body: S.obj({ price: S.positive }),
      tag: "Simulation",
      summary: "Quy đổi giá món hàng thành giờ công",
    },
    async (req) => {
      const u = await db.collection("users").findOne({ _id: req.owner });
      fail(
        u.settings?.workIncome && u.settings?.workHours,
        "MISSING_WORK_SETTINGS",
        "Bổ sung thu nhập và số giờ làm trong thiết lập.",
        422,
      );
      return {
        isSimulation: true,
        hours:
          Number(
            (BigInt(req.input.price) *
              BigInt(Number(u.settings.workHours)) *
              100n) /
              B(u.settings.workIncome),
          ) / 100,
      };
    },
  );
  r(
    "POST",
    "/simulations/habit",
    {
      body: S.obj({
        amountPerOccurrence: S.positive,
        occurrencesPerWeek: S.z.number().int().min(1).max(100),
        weeks: S.z.number().int().min(1).max(104),
        reductionPercent: S.z.number().int().min(1).max(100),
      }),
      tag: "Simulation",
      summary: "Thử giảm một thói quen chi tiêu",
    },
    async (req) => ({
      isSimulation: true,
      estimatedSaving:
        (BigInt(req.input.amountPerOccurrence) *
          BigInt(req.input.occurrencesPerWeek) *
          BigInt(req.input.weeks) *
          BigInt(req.input.reductionPercent)) /
        100n,
      assumptions: req.input,
    }),
  );
  r(
    "GET",
    "/purchases",
    { tag: "Purchases", summary: "Danh sách mong muốn" },
    (req) =>
      db
        .collection("purchase_intents")
        .find({ userId: req.owner })
        .sort({ createdAt: -1 })
        .toArray(),
  );
  r(
    "POST",
    "/purchases",
    {
      write: true,
      body: S.purchase,
      tag: "Purchases",
      summary: "Lưu khoản mua để cân nhắc",
    },
    async (req, reply, session) => {
      const cat = await owned(
        db,
        "categories",
        req.owner,
        req.input.categoryId,
        session,
      );
      fail(
        cat.kind === "expense",
        "INVALID_CATEGORY",
        "Chọn danh mục chi.",
        422,
      );
      const p = {
        ...base(req.owner),
        ...req.input,
        categoryId: cat._id,
        price: L(req.input.price),
        status: "waiting",
      };
      if (p.remindAt) p.remindAt = new Date(p.remindAt);
      if (p.dailySaving) p.dailySaving = L(p.dailySaving);
      await db.collection("purchase_intents").insertOne(p, { session });
      if (p.remindAt)
        await notify(
          db,
          req.owner,
          "purchase_reminder",
          p._id,
          p.remindAt,
          "purchase:" + p._id,
          session,
        );
      return p;
    },
  );
  r(
    "GET",
    "/purchases/:id",
    { tag: "Purchases", summary: "Chi tiết khoản mua và tác động hiện tại" },
    async (req) => {
      const p = await owned(db, "purchase_intents", req.owner, req.params.id);
      return {
        purchase: p,
        simulation: await simulate(db, req.owner, {
          price: B(p.price).toString(),
        }),
      };
    },
  );
  r(
    "PATCH",
    "/purchases/:id",
    {
      write: true,
      body: S.obj({
        name: S.text.optional(),
        price: S.positive.optional(),
        remindAt: S.timestamp.optional(),
        dailySaving: S.money.optional(),
        status: S.z.enum(["waiting", "cancelled"]).optional(),
      }),
      tag: "Purchases",
      summary: "Sửa giá hoặc nhắc lại khoản mua",
    },
    async (req, reply, session) => {
      const p = await owned(
        db,
        "purchase_intents",
        req.owner,
        req.params.id,
        session,
      );
      fail(
        p.status !== "purchased",
        "PURCHASED",
        "Hủy giao dịch mua trước khi sửa.",
      );
      const set = { ...req.input, updatedAt: now() };
      if (set.price) set.price = L(set.price);
      if (set.dailySaving) set.dailySaving = L(set.dailySaving);
      if (set.remindAt) set.remindAt = new Date(set.remindAt);
      await db
        .collection("purchase_intents")
        .updateOne({ _id: p._id }, { $set: set }, { session });
      await db
        .collection("notifications")
        .updateMany(
          { userId: req.owner, entityId: p._id, status: "pending" },
          { $set: { status: "cancelled", updatedAt: now() } },
          { session },
        );
      if (set.remindAt && set.status !== "cancelled")
        await notify(
          db,
          req.owner,
          "purchase_reminder",
          p._id,
          set.remindAt,
          "purchase:" + p._id + ":" + req.headers["idempotency-key"],
          session,
        );
      return owned(db, "purchase_intents", req.owner, p._id, session);
    },
  );
  r(
    "POST",
    "/purchases/:id/buy",
    {
      write: true,
      body: S.obj({
        walletId: S.id,
        occurredAt: S.timestamp,
        trackReview: S.z.boolean().default(true),
      }),
      tag: "Purchases",
      summary: "Xác nhận mua và tạo giao dịch thực tế",
    },
    async (req, reply, session) => {
      const p = await owned(
        db,
        "purchase_intents",
        req.owner,
        req.params.id,
        session,
      );
      const simulation = await simulate(
        db,
        req.owner,
        { price: B(p.price).toString() },
        session,
      );
      const t = await createEntry(
        db,
        req.owner,
        {
          ...req.input,
          type: "expense",
          amount: B(p.price).toString(),
          categoryId: p.categoryId.toHexString(),
          purchaseIntentId: req.params.id,
          note: p.name,
          source: "purchase",
        },
        req.headers["idempotency-key"],
        session,
      );
      return { transaction: t, simulation };
    },
  );
  r(
    "POST",
    "/purchases/:id/saving-plan",
    {
      write: true,
      body: S.obj({ targetAt: S.timestamp, dailySaving: S.positive }),
      tag: "Purchases",
      summary: "Để dành mua sau: tạo mục tiêu, chưa phân bổ tiền",
    },
    async (req, reply, session) => {
      const p = await owned(
        db,
        "purchase_intents",
        req.owner,
        req.params.id,
        session,
      );
      fail(
        ["draft", "waiting"].includes(p.status),
        "PURCHASED",
        "Khoản mua đã hoàn tất.",
      );
      if (p.goalId) return owned(db, "goals", req.owner, p.goalId, session);
      const g = {
        ...base(req.owner),
        name: p.name,
        targetAmount: p.price,
        targetAt: new Date(req.input.targetAt),
        protect: true,
        status: "active",
      };
      await db.collection("goals").insertOne(g, { session });
      await db.collection("purchase_intents").updateOne(
        { _id: p._id },
        {
          $set: {
            goalId: g._id,
            dailySaving: L(req.input.dailySaving),
            status: "waiting",
            updatedAt: now(),
          },
        },
        { session },
      );
      return g;
    },
  );
  r(
    "POST",
    "/seasonal-goals",
    {
      write: true,
      body: S.obj({
        name: S.text,
        targetAmount: S.positive,
        targetAt: S.timestamp,
      }),
      tag: "Goals",
      summary: "Lập quỹ Tết, học phí, hiếu hỉ",
    },
    async (req, reply, session) => {
      const days = daysBetween(
        now(),
        new Date(req.input.targetAt),
        "Asia/Ho_Chi_Minh",
      );
      fail(
        days > 0,
        "INVALID_TARGET_DATE",
        "Ngày mục tiêu phải ở tương lai.",
        422,
      );
      const g = {
        ...base(req.owner),
        ...req.input,
        targetAmount: L(req.input.targetAmount),
        targetAt: new Date(req.input.targetAt),
        protect: true,
        status: "active",
        seasonal: true,
      };
      await db.collection("goals").insertOne(g, { session });
      return {
        goal: g,
        dailySaving:
          (BigInt(req.input.targetAmount) + BigInt(days) - 1n) / BigInt(days),
      };
    },
  );
  r(
    "GET",
    "/reflections/:id",
    { tag: "Reflection", summary: "Chi tiết một mục nhật ký" },
    async (req) => {
      const items = await journal(db, req.owner);
      const found = items.find((x) => x._id.toHexString() === req.params.id);
      fail(found, "NOT_FOUND", "Không tìm thấy nhật ký.", 404);
      return found;
    },
  );
  r(
    "PUT",
    "/reflections/:id",
    {
      write: true,
      body: S.obj({
        status: S.z.enum(["rated", "skipped"]),
        rating: S.z.enum(["worth_it", "neutral", "reconsider"]).optional(),
        note: S.note.optional(),
      }),
      tag: "Reflection",
      summary: "Lưu đánh giá hoặc bỏ qua",
    },
    async (req, reply, session) => {
      // Nhật ký được tạo tự động nên client có thể gửi id bản ghi nhật ký hoặc
      // id giao dịch. Chuẩn hoá về bản ghi hiện có, tạo nếu dữ liệu cũ thiếu.
      let ref = await db
        .collection("reflections")
        .findOne(
          { userId: req.owner, _id: oid(req.params.id) },
          { session },
        );
      if (!ref) {
        const t0 = await owned(
          db,
          "transactions",
          req.owner,
          req.params.id,
          session,
        );
        fail(
          t0.type === "expense" && t0.status === "posted",
          "INVALID_REFLECTION",
          "Chỉ đánh giá khoản chi đang có hiệu lực.",
        );
        ref = await autoTrackReview(db, req.owner, t0, session);
      }
      const t = await owned(
        db,
        "transactions",
        req.owner,
        ref.transactionId,
        session,
      );
      fail(
        t.status === "posted" && t.type === "expense",
        "VOIDED_TRANSACTION",
        "Giao dịch đã bị hủy.",
      );
      fail(
        req.input.status !== "rated" || req.input.rating,
        "RATING_REQUIRED",
        "Chọn mức đánh giá.",
        422,
      );
      const update = {
        $set: {
          status: req.input.status,
          note: req.input.note || "",
          updatedAt: now(),
        },
      };
      if (req.input.status === "rated") {
        update.$set.rating = req.input.rating;
        update.$set.ratedAt = now();
      } else update.$unset = { rating: "", ratedAt: "" };
      await db
        .collection("reflections")
        .updateOne({ _id: ref._id }, update, { session });
      await db
        .collection("insights")
        .updateMany(
          { userId: req.owner, status: "new", evidenceTransactionIds: t._id },
          { $set: { status: "dismissed", updatedAt: now() } },
          { session },
        );
      await db
        .collection("notifications")
        .updateMany(
          { userId: req.owner, entityId: ref._id, status: "pending" },
          { $set: { status: "cancelled", updatedAt: now() } },
          { session },
        );
      return owned(db, "reflections", req.owner, ref._id, session);
    },
  );
  r(
    "GET",
    "/insights",
    { tag: "Reflection", summary: "Gợi ý đã lưu và căn cứ" },
    (req) =>
      db
        .collection("insights")
        .find({ userId: req.owner })
        .sort({ generatedAt: -1 })
        .limit(100)
        .toArray(),
  );
  r(
    "POST",
    "/insights/:id/dismiss",
    { write: true, body: S.obj({}), tag: "Reflection", summary: "Ẩn gợi ý" },
    async (req, reply, session) => {
      const i = await owned(db, "insights", req.owner, req.params.id, session);
      await db
        .collection("insights")
        .updateOne(
          { _id: i._id },
          { $set: { status: "dismissed", updatedAt: now() } },
          { session },
        );
      return { dismissed: true };
    },
  );
  r(
    "GET",
    "/challenges",
    { tag: "Reflection", summary: "Các thử thách đang theo dõi" },
    (req) => db.collection("challenges").find({ userId: req.owner }).toArray(),
  );
  r(
    "POST",
    "/challenges",
    {
      write: true,
      body: S.obj({
        type: S.z.enum(["cooldown_48h", "reduce_habit"]),
        purchaseIntentId: S.id.optional(),
        durationDays: S.z.number().int().min(1).max(365).optional(),
      }),
      tag: "Reflection",
      summary: "Kích hoạt khoảng lặng 48h hoặc thay đổi thói quen",
    },
    async (req, reply, session) => {
      if (req.input.purchaseIntentId)
        await owned(
          db,
          "purchase_intents",
          req.owner,
          req.input.purchaseIntentId,
          session,
        );
      const c = {
        ...base(req.owner),
        type: req.input.type,
        startAt: now(),
        endAt: new Date(
          Date.now() +
            (req.input.type === "cooldown_48h"
              ? 2
              : req.input.durationDays || 7) *
              86400000,
        ),
        status: "active",
      };
      if (req.input.purchaseIntentId)
        c.purchaseIntentId = oid(req.input.purchaseIntentId);
      await db.collection("challenges").insertOne(c, { session });
      return c;
    },
  );
  r(
    "POST",
    "/challenges/:id/cancel",
    {
      write: true,
      body: S.obj({}),
      tag: "Reflection",
      summary: "Dừng thử thách",
    },
    async (req, reply, session) => {
      const c = await owned(
        db,
        "challenges",
        req.owner,
        req.params.id,
        session,
      );
      await db
        .collection("challenges")
        .updateOne(
          { _id: c._id },
          { $set: { status: "cancelled", updatedAt: now() } },
          { session },
        );
      return { cancelled: true };
    },
  );
  r(
    "GET",
    "/notifications",
    {
      tag: "Notifications",
      summary: "Thông báo trong app đã đến thời điểm hiển thị",
    },
    (req) =>
      db
        .collection("notifications")
        .find({
          userId: req.owner,
          status: { $ne: "cancelled" },
          scheduledAt: { $lte: now() },
        })
        .sort({ scheduledAt: -1 })
        .limit(100)
        .toArray(),
  );
  r(
    "POST",
    "/notifications/:id/read",
    {
      write: true,
      body: S.obj({}),
      tag: "Notifications",
      summary: "Đánh dấu đã đọc",
    },
    async (req, reply, session) => {
      const n = await owned(
        db,
        "notifications",
        req.owner,
        req.params.id,
        session,
      );
      await db
        .collection("notifications")
        .updateOne(
          { _id: n._id },
          { $set: { readAt: now(), updatedAt: now() } },
          { session },
        );
      return { read: true };
    },
  );
  r(
    "POST",
    "/recommendations",
    {
      body: S.obj({
        question: S.note,
        options: S.z
          .array(S.obj({ name: S.text, price: S.positive }))
          .min(1)
          .max(5),
        minimumDaily: S.money.default("0"),
      }),
      tag: "Advice",
      summary: "So sánh các phương án bằng dữ liệu tài chính thật",
    },
    async (req) => {
      const o = await overview(db, req.owner);
      const options = [];
      for (const option of req.input.options) {
        const availableAfter =
          o.available === null ? null : o.available - BigInt(option.price);
        const sim = {
          availableAfter,
          dailyAfter:
            availableAfter !== null && o.daysRemaining > 0
              ? availableAfter / BigInt(o.daysRemaining)
              : null,
        };
        const reason =
          sim.availableAfter === null
            ? "Thiếu ngày lương để tính."
            : sim.availableAfter < 0n
              ? "Khoản mua vượt tiền còn để chi."
              : sim.dailyAfter !== null &&
                  sim.dailyAfter < BigInt(req.input.minimumDaily)
                ? "Sau khi mua, mức bình quân thấp hơn ngưỡng bạn đặt."
                : "Khoản mua nằm trong tiền còn để chi; bạn vẫn cần cân nhắc nhu cầu.";
        options.push({
          ...option,
          availableAfter: sim.availableAfter,
          dailyAfter: sim.dailyAfter,
          reason,
        });
      }
      return {
        engine: "rules",
        question: req.input.question,
        overview: o,
        options,
        alternatives: [
          "Chờ đến kỳ lương rồi tính lại.",
          "Đặt mục tiêu để dành và chọn ngày nhắc.",
        ],
        requiresConfirmation: true,
        notice:
          "Gợi ý theo phép tính và quy tắc. Chưa gọi mô hình AI; không có giá sản phẩm trực tiếp.",
      };
    },
  );
}
