import { DateTime } from "luxon";
import {
  base,
  B,
  L,
  I,
  now,
  oid,
  owned,
  fail,
  bounds,
  daysBetween,
  json,
} from "./common.js";
import * as S from "./schemas.js";
import { createEntry, changeEntry, applyImpacts, notify } from "./ledger.js";
import {
  overview,
  budgetView,
  goalView,
  simulate,
  listEntries,
} from "./views.js";
import { budgetAlerts } from "./signals.js";
import { generateBills } from "./jobs.js";

export function financeRoutes(app, ctx, r) {
  const db = ctx.db;
  const ownedList = (col, userId, session) =>
    db.collection(col).find({ userId }, { session }).toArray();
  r("GET", "/wallets", { tag: "Wallets", summary: "Danh sách ví" }, (req) =>
    ownedList("wallets", req.owner),
  );
  r(
    "POST",
    "/wallets",
    {
      write: true,
      body: S.wallet,
      tag: "Wallets",
      summary: "Tạo ví với số dư ban đầu",
    },
    async (req, reply, session) => {
      const b = req.input;
      fail(
        new Date(b.openingAt) <= now(),
        "FUTURE_OPENING",
        "Ngày bắt đầu không được ở tương lai.",
        422,
      );
      const w = {
        ...base(req.owner),
        ...b,
        openingAt: new Date(b.openingAt),
        openingBalance: L(b.openingBalance),
        balance: L(b.openingBalance),
        currency: "VND",
        status: "active",
        version: I(0),
      };
      await db.collection("wallets").insertOne(w, { session });
      return w;
    },
  );
  r(
    "PATCH",
    "/wallets/:id",
    {
      write: true,
      body: S.obj({
        name: S.text.optional(),
        status: S.z.enum(["active", "archived"]).optional(),
      }),
      tag: "Wallets",
      summary: "Đổi tên hoặc lưu trữ ví",
    },
    async (req, reply, session) => {
      const w = await owned(db, "wallets", req.owner, req.params.id, session);
      if (req.input.status === "archived") {
        fail(
          B(w.balance) === 0n,
          "NONZERO_WALLET",
          "Chuyển hết tiền trước khi lưu trữ ví.",
        );
        fail(
          !(await db
            .collection("goal_allocations")
            .findOne(
              { userId: req.owner, walletId: w._id, amount: { $gt: L(0) } },
              { session },
            )),
          "ALLOCATED_FUNDS",
          "Giải phóng tiền mục tiêu trước.",
        );
      }
      await db
        .collection("wallets")
        .updateOne(
          { _id: w._id, userId: req.owner },
          { $set: { ...req.input, updatedAt: now() } },
          { session },
        );
      return owned(db, "wallets", req.owner, w._id, session);
    },
  );
  r(
    "POST",
    "/wallets/:id/reconcile",
    {
      write: true,
      body: S.obj({
        actualBalance: S.money,
        expectedVersion: S.z.number().int().min(0),
        note: S.note.optional(),
      }),
      tag: "Wallets",
      summary: "Đối chiếu và tạo điều chỉnh số dư",
    },
    async (req, reply, session) => {
      const w = await owned(db, "wallets", req.owner, req.params.id, session);
      fail(
        Number(w.version) === req.input.expectedVersion,
        "VERSION_CONFLICT",
        "Số dư đã thay đổi.",
      );
      const delta = BigInt(req.input.actualBalance) - B(w.balance);
      if (delta === 0n) return { unchanged: true, wallet: w };
      return createEntry(
        db,
        req.owner,
        {
          type: "adjustment",
          walletId: req.params.id,
          amount: (delta < 0n ? -delta : delta).toString(),
          adjustmentDirection: delta > 0n ? "increase" : "decrease",
          occurredAt: now().toISOString(),
          note: req.input.note || "Đối chiếu số dư",
          source: "reconciliation",
        },
        req.headers["idempotency-key"],
        session,
      );
    },
  );
  r(
    "GET",
    "/categories",
    { tag: "Categories", summary: "Danh mục thu chi" },
    (req) => ownedList("categories", req.owner),
  );
  r(
    "POST",
    "/categories",
    {
      write: true,
      body: S.category,
      tag: "Categories",
      summary: "Tạo danh mục",
    },
    async (req, reply, session) => {
      const c = { ...base(req.owner), ...req.input, status: "active" };
      await db.collection("categories").insertOne(c, { session });
      return c;
    },
  );
  r(
    "PATCH",
    "/categories/:id",
    {
      write: true,
      body: S.obj({
        name: S.text.optional(),
        icon: S.text.optional(),
        color: S.z
          .string()
          .regex(/^#[\da-f]{6}$/i)
          .optional(),
        status: S.z.enum(["active", "archived"]).optional(),
      }),
      tag: "Categories",
      summary: "Sửa/lưu trữ danh mục",
    },
    async (req, reply, session) => {
      const c = await owned(
        db,
        "categories",
        req.owner,
        req.params.id,
        session,
      );
      await db
        .collection("categories")
        .updateOne(
          { _id: c._id, userId: req.owner },
          { $set: { ...req.input, updatedAt: now() } },
          { session },
        );
      return owned(db, "categories", req.owner, c._id, session);
    },
  );
  r(
    "GET",
    "/transactions",
    {
      query: S.entryQuery,
      tag: "Transactions",
      summary: "Tìm giao dịch và phân trang cursor",
    },
    (req) => listEntries(db, req.owner, req.filters),
  );
  r(
    "GET",
    "/transactions/:id",
    { tag: "Transactions", summary: "Chi tiết giao dịch" },
    (req) => owned(db, "transactions", req.owner, req.params.id),
  );
  r(
    "POST",
    "/transactions",
    {
      write: true,
      body: S.entry,
      tag: "Transactions",
      summary: "Ghi thu/chi/chuyển ví và cập nhật số dư atomically",
    },
    (req, reply, session) =>
      createEntry(
        db,
        req.owner,
        req.input,
        req.headers["idempotency-key"],
        session,
      ),
  );
  r(
    "PUT",
    "/transactions/:id",
    {
      write: true,
      body: S.entry.extend({ expectedVersion: S.version }),
      tag: "Transactions",
      summary: "Sửa giao dịch và đảo tác động cũ",
    },
    (req, reply, session) =>
      changeEntry(db, req.owner, req.params.id, req.input, "edit", session),
  );
  for (const [path, mode] of [
    ["void", "void"],
    ["restore", "restore"],
  ])
    r(
      "POST",
      "/transactions/:id/" + path,
      {
        write: true,
        body: S.obj({ expectedVersion: S.version }),
        tag: "Transactions",
        summary:
          mode === "void"
            ? "Hủy giao dịch và hoàn tiền về ví"
            : "Hoàn tác hủy giao dịch",
      },
      (req, reply, session) =>
        changeEntry(db, req.owner, req.params.id, req.input, mode, session),
    );

  async function validateBudget(userId, b, session, exceptId) {
    bounds(b.startAt, b.endAt);
    fail(
      new Set(b.limits.map((l) => l.categoryId)).size === b.limits.length,
      "DUPLICATE_CATEGORY",
      "Danh mục ngân sách không được lặp.",
      422,
    );
    for (const l of b.limits) {
      const c = await owned(db, "categories", userId, l.categoryId, session);
      fail(
        c.kind === "expense" && c.status === "active",
        "INVALID_CATEGORY",
        "Cần danh mục chi đang hoạt động.",
        422,
      );
    }
    const overlap = await db
      .collection("budget_plans")
      .findOne(
        {
          userId,
          periodType: b.periodType,
          status: "active",
          startAt: { $lt: new Date(b.endAt) },
          endAt: { $gt: new Date(b.startAt) },
          ...(exceptId ? { _id: { $ne: exceptId } } : {}),
        },
        { session },
      );
    fail(
      !overlap,
      "OVERLAPPING_BUDGET",
      "Kỳ ngân sách bị chồng với kỳ đang có.",
    );
    return {
      ...b,
      startAt: new Date(b.startAt),
      endAt: new Date(b.endAt),
      warningPercent: I(b.warningPercent),
      limits: b.limits.map((l) => ({
        categoryId: oid(l.categoryId),
        limit: L(l.limit),
      })),
    };
  }
  r(
    "GET",
    "/budgets",
    { tag: "Plans", summary: "Các ngân sách và số đã chi" },
    async (req) => {
      const plans = await ownedList("budget_plans", req.owner);
      return Promise.all(plans.map((p) => budgetView(db, req.owner, p)));
    },
  );
  r(
    "POST",
    "/budgets",
    { write: true, body: S.budget, tag: "Plans", summary: "Tạo kỳ ngân sách" },
    async (req, reply, session) => {
      const p = {
        ...base(req.owner),
        ...(await validateBudget(req.owner, req.input, session)),
        status: "active",
      };
      await db.collection("budget_plans").insertOne(p, { session });
      await budgetAlerts(db, req.owner, session);
      return budgetView(db, req.owner, p, session);
    },
  );
  r(
    "PUT",
    "/budgets/:id",
    {
      write: true,
      body: S.budget,
      tag: "Plans",
      summary: "Thay đổi hạn mức ngân sách",
    },
    async (req, reply, session) => {
      const p = await owned(
        db,
        "budget_plans",
        req.owner,
        req.params.id,
        session,
      );
      fail(p.status === "active", "BUDGET_CLOSED", "Ngân sách đã đóng.");
      const updated = {
        ...p,
        ...(await validateBudget(req.owner, req.input, session, p._id)),
        updatedAt: now(),
      };
      await db
        .collection("budget_plans")
        .replaceOne({ _id: p._id, userId: req.owner }, updated, { session });
      await budgetAlerts(db, req.owner, session);
      return budgetView(db, req.owner, updated, session);
    },
  );
  r(
    "POST",
    "/budgets/:id/close",
    {
      write: true,
      body: S.obj({}),
      tag: "Plans",
      summary: "Đóng kỳ ngân sách",
    },
    async (req, reply, session) => {
      const p = await owned(
        db,
        "budget_plans",
        req.owner,
        req.params.id,
        session,
      );
      await db
        .collection("budget_plans")
        .updateOne(
          { _id: p._id },
          { $set: { status: "closed", updatedAt: now() } },
          { session },
        );
      await db
        .collection("notifications")
        .updateMany(
          { userId: req.owner, entityId: p._id, type: "budget_warning" },
          { $set: { status: "cancelled", updatedAt: now() } },
          { session },
        );
      return { closed: true };
    },
  );
  r(
    "GET",
    "/goals",
    { tag: "Goals", summary: "Mục tiêu và tiến độ" },
    async (req) =>
      Promise.all(
        (await ownedList("goals", req.owner)).map((g) =>
          goalView(db, req.owner, g),
        ),
      ),
  );
  r(
    "POST",
    "/goals",
    {
      write: true,
      body: S.goal,
      tag: "Goals",
      summary: "Tạo mục tiêu tiết kiệm",
    },
    async (req, reply, session) => {
      const g = {
        ...base(req.owner),
        ...req.input,
        targetAmount: L(req.input.targetAmount),
        ...(req.input.targetAt
          ? { targetAt: new Date(req.input.targetAt) }
          : {}),
        status: "active",
      };
      await db.collection("goals").insertOne(g, { session });
      return g;
    },
  );
  r(
    "PATCH",
    "/goals/:id",
    {
      write: true,
      body: S.obj({
        name: S.text.optional(),
        targetAmount: S.positive.optional(),
        targetAt: S.timestamp.optional(),
        protect: S.z.boolean().optional(),
        status: S.z.enum(["active", "completed", "archived"]).optional(),
      }),
      tag: "Goals",
      summary: "Sửa mục tiêu hoặc bật/tắt bảo vệ",
    },
    async (req, reply, session) => {
      const g = await owned(db, "goals", req.owner, req.params.id, session),
        before = await overview(db, req.owner, { session });
      if (req.input.status && req.input.status !== "active")
        fail(
          !(await db
            .collection("goal_allocations")
            .findOne(
              { userId: req.owner, goalId: g._id, amount: { $gt: L(0) } },
              { session },
            )),
          "ALLOCATED_FUNDS",
          "Giải phóng phân bổ trước khi đóng mục tiêu.",
        );
      const set = { ...req.input, updatedAt: now() };
      if (set.targetAmount) set.targetAmount = L(set.targetAmount);
      if (set.targetAt) set.targetAt = new Date(set.targetAt);
      await db
        .collection("goals")
        .updateOne(
          { _id: g._id, userId: req.owner },
          { $set: set },
          { session },
        );
      return {
        goal: await goalView(
          db,
          req.owner,
          await owned(db, "goals", req.owner, g._id, session),
          session,
        ),
        availableBefore: before.available,
        availableAfter: (await overview(db, req.owner, { session })).available,
      };
    },
  );
  r(
    "PUT",
    "/goals/:id/allocation",
    {
      write: true,
      body: S.obj({ walletId: S.id, amount: S.money }),
      tag: "Goals",
      summary: "Đặt số tiền phân bổ của mục tiêu trong một ví",
    },
    async (req, reply, session) => {
      const g = await owned(db, "goals", req.owner, req.params.id, session),
        w = await owned(db, "wallets", req.owner, req.input.walletId, session);
      fail(
        g.status === "active" && w.status === "active",
        "RESOURCE_CLOSED",
        "Ví hoặc mục tiêu đã đóng.",
      );
      const others = await db
        .collection("goal_allocations")
        .find(
          { userId: req.owner, walletId: w._id, goalId: { $ne: g._id } },
          { session },
        )
        .toArray();
      fail(
        others.reduce((s, a) => s + B(a.amount), 0n) +
          BigInt(req.input.amount) <=
          B(w.balance),
        "OVER_ALLOCATION",
        "Phân bổ vượt tiền thực tế trong ví.",
      );
      await db
        .collection("goal_allocations")
        .updateOne(
          { userId: req.owner, goalId: g._id, walletId: w._id },
          {
            $set: { amount: L(req.input.amount), updatedAt: now() },
            $setOnInsert: { _id: base(req.owner)._id, createdAt: now() },
          },
          { upsert: true, session },
        );
      return goalView(db, req.owner, g, session);
    },
  );

  r(
    "GET",
    "/bill-templates",
    { tag: "Bills", summary: "Lịch hóa đơn định kỳ" },
    (req) => ownedList("bill_templates", req.owner),
  );
  r(
    "POST",
    "/bill-templates",
    {
      write: true,
      body: S.template,
      tag: "Bills",
      summary: "Tạo lịch hóa đơn và sinh các kỳ",
    },
    async (req, reply, session) => {
      const b = req.input,
        c = await owned(db, "categories", req.owner, b.categoryId, session);
      fail(
        c.kind === "expense" && c.status === "active",
        "INVALID_CATEGORY",
        "Danh mục hóa đơn không hợp lệ.",
        422,
      );
      if (b.preferredWalletId)
        await owned(db, "wallets", req.owner, b.preferredWalletId, session);
      const user = await db
        .collection("users")
        .findOne({ _id: req.owner }, { session });
      const t = {
        ...base(req.owner),
        ...b,
        estimatedAmount: L(b.estimatedAmount),
        categoryId: c._id,
        startAt: new Date(b.startAt),
        dueDay: I(DateTime.fromISO(b.startAt, { zone: user.timezone }).day),
        reminderDaysBefore: I(b.reminderDaysBefore),
        active: true,
      };
      if (b.preferredWalletId) t.preferredWalletId = oid(b.preferredWalletId);
      await db.collection("bill_templates").insertOne(t, { session });
      await generateBills(db, req.owner, session);
      return t;
    },
  );
  r(
    "PATCH",
    "/bill-templates/:id",
    {
      write: true,
      body: S.obj({
        active: S.z.boolean(),
        cancelFutureUnpaid: S.z.boolean().default(false),
      }),
      tag: "Bills",
      summary: "Bật/tắt lịch lặp; tùy chọn hủy hóa đơn tương lai chưa trả",
    },
    async (req, reply, session) => {
      const t = await owned(
        db,
        "bill_templates",
        req.owner,
        req.params.id,
        session,
      );
      await db
        .collection("bill_templates")
        .updateOne(
          { _id: t._id },
          { $set: { active: req.input.active, updatedAt: now() } },
          { session },
        );
      if (!req.input.active && req.input.cancelFutureUnpaid) {
        const bills = await db
          .collection("bill_occurrences")
          .find(
            {
              userId: req.owner,
              templateId: t._id,
              status: "unpaid",
              dueAt: { $gt: now() },
            },
            { session },
          )
          .toArray();
        for (const b of bills) {
          await db
            .collection("bill_occurrences")
            .updateOne(
              { _id: b._id },
              { $set: { status: "cancelled", updatedAt: now() } },
              { session },
            );
          await db
            .collection("notifications")
            .updateMany(
              { userId: req.owner, entityId: b._id, status: "pending" },
              { $set: { status: "cancelled", updatedAt: now() } },
              { session },
            );
        }
      }
      return { active: req.input.active };
    },
  );
  r(
    "GET",
    "/bills",
    {
      query: S.obj({
        status: S.z.enum(["unpaid", "paid", "cancelled"]).optional(),
        before: S.timestamp.optional(),
      }),
      tag: "Bills",
      summary: "Hóa đơn từng kỳ và trạng thái quá hạn",
    },
    async (req) => {
      const rows = await db
        .collection("bill_occurrences")
        .find({
          userId: req.owner,
          ...(req.filters.status ? { status: req.filters.status } : {}),
          ...(req.filters.before
            ? { dueAt: { $lt: new Date(req.filters.before) } }
            : {}),
        })
        .sort({ dueAt: 1 })
        .toArray();
      return rows.map((b) => ({
        ...b,
        overdue:
          b.status === "unpaid" &&
          daysBetween(b.dueAt, now(), "Asia/Ho_Chi_Minh") > 0,
      }));
    },
  );
  r(
    "PATCH",
    "/bills/:id",
    {
      write: true,
      body: S.obj({
        amount: S.positive.optional(),
        dueAt: S.timestamp.optional(),
        status: S.z.enum(["unpaid", "cancelled"]).optional(),
      }),
      tag: "Bills",
      summary: "Điều chỉnh hoặc hủy hóa đơn chưa trả",
    },
    async (req, reply, session) => {
      const b = await owned(
        db,
        "bill_occurrences",
        req.owner,
        req.params.id,
        session,
      );
      fail(
        b.status !== "paid",
        "BILL_PAID",
        "Hủy giao dịch thanh toán trước khi sửa hóa đơn.",
      );
      const set = {
        ...req.input,
        scheduledFor: b.scheduledFor || b.dueAt,
        updatedAt: now(),
      };
      if (set.amount) set.amount = L(set.amount);
      if (set.dueAt) set.dueAt = new Date(set.dueAt);
      await db
        .collection("bill_occurrences")
        .updateOne({ _id: b._id }, { $set: set }, { session });
      await db
        .collection("notifications")
        .updateMany(
          { userId: req.owner, entityId: b._id, status: "pending" },
          { $set: { status: "cancelled", updatedAt: now() } },
          { session },
        );
      if ((set.status || b.status) === "unpaid")
        await notify(
          db,
          req.owner,
          "bill_due",
          b._id,
          set.dueAt || b.dueAt,
          "bill-edit:" + b._id + ":" + req.headers["idempotency-key"],
          session,
        );
      return owned(db, "bill_occurrences", req.owner, b._id, session);
    },
  );
  r(
    "POST",
    "/bills/:id/pay",
    {
      write: true,
      body: S.obj({
        walletId: S.id,
        amount: S.positive.optional(),
        occurredAt: S.timestamp,
        note: S.note.optional(),
      }),
      tag: "Bills",
      summary: "Thanh toán hóa đơn và trừ ví cùng một transaction",
    },
    async (req, reply, session) => {
      const bill = await owned(
        db,
        "bill_occurrences",
        req.owner,
        req.params.id,
        session,
      );
      return createEntry(
        db,
        req.owner,
        {
          ...req.input,
          type: "expense",
          amount: req.input.amount || B(bill.amount).toString(),
          categoryId: bill.categoryId.toHexString(),
          billOccurrenceId: req.params.id,
          note: req.input.note || bill.name,
          source: "bill",
        },
        req.headers["idempotency-key"],
        session,
      );
    },
  );
  r(
    "POST",
    "/bills/:id/link-transaction",
    {
      write: true,
      body: S.obj({ transactionId: S.id, expectedVersion: S.version }),
      tag: "Bills",
      summary: "Liên kết khoản chi đã ghi, không trừ ví lần nữa",
    },
    async (req, reply, session) => {
      const bill = await owned(
          db,
          "bill_occurrences",
          req.owner,
          req.params.id,
          session,
        ),
        t = await owned(
          db,
          "transactions",
          req.owner,
          req.input.transactionId,
          session,
        );
      fail(
        bill.status === "unpaid" &&
          t.type === "expense" &&
          t.status === "posted" &&
          !t.billOccurrenceId,
        "INVALID_LINK",
        "Hóa đơn hoặc giao dịch không thể liên kết.",
      );
      fail(
        t.categoryId.equals(bill.categoryId),
        "CATEGORY_MISMATCH",
        "Danh mục giao dịch và hóa đơn phải giống nhau.",
      );
      fail(
        Number(t.version) === req.input.expectedVersion,
        "VERSION_CONFLICT",
        "Giao dịch đã thay đổi.",
      );
      await db
        .collection("transactions")
        .updateOne(
          { _id: t._id, userId: req.owner },
          {
            $set: { billOccurrenceId: bill._id, updatedAt: now() },
            $inc: { version: I(1) },
          },
          { session },
        );
      await db
        .collection("bill_occurrences")
        .updateOne(
          { _id: bill._id },
          {
            $set: {
              status: "paid",
              transactionId: t._id,
              paidAt: t.occurredAt,
              updatedAt: now(),
            },
          },
          { session },
        );
      await db
        .collection("notifications")
        .updateMany(
          { userId: req.owner, entityId: bill._id, status: "pending" },
          { $set: { status: "cancelled", updatedAt: now() } },
          { session },
        );
      return owned(db, "bill_occurrences", req.owner, bill._id, session);
    },
  );
  r(
    "POST",
    "/jobs/run",
    {
      write: true,
      body: S.obj({}),
      tag: "Notifications",
      summary: "Sinh hóa đơn và lịch nhắc cho người dùng hiện tại",
    },
    (req, reply, session) => generateBills(db, req.owner, session),
  );
}
