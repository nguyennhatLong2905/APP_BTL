import { B, L, I, fail, fraction, base, now, ApiError } from "./common.js";
import { budgetView } from "./views.js";

/**
 * Khóa chi tiêu cứng theo ngân sách (Hard Spending Limit).
 *
 * Nguyên tắc bất biến:
 * - Ngân sách chỉ là kế hoạch kiểm soát chi, KHÔNG phải tiền bị khóa. Module
 *   này không đụng vào số dư ví, quỹ bảo vệ, hóa đơn chưa trả và không trừ hạn
 *   mức khỏi "Còn để chi". Số dư/Còn để chi chỉ đổi khi giao dịch chi thực sự
 *   được ghi — do luồng giao dịch hiện có, không phải module này.
 * - Chỉ danh mục có hạn mức trong kỳ ngân sách đang bao phủ ngày giao dịch bị
 *   giới hạn. Danh mục khác, thu nhập, chuyển ví và điều chỉnh số dư đi qua
 *   bình thường.
 * - "Đã chi" luôn tính từ `budgetView` — một công thức duy nhất (tổng giao dịch
 *   chi `posted` trong kỳ). Không có công thức song song.
 * - An toàn khi đồng thời: mỗi (kỳ, danh mục) có một khoá ngắn hạn trong
 *   `budget_spend`. Kiểm tra hạn mức và ghi giao dịch diễn ra trong cùng khoá,
 *   nên nhiều request song song không thể cùng vượt hạn mức.
 * - Không bao giờ tự giảm số tiền người dùng nhập.
 */

const LOCK_MS = 5000;
const LOCK_ATTEMPTS = 40;

/**
 * Bản ghi khởi tạo cho khoá.
 *
 * `withUpdatedAt: false` dùng khi cùng lệnh ghi đã có `$set: {updatedAt}`.
 * `withUsed: false` dùng khi cùng lệnh ghi đã có `$set: {used}`.
 * MongoDB không cho hai toán tử cùng đặt một đường dẫn.
 */
function insertDoc(userId, { withUpdatedAt = true, withUsed = true } = {}) {
  const b = base(userId);
  return {
    _id: b._id,
    userId,
    createdAt: b.createdAt,
    ...(withUpdatedAt ? { updatedAt: b.updatedAt } : {}),
    ...(withUsed ? { used: L(0) } : {}),
    version: I(0),
  };
}

/** Trạng thái hiển thị của một dòng hạn mức. */
export function budgetLineStatus({ limit, spent }) {
  const l = B(limit),
    s = B(spent);
  if (s > l) return "over";
  if (s === l) return "exhausted";
  const percent = fraction(s, l);
  if (percent !== null && percent >= 80) return "near";
  return "normal";
}

/** Kỳ ngân sách bao phủ `occurredAt` (chỉ kỳ đang mở). */
export async function planCovering(db, userId, occurredAt, session) {
  return db.collection("budget_plans").findOne(
    {
      userId,
      status: "active",
      startAt: { $lte: occurredAt },
      endAt: { $gt: occurredAt },
    },
    { session },
  );
}

/** Dòng hạn mức của danh mục trong kỳ (kèm số đã chi theo budgetView). */
export async function planLineFor(db, userId, plan, categoryId, session) {
  const view = await budgetView(db, userId, plan, session);
  return view.limits.find((l) => l.categoryId.equals(categoryId)) || null;
}

export function limitFailure(line, name, amount) {
  const limit = B(line.limit);
  const spent = B(line.spent);
  const remaining = limit - spent > 0n ? limit - spent : 0n;
  const overBy = B(amount) - remaining > 0n ? B(amount) - remaining : 0n;
  const head =
    remaining === 0n
      ? `Danh mục "${name}" đã hết hạn mức ngân sách trong kỳ này.`
      : `Khoản chi vượt hạn mức còn lại ${remaining} ₫ của danh mục "${name}" (vượt ${overBy} ₫).`;
  return {
    code: "BUDGET_LIMIT_EXCEEDED",
    message:
      `${head} Tăng hạn mức trong Kế hoạch hoặc chọn danh mục khác. ` +
      `Ví An không tự giảm số tiền bạn nhập.`,
    details: {
      categoryId: line.categoryId,
      categoryName: name,
      limit: limit.toString(),
      spent: spent.toString(),
      remaining: remaining.toString(),
      requested: B(amount).toString(),
      overBy: overBy.toString(),
    },
  };
}

async function categoryName(db, userId, categoryId, session) {
  const c = await db
    .collection("categories")
    .findOne({ _id: categoryId, userId }, { session });
  return c?.name || "danh mục này";
}

/**
 * Xin khoá cho (kỳ, danh mục). Trả token nếu lấy được, `null` nếu đang bận.
 * Khoá tự hết hạn sau LOCK_MS để không treo vĩnh viễn nếu tiến trình chết.
 */
async function acquire(db, userId, planId, categoryId, token, session) {
  const key = { userId, planId, categoryId };
  await db.collection("budget_spend").updateOne(
    key,
    { $setOnInsert: insertDoc(userId) },
    { upsert: true, session },
  );
  const doc = await db.collection("budget_spend").findOneAndUpdate(
    {
      ...key,
      $or: [{ lockToken: { $exists: false } }, { lockToken: null }],
    },
    { $set: { lockToken: token, lockedUntil: new Date(Date.now() + LOCK_MS) } },
    { returnDocument: "after", session },
  );
  if (doc) return token;
  // Lấy lại khoá đã hết hạn.
  const stale = await db.collection("budget_spend").findOneAndUpdate(
    { ...key, lockedUntil: { $lt: new Date() } },
    { $set: { lockToken: token, lockedUntil: new Date(Date.now() + LOCK_MS) } },
    { returnDocument: "after", session },
  );
  return stale ? token : null;
}
async function release(db, userId, planId, categoryId, token, session) {
  await db.collection("budget_spend").updateOne(
    { userId, planId, categoryId, lockToken: token },
    { $unset: { lockToken: "", lockedUntil: "" } },
    { session },
  );
}

/**
 * Kiểm tra hạn mức rồi chạy `write()` — cả hai trong cùng khoá của danh mục.
 *
 * Trả kết quả của `write()`. Ném 422 `BUDGET_LIMIT_EXCEEDED` khi vượt hạn mức,
 * `write()` KHÔNG được gọi (nên giao dịch không được ghi, số tiền không bị sửa).
 *
 * - Danh mục không có hạn mức / không có kỳ bao phủ → chạy `write()` trực tiếp,
 *   không chặn.
 * - `excludeTransactionId`: bỏ tác động cũ của chính giao dịch đang sửa.
 */
export async function withBudgetLimit(
  db,
  userId,
  { categoryId, amount, occurredAt, excludeTransactionId, session },
  write,
) {
  if (!categoryId) return write();
  const plan = await planCovering(db, userId, occurredAt, session);
  if (!plan) return write();
  const initial = await planLineFor(db, userId, plan, categoryId, session);
  if (!initial) return write();

  const token = `${process.pid}-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  let held = null;
  for (let i = 0; i < LOCK_ATTEMPTS && !held; i++) {
    held = await acquire(db, userId, plan._id, categoryId, token, session);
    if (!held) await new Promise((r) => setTimeout(r, 5 + i * 2));
  }
  fail(
    held,
    "BUDGET_BUSY",
    "Đang có giao dịch khác cập nhật ngân sách này, vui lòng thử lại.",
    409,
  );

  try {
    // Đọc lại số đã chi sau khi đã giữ khoá để chắc chắn thấy dữ liệu mới nhất.
    const line = await planLineFor(db, userId, plan, categoryId, session);
    if (!line) return await write();

    let spent = B(line.spent);
    if (excludeTransactionId) {
      const old = await db
        .collection("transactions")
        .findOne({ _id: excludeTransactionId, userId }, { session });
      if (
        old &&
        old.status === "posted" &&
        old.type === "expense" &&
        old.categoryId?.equals(categoryId) &&
        old.occurredAt >= plan.startAt &&
        old.occurredAt < plan.endAt
      )
        spent -= B(old.amount);
    }
    const limit = B(line.limit);
    if (B(amount) > limit - spent) {
      const name = await categoryName(db, userId, categoryId, session);
      const err = limitFailure({ ...line, spent }, name, amount);
      throw new ApiError(422, err.code, err.message, err.details);
    }

    const result = await write();
    // Ghi xong: cập nhật số đã chi quan sát được (chỉ để tra cứu/giám sát).
    const after = await planLineFor(db, userId, plan, categoryId, session);
    if (after)
      await db.collection("budget_spend").updateOne(
        { userId, planId: plan._id, categoryId },
        { $set: { used: L(B(after.spent)), updatedAt: now() }, $inc: { version: I(1) } },
        { session },
      );
    return result;
  } finally {
    await release(db, userId, plan._id, categoryId, token, session).catch(
      () => {},
    );
  }
}

/**
 * Đồng bộ số đã chi cho các kỳ/danh mục bị ảnh hưởng bởi một cặp giao dịch
 * (trước và sau khi sửa/hủy/khôi phục). Nhờ vậy hủy giao dịch mở khóa ngay.
 */
export async function syncBudgetCounters(db, userId, transactions, session) {
  const seen = new Set();
  for (const tx of transactions) {
    if (!tx || tx.type !== "expense" || !tx.categoryId) continue;
    const at = tx.occurredAt;
    const plan = await db
      .collection("budget_plans")
      .findOne(
        { userId, startAt: { $lte: at }, endAt: { $gt: at } },
        { session },
      );
    if (!plan) continue;
    const key = `${plan._id}:${tx.categoryId}`;
    if (seen.has(key)) continue;
    seen.add(key);
    const line = await planLineFor(db, userId, plan, tx.categoryId, session);
    if (!line) continue;
    await db.collection("budget_spend").updateOne(
      { userId, planId: plan._id, categoryId: tx.categoryId },
      {
        $set: { used: L(B(line.spent)), updatedAt: now() },
        $setOnInsert: insertDoc(userId, { withUpdatedAt: false, withUsed: false }),
      },
      { upsert: true, session },
    );
  }
}

/** Đồng bộ lại số đã chi quan sát được cho cả kỳ (sau khi đổi hạn mức). */
export async function reconcilePlanSpend(db, userId, plan, session) {
  for (const limit of plan.limits) {
    const line = await planLineFor(db, userId, plan, limit.categoryId, session);
    if (!line) continue;
    await db.collection("budget_spend").updateOne(
      { userId, planId: plan._id, categoryId: limit.categoryId },
      {
        $set: { used: L(B(line.spent)), updatedAt: now() },
        $setOnInsert: insertDoc(userId, { withUpdatedAt: false, withUsed: false }),
      },
      { upsert: true, session },
    );
  }
}
