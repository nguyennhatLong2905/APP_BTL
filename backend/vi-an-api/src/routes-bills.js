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
} from "./common.js";
import * as S from "./schemas.js";
import {
  billView,
  billsSummary,
  billPayPreview,
  derivedBillStatus,
  billZone,
} from "./bills.js";
import { generateBills } from "./jobs.js";
import { overview } from "./views.js";
import { createEntry } from "./ledger.js";

/**
 * Các endpoint bổ sung cho tính năng "Hóa đơn định kỳ".
 * Không thay thế endpoint cũ (/bills, /bills/:id/pay,
 * /bills/:id/link-transaction, /bill-templates) — chỉ mở rộng thêm.
 */
export function billRoutes(app, ctx, r) {
  const db = ctx.db;

  async function loadBill(req, session) {
    return owned(db, "bill_occurrences", req.owner, req.params.id, session);
  }
  async function currentUser(req, session) {
    return db.collection("users").findOne({ _id: req.owner }, { session });
  }

  // ── Màn hình Hóa đơn: tổng quan + danh sách kèm trạng thái suy ra ──
  r(
    "GET",
    "/screens/bills",
    {
      tag: "Bills",
      summary: "Tab Hóa đơn: tổng quan, danh sách và phân nhóm trạng thái",
    },
    async (req) => {
      const [rows, cats, wallets, o] = await Promise.all([
        db
          .collection("bill_occurrences")
          .find({ userId: req.owner })
          .sort({ dueAt: 1 })
          .toArray(),
        db.collection("categories").find({ userId: req.owner }).toArray(),
        db
          .collection("wallets")
          .find({ userId: req.owner, status: "active" })
          .toArray(),
        overview(db, req.owner),
      ]);
      const views = await Promise.all(
        rows.map((b) =>
          billView(db, req.owner, b, undefined, new Date(), {
            withTransaction: true,
          }),
        ),
      );
      return {
        overview: o,
        bills: views,
        summary: billsSummary(views),
        categories: cats,
        wallets,
        payday: o.nextPayday,
      };
    },
  );

  // ── Chi tiết một kỳ hóa đơn ────────────────────────────────────────
  r(
    "GET",
    "/bills/:id",
    { tag: "Bills", summary: "Chi tiết hóa đơn và lịch sử thanh toán" },
    async (req) => {
      const bill = await loadBill(req);
      return billView(db, req.owner, bill);
    },
  );

  // ── Giao dịch chi có thể liên kết (chưa gắn hóa đơn khác) ──────────
  r(
    "GET",
    "/bills/:id/candidate-transactions",
    {
      query: S.obj({
        search: S.z.string().max(100).optional(),
        limit: S.z.coerce.number().int().min(1).max(50).default(20),
      }),
      tag: "Bills",
      summary: "Giao dịch chi phù hợp để liên kết với hóa đơn",
    },
    async (req) => {
      const bill = await loadBill(req);
      const filter = {
        userId: req.owner,
        type: "expense",
        status: "posted",
        categoryId: bill.categoryId,
        billOccurrenceId: { $exists: false },
      };
      if (req.filters.search)
        filter.note = {
          $regex: String(req.filters.search).replace(/[.*+?^${}()|[\]\\]/g, "\\$&"),
          $options: "i",
        };
      const rows = await db
        .collection("transactions")
        .find(filter)
        .sort({ occurredAt: -1, _id: -1 })
        .limit(req.filters.limit)
        .toArray();
      return rows.map((t) => ({
        _id: t._id,
        amount: t.amount,
        occurredAt: t.occurredAt,
        note: t.note || null,
        version: t.version,
        walletId: t.walletId || null,
        categoryId: t.categoryId,
      }));
    },
  );

  // ── Xem trước tác động 3 lớp khi thanh toán (không ghi dữ liệu) ────
  r(
    "POST",
    "/bills/:id/pay-preview",
    {
      body: S.obj({ amount: S.positive.optional() }),
      tag: "Bills",
      summary: "Tác động lên 3 lớp tiền nếu thanh toán hóa đơn",
    },
    async (req) => {
      const bill = await loadBill(req);
      return billPayPreview(
        db,
        req.owner,
        bill,
        req.input.amount || B(bill.amount).toString(),
      );
    },
  );

  // ── Hủy một kỳ hóa đơn chưa thanh toán ────────────────────────────
  r(
    "POST",
    "/bills/:id/cancel",
    {
      write: true,
      body: S.obj({}),
      tag: "Bills",
      summary: "Hủy hóa đơn chưa thanh toán",
    },
    async (req, reply, session) => {
      const bill = await loadBill(req, session);
      fail(
        bill.status === "unpaid",
        "BILL_PAID",
        "Hóa đơn đã thanh toán, cần hủy giao dịch thanh toán trước.",
      );
      await db
        .collection("bill_occurrences")
        .updateOne(
          { _id: bill._id, userId: req.owner },
          { $set: { status: "cancelled", updatedAt: now() } },
          { session },
        );
      await db
        .collection("notifications")
        .updateMany(
          { userId: req.owner, entityId: bill._id, status: "pending" },
          { $set: { status: "cancelled", updatedAt: now() } },
          { session },
        );
      return billView(db, req.owner, bill, session);
    },
  );

  // ── Xóa hẳn một kỳ hóa đơn chưa thanh toán ────────────────────────
  r(
    "DELETE",
    "/bills/:id",
    { tag: "Bills", summary: "Xóa hóa đơn chưa thanh toán" },
    async (req) => {
      const bill = await loadBill(req);
      fail(
        bill.status !== "paid",
        "BILL_PAID",
        "Không xóa hóa đơn đã thanh toán; hãy hủy giao dịch thanh toán trước.",
      );
      await db
        .collection("bill_occurrences")
        .deleteOne({ _id: bill._id, userId: req.owner });
      await db
        .collection("notifications")
        .updateMany(
          { userId: req.owner, entityId: bill._id, status: "pending" },
          { $set: { status: "cancelled", updatedAt: now() } },
        );
      return { deleted: true };
    },
  );

  // ── Dừng lịch định kỳ (toàn bộ hóa đơn tương lai chưa trả) ────────
  r(
    "POST",
    "/bill-templates/:id/stop",
    {
      write: true,
      body: S.obj({ cancelFutureUnpaid: S.z.boolean().default(true) }),
      tag: "Bills",
      summary: "Ngừng hóa đơn định kỳ và hủy các kỳ tương lai chưa trả",
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
          { _id: t._id, userId: req.owner },
          { $set: { active: false, updatedAt: now() } },
          { session },
        );
      if (req.input.cancelFutureUnpaid) {
        const future = await db
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
        for (const b of future) {
          await db
            .collection("bill_occurrences")
            .updateOne(
              { _id: b._id, userId: req.owner },
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
      return { active: false };
    },
  );

  // ── Sửa đầy đủ hóa đơn định kỳ ─────────────────────────────────────
  r(
    "PUT",
    "/bill-templates/:id",
    {
      write: true,
      body: S.obj({
        name: S.text.optional(),
        estimatedAmount: S.positive.optional(),
        categoryId: S.id.optional(),
        preferredWalletId: S.id.optional(),
        frequency: S.z
          .enum(["once", "weekly", "monthly", "quarterly", "yearly"])
          .optional(),
        startAt: S.timestamp.optional(),
        endAt: S.timestamp.nullable().optional(),
        note: S.note.optional(),
        reminderDaysBefore: S.z.number().int().min(0).max(30).optional(),
        active: S.z.boolean().optional(),
      }),
      tag: "Bills",
      summary: "Chỉnh sửa toàn bộ thông tin hóa đơn định kỳ",
    },
    async (req, reply, session) => {
      const t = await owned(
        db,
        "bill_templates",
        req.owner,
        req.params.id,
        session,
      );
      const set = { ...req.input, updatedAt: now() };
      const unset = {};
      if (set.estimatedAmount) set.estimatedAmount = L(set.estimatedAmount);
      if (set.startAt) set.startAt = new Date(set.startAt);
      if (set.endAt === null) {
        // Cho phép bỏ hạn kết thúc.
        delete set.endAt;
        unset.endAt = "";
      } else if (set.endAt) set.endAt = new Date(set.endAt);
      if (set.categoryId) {
        const c = await owned(
          db,
          "categories",
          req.owner,
          set.categoryId,
          session,
        );
        fail(
          c.kind === "expense" && c.status === "active",
          "INVALID_CATEGORY",
          "Danh mục hóa đơn không hợp lệ.",
          422,
        );
        set.categoryId = c._id;
      }
      if (set.preferredWalletId) {
        await owned(db, "wallets", req.owner, set.preferredWalletId, session);
        set.preferredWalletId = oid(set.preferredWalletId);
      }
      if (set.startAt) {
        const user = await currentUser(req, session);
        set.dueDay = I(
          DateTime.fromJSDate(set.startAt, { zone: billZone(user) }).day,
        );
      }
      // Nếu đổi lịch (startAt/frequency/endAt) → bỏ các kỳ tương lai chưa trả
      // để bộ sinh lịch tạo lại đúng chuỗi kỳ mới (tránh trùng/không cập nhật).
      const reschedule =
        !!set.startAt || !!set.frequency || Object.hasOwn(req.input, "endAt");
      if (reschedule) {
        await db
          .collection("bill_occurrences")
          .deleteMany(
            {
              userId: req.owner,
              templateId: t._id,
              status: "unpaid",
              transactionId: { $exists: false },
              dueAt: { $gt: now() },
            },
            { session },
          );
      }
      // Các kỳ tương lai chưa trả còn lại: đồng bộ tên/số tiền/danh mục.
      // Lưu ý: cột số tiền trên kỳ là `amount`, còn template là
      // `estimatedAmount` (khác tên) nên phải map tường minh.
      const futureSync = {};
      if (req.input.name !== undefined) futureSync.name = set.name;
      if (req.input.estimatedAmount !== undefined)
        futureSync.amount = set.estimatedAmount;
      if (req.input.categoryId !== undefined)
        futureSync.categoryId = set.categoryId;
      if (Object.keys(futureSync).length) {
        await db
          .collection("bill_occurrences")
          .updateMany(
            {
              userId: req.owner,
              templateId: t._id,
              status: "unpaid",
              transactionId: { $exists: false },
              dueAt: { $gt: now() },
            },
            { $set: { ...futureSync, updatedAt: now() } },
            { session },
          );
      }
      await db
        .collection("bill_templates")
        .updateOne(
          { _id: t._id, userId: req.owner },
          {
            $set: set,
            ...(Object.keys(unset).length ? { $unset: unset } : {}),
          },
          { session },
        );
      await generateBills(db, req.owner, session);
      return owned(db, "bill_templates", req.owner, t._id, session);
    },
  );

  // ── Thanh toán: kiểm tra trạng thái trước khi tạo giao dịch ────────
  // (endpoint gốc POST /bills/:id/pay vẫn giữ; đây là bản có tiền kiểm
  //  và trả kèm ảnh hưởng 3 lớp để UI hiển thị sau khi trả.)
  r(
    "POST",
    "/bills/:id/settle",
    {
      write: true,
      body: S.obj({
        walletId: S.id,
        amount: S.positive.optional(),
        occurredAt: S.timestamp,
        note: S.note.optional(),
        allowNegativeAvailable: S.z.boolean().default(false),
      }),
      tag: "Bills",
      summary: "Xác nhận thanh toán hóa đơn (idempotent, chống trả trùng)",
    },
    async (req, reply, session) => {
      const bill = await loadBill(req, session);
      // Chống thanh toán trùng: hóa đơn đã trả thì từ chối.
      fail(
        bill.status === "unpaid",
        "BILL_ALREADY_PAID",
        "Hóa đơn này đã được thanh toán.",
      );
      const preview = await billPayPreview(
        db,
        req.owner,
        bill,
        req.input.amount || B(bill.amount).toString(),
      );
      fail(
        !preview.requiresConfirmation || req.input.allowNegativeAvailable,
        "NEGATIVE_AVAILABLE_CONFIRMATION",
        "Thanh toán làm tiền còn để chi âm. Cần xác nhận rõ ràng.",
      );
      const { allowNegativeAvailable, ...payload } = req.input;
      const created = await createBillPayment(
        db,
        req.owner,
        bill,
        payload,
        req.headers["idempotency-key"],
        session,
      );
      await generateBills(db, req.owner, session);
      const fresh = await owned(db, "bill_occurrences", req.owner, bill._id, session);
      return {
        transaction: created,
        preview,
        bill: await billView(db, req.owner, fresh, session),
      };
    },
  );

  r(
    "POST",
    "/bills/:id/link",
    {
      write: true,
      body: S.obj({
        transactionId: S.id,
        expectedVersion: S.version,
      }),
      tag: "Bills",
      summary: "Liên kết giao dịch chi đã có và đánh dấu hóa đơn đã trả",
    },
    async (req, reply, session) => {
      const bill = await loadBill(req, session);
      fail(
        bill.status === "unpaid",
        "BILL_ALREADY_PAID",
        "Hóa đơn này đã được thanh toán.",
      );
      const t = await owned(
        db,
        "transactions",
        req.owner,
        req.input.transactionId,
        session,
      );
      fail(
        t.type === "expense" && t.status === "posted" && !t.billOccurrenceId,
        "INVALID_LINK",
        "Chỉ giao dịch chi đang có hiệu lực và chưa gắn hóa đơn mới liên kết được.",
      );
      fail(
        t.categoryId.equals(bill.categoryId),
        "CATEGORY_MISMATCH",
        "Danh mục giao dịch và hóa đơn phải giống nhau.",
      );
      fail(
        Number(t.version) === req.input.expectedVersion,
        "VERSION_CONFLICT",
        "Giao dịch đã thay đổi; hãy tải lại.",
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
          { _id: bill._id, userId: req.owner },
          {
            $set: {
              status: "paid",
              transactionId: t._id,
              paidAt: t.occurredAt,
              paidAmount: t.amount,
              paymentMethod: "linked_transaction",
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
      await generateBills(db, req.owner, session);
      const fresh = await owned(
        db,
        "bill_occurrences",
        req.owner,
        bill._id,
        session,
      );
      return billView(db, req.owner, fresh, session);
    },
  );
}

// Tạo giao dịch chi cho hóa đơn, dùng chung createEntry của ledger để
// đảm bảo cập nhật số dư ví + kiểm tra hạn mức trong cùng session.
async function createBillPayment(db, userId, bill, payload, key, session) {
  const t = await createEntry(
    db,
    userId,
    {
      ...payload,
      type: "expense",
      amount: payload.amount || B(bill.amount).toString(),
      categoryId: bill.categoryId.toHexString(),
      billOccurrenceId: bill._id.toHexString(),
      note: payload.note || bill.name,
      source: "bill",
    },
    key,
    session,
  );
  await db
    .collection("bill_occurrences")
    .updateOne(
      { _id: bill._id, userId },
      {
        $set: {
          paidAmount: t.amount,
          paymentMethod: "new_transaction",
          updatedAt: now(),
        },
      },
      { session },
    );
  return t;
}
