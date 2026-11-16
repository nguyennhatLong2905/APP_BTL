import { DateTime } from "luxon";
import { B, fail, owned } from "./common.js";
import { overview } from "./views.js";

// ════════════════════════════════════════════════════════════════════
// Hóa đơn định kỳ – tiện ích dùng chung cho routes & screens
// ════════════════════════════════════════════════════════════════════

export const billZone = (user) => user?.timezone || "Asia/Ho_Chi_Minh";

/** Trạng thái hiển thị suy ra từ ngày hiện tại (không ghi đè status gốc). */
export function derivedBillStatus(bill, at = new Date(), zone = "Asia/Ho_Chi_Minh") {
  if (bill.status !== "unpaid") return bill.status;
  const today = DateTime.fromJSDate(at, { zone }).startOf("day");
  const due = DateTime.fromJSDate(bill.dueAt, { zone }).startOf("day");
  if (due < today) return "overdue";
  if (due.equals(today)) return "due";
  return "upcoming";
}

export function billDaysUntilDue(bill, at = new Date(), zone = "Asia/Ho_Chi_Minh") {
  return Math.round(
    DateTime.fromJSDate(bill.dueAt, { zone })
      .startOf("day")
      .diff(DateTime.fromJSDate(at, { zone }).startOf("day"), "days").days,
  );
}

/** Một kỳ hóa đơn kèm template + giao dịch thanh toán + trạng thái suy ra. */
export async function billView(
  db,
  userId,
  bill,
  session,
  at = new Date(),
  { withTransaction = true } = {},
) {
  const user = await db.collection("users").findOne({ _id: userId }, { session });
  const zone = billZone(user);
  const template = bill.templateId
    ? await db
        .collection("bill_templates")
        .findOne({ _id: bill.templateId, userId }, { session })
    : null;
  const transaction =
    withTransaction && bill.transactionId
      ? await db
          .collection("transactions")
          .findOne({ _id: bill.transactionId, userId }, { session })
      : null;
  return {
    ...bill,
    derivedStatus: derivedBillStatus(bill, at, zone),
    daysUntilDue: billDaysUntilDue(bill, at, zone),
    frequency: template?.frequency || "once",
    templateActive: !!template?.active,
    templateStartAt: template?.startAt || null,
    templateEndAt: template?.endAt || null,
    reminderDaysBefore: template?.reminderDaysBefore ?? 0,
    note: bill.note ?? template?.note ?? null,
    payment: transaction
      ? {
          transactionId: transaction._id,
          amount: transaction.amount,
          occurredAt: transaction.occurredAt,
          method: bill.paymentMethod || "new_transaction",
        }
      : null,
  };
}

export function billsSummary(bills) {
  const s = {
    total: bills.length,
    unpaidCount: 0,
    upcomingCount: 0,
    dueCount: 0,
    overdueCount: 0,
    paidCount: 0,
    cancelledCount: 0,
    unpaidTotal: 0n,
    overdueTotal: 0n,
    dueTotal: 0n,
    paidTotal: 0n,
  };
  for (const b of bills) {
    const amount = B(b.amount);
    switch (b.derivedStatus) {
      case "upcoming":
        s.upcomingCount++;
        s.unpaidCount++;
        s.unpaidTotal += amount;
        break;
      case "due":
        s.dueCount++;
        s.unpaidCount++;
        s.unpaidTotal += amount;
        s.dueTotal += amount;
        break;
      case "overdue":
        s.overdueCount++;
        s.unpaidCount++;
        s.unpaidTotal += amount;
        s.overdueTotal += amount;
        break;
      case "paid":
        s.paidCount++;
        s.paidTotal += B(b.paidAmount ?? b.amount);
        break;
      default:
        s.cancelledCount++;
    }
  }
  return s;
}

/**
 * Xem trước tác động 3 lớp khi thanh toán hóa đơn — KHÔNG ghi dữ liệu.
 *
 * Công thức bám đúng overview() hiện có:
 *   available = total − protectedMoney − unpaidBills(đã giữ riêng)
 * nên khi trả một hóa đơn đã nằm trong khoản giữ riêng:
 *   available' = available − amount + releasedReservation
 * nghĩa là "Còn để chi" chỉ đổi đúng phần chênh lệch so với số dự kiến.
 */
export async function billPayPreview(db, userId, bill, amount, session) {
  const o = await overview(db, userId, { session });
  const reservedAmount = B(bill.amount);
  const pay = B(amount ?? bill.amount);
  if (pay <= 0n)
    fail(false, "INVALID_AMOUNT", "Số tiền thanh toán phải lớn hơn 0.", 422);

  const isReserved = o.bills.some((b) => b._id.equals(bill._id));
  const released = isReserved ? reservedAmount : 0n;

  const before = {
    total: o.total,
    protectedMoney: o.protectedMoney,
    unpaidBills: o.unpaidBills,
    available: o.available,
  };
  let after = null;
  if (o.available !== null) {
    const unpaidAfter = o.unpaidBills - released;
    after = {
      total: o.total - pay,
      protectedMoney: o.protectedMoney,
      unpaidBills: unpaidAfter < 0n ? 0n : unpaidAfter,
      available: o.available - pay + released,
    };
  }
  const excessOverReserved = pay > reservedAmount ? pay - reservedAmount : 0n;
  const warnings = [];
  if (!isReserved)
    warnings.push(
      "Hóa đơn này chưa nằm trong khoản dự phòng của kỳ hiện tại; thanh toán sẽ trừ trực tiếp vào tiền còn để chi.",
    );
  if (excessOverReserved > 0n)
    warnings.push(
      "Số tiền thực tế vượt phần đã giữ riêng; phần vượt sẽ trừ vào tiền chi tiêu tự do.",
    );
  if (after && after.available < 0n)
    warnings.push(
      "Sau khi thanh toán, tiền còn để chi sẽ âm. Cần xác nhận trước khi tiếp tục.",
    );

  return {
    billId: bill._id,
    amount: pay,
    reservedAmount,
    releasedReservation: released,
    excessOverReserved,
    before,
    after,
    requiresConfirmation: !!(after && after.available < 0n),
    warnings,
  };
}

export async function ownedBillTemplate(db, userId, id, session) {
  return owned(db, "bill_templates", userId, id, session);
}
