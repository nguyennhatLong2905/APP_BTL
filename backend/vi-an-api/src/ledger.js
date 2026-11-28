import { budgetAlerts } from "./signals.js";
import { withBudgetLimit, syncBudgetCounters } from "./budget-limit.js";
import { B, L, I, base, now, fail, owned, oid, hash } from "./common.js";

export async function validateEntry(db, userId, input, session) {
  const t = {
    ...Object.fromEntries(
      Object.entries(input).filter(([, v]) => v !== undefined),
    ),
    amount: L(input.amount),
    occurredAt: new Date(input.occurredAt),
    currency: "VND",
  };
  for (const field of [
    "walletId",
    "fromWalletId",
    "toWalletId",
    "categoryId",
    "billOccurrenceId",
    "purchaseIntentId",
  ])
    if (t[field]) t[field] = oid(t[field]);
  fail(
    t.occurredAt <= now(),
    "FUTURE_TRANSACTION",
    "Giao dịch thực tế không được ở tương lai.",
    422,
  );
  const transfer = t.type === "transfer";
  fail(
    transfer
      ? !!(t.fromWalletId && t.toWalletId && !t.walletId && !t.categoryId)
      : !!(t.walletId && !t.fromWalletId && !t.toWalletId),
    "INVALID_TRANSACTION",
    "Thiếu ví hoặc chọn sai loại giao dịch.",
    422,
  );
  if (transfer)
    fail(
      !t.fromWalletId.equals(t.toWalletId),
      "SAME_WALLET",
      "Ví nguồn và đích phải khác nhau.",
      422,
    );
  for (const walletId of transfer
    ? [t.fromWalletId, t.toWalletId]
    : [t.walletId]) {
    const wallet = await owned(db, "wallets", userId, walletId, session);
    fail(wallet.status === "active", "WALLET_ARCHIVED", "Ví đã được lưu trữ.");
    fail(
      t.occurredAt >= wallet.openingAt,
      "BEFORE_OPENING",
      "Ngày giao dịch trước ngày bắt đầu theo dõi ví.",
      422,
    );
  }
  if (["expense", "income"].includes(t.type)) {
    fail(t.categoryId, "CATEGORY_REQUIRED", "Cần chọn danh mục.", 422);
    const cat = await owned(db, "categories", userId, t.categoryId, session);
    fail(
      cat.status === "active" && cat.kind === t.type,
      "INVALID_CATEGORY",
      "Danh mục không phù hợp.",
      422,
    );
  }
  if (t.type === "adjustment")
    fail(
      !t.categoryId && ["increase", "decrease"].includes(t.adjustmentDirection),
      "INVALID_ADJUSTMENT",
      "Điều chỉnh phải có chiều tăng/giảm.",
      422,
    );
  if (t.type !== "adjustment")
    fail(
      !t.adjustmentDirection,
      "INVALID_TRANSACTION",
      "Chỉ adjustment có chiều điều chỉnh.",
      422,
    );
  if (t.billOccurrenceId || t.purchaseIntentId)
    fail(
      t.type === "expense",
      "INVALID_LINK",
      "Chỉ khoản chi được liên kết hóa đơn hoặc khoản mua.",
      422,
    );
  if (input.attachmentIds) {
    t.attachments = [];
    for (const attachmentId of input.attachmentIds) {
      const file = await owned(
        db,
        "attachments",
        userId,
        attachmentId,
        session,
      );
      t.attachments.push({
        storageKey: file._id.toHexString(),
        mimeType: file.mimeType,
      });
    }
    delete t.attachmentIds;
  }
  if (input.receiptLines !== undefined) {
    fail(
      t.type === "expense",
      "INVALID_RECEIPT",
      "Chỉ khoản chi có chi tiết hóa đơn.",
      422,
    );
    t.receiptLines = input.receiptLines.map(({ name, amount }) => ({
      name,
      amount: L(amount),
    }));
  }
  delete t.expectedVersion;
  delete t.trackReview;
  return t;
}
export function impacts(t, sign = 1n) {
  const n = B(t.amount) * sign;
  if (t.type === "transfer")
    return [
      [t.fromWalletId, -n],
      [t.toWalletId, n],
    ];
  return [
    [
      t.walletId,
      t.type === "income" || t.adjustmentDirection === "increase" ? n : -n,
    ],
  ];
}
export async function applyImpacts(db, userId, entries, session) {
  const changes = new Map();
  for (const [id, delta] of entries) {
    const key = id.toHexString();
    changes.set(key, (changes.get(key) || 0n) + delta);
  }
  for (const [id, delta] of changes) {
    const w = await owned(db, "wallets", userId, id, session);
    fail(
      w.status === "active",
      "WALLET_ARCHIVED",
      "Mở lại ví trước khi sửa lịch sử.",
    );
    const allocations = await db
      .collection("goal_allocations")
      .find({ userId, walletId: w._id }, { session })
      .toArray();
    const reserved = allocations.reduce((s, a) => s + B(a.amount), 0n),
      balance = B(w.balance) + delta;
    fail(balance >= 0n, "INSUFFICIENT_BALANCE", "Ví không đủ tiền.");
    fail(
      balance >= reserved,
      "ALLOCATED_FUNDS",
      "Giảm tiền phân bổ vào mục tiêu trước khi chi khoản tiền này.",
    );
    fail(
      balance <= 9223372036854775807n,
      "AMOUNT_OVERFLOW",
      "Số dư vượt giới hạn.",
    );
    await db
      .collection("wallets")
      .updateOne(
        { _id: w._id, userId },
        {
          $set: { balance: L(balance), updatedAt: now() },
          $inc: { version: I(1) },
        },
        { session },
      );
  }
}
async function link(db, userId, t, session) {
  if (t.billOccurrenceId) {
    const bill = await owned(
      db,
      "bill_occurrences",
      userId,
      t.billOccurrenceId,
      session,
    );
    fail(
      bill.status === "unpaid",
      "BILL_ALREADY_PAID",
      "Hóa đơn không ở trạng thái chưa trả.",
    );
    fail(
      bill.categoryId.equals(t.categoryId),
      "CATEGORY_MISMATCH",
      "Khoản chi và hóa đơn phải cùng danh mục.",
    );
    await db
      .collection("bill_occurrences")
      .updateOne(
        { _id: bill._id, userId },
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
        { userId, entityId: bill._id, status: "pending" },
        { $set: { status: "cancelled", updatedAt: now() } },
        { session },
      );
  }
  if (t.purchaseIntentId) {
    const p = await owned(
      db,
      "purchase_intents",
      userId,
      t.purchaseIntentId,
      session,
    );
    fail(
      ["draft", "waiting"].includes(p.status),
      "PURCHASE_ALREADY_HANDLED",
      "Khoản mua không còn chờ xác nhận.",
    );
    await db
      .collection("purchase_intents")
      .updateOne(
        { _id: p._id, userId },
        {
          $set: { status: "purchased", transactionId: t._id, updatedAt: now() },
        },
        { session },
      );
    await db
      .collection("notifications")
      .updateMany(
        { userId, entityId: p._id, status: "pending" },
        { $set: { status: "cancelled", updatedAt: now() } },
        { session },
      );
  }
}
async function unlink(db, userId, t, session) {
  if (t.billOccurrenceId)
    await db
      .collection("bill_occurrences")
      .updateOne(
        { _id: t.billOccurrenceId, userId, transactionId: t._id },
        {
          $set: { status: "unpaid", updatedAt: now() },
          $unset: { transactionId: "", paidAt: "" },
        },
        { session },
      );
  if (t.purchaseIntentId)
    await db
      .collection("purchase_intents")
      .updateOne(
        { _id: t.purchaseIntentId, userId, transactionId: t._id },
        {
          $set: { status: "waiting", updatedAt: now() },
          $unset: { transactionId: "" },
        },
        { session },
      );
}
/**
 * Nhật ký Đáng tiền được ghi nhận TỰ ĐỘNG.
 *
 * Mọi giao dịch chi tiêu `posted` đều có đúng một bản ghi `reflections` liên
 * kết bằng `transactionId` (unique index). Giao dịch thu nhập, chuyển ví nội bộ
 * và điều chỉnh số dư không bao giờ vào nhật ký.
 */
export const DEFAULT_REVIEW_DELAY_DAYS = 7;

export function reviewDelayDays(user) {
  const n = Number(user?.settings?.reviewDelayDays ?? DEFAULT_REVIEW_DELAY_DAYS);
  return Number.isFinite(n) && n >= 0 ? n : DEFAULT_REVIEW_DELAY_DAYS;
}

/** Hạn đánh giá = ngày chi thực tế + số ngày chờ (mặc định 7). */
export function reviewDueAt(transaction, delayDays) {
  return new Date(transaction.occurredAt.getTime() + delayDays * 86400000);
}

/**
 * Tạo hoặc cập nhật bản ghi nhật ký cho một giao dịch chi.
 *
 * - Không tạo trùng (khoá `transactionId`, upsert theo khoá đó).
 * - Giữ nguyên đánh giá người dùng đã lưu; chỉ đồng bộ lại số tiền/danh mục
 *   thông qua giao dịch mà bản ghi trỏ tới, và hạn đánh giá theo ngày chi mới.
 * - Nhắc đánh giá dùng `dedupeKey = review:<transactionId>` nên không nhân bản.
 */
export async function autoTrackReview(db, userId, t, session) {
  const user = await db
    .collection("users")
    .findOne({ _id: userId }, { session });
  const dueAt = reviewDueAt(t, reviewDelayDays(user));

  // Upsert theo khoá duy nhất (userId, transactionId): chạy song song hay lặp
  // lại đều chỉ có đúng một bản ghi. Không ghi đè status/rating đã có.
  const r = await db
    .collection("reflections")
    .findOneAndUpdate(
      { userId, transactionId: t._id },
      {
        $set: { dueAt, updatedAt: now() },
        $setOnInsert: {
          _id: base(userId)._id,
          userId,
          transactionId: t._id,
          createdAt: now(),
          status: "pending",
        },
      },
      { upsert: true, returnDocument: "after", session },
    );
  if (!r) return null;
  if (r.status === "pending")
    await notify(
      db,
      userId,
      "review_due",
      r._id,
      dueAt,
      "review:" + t._id,
      session,
    );
  return r;
}

/**
 * Gỡ bản ghi nhật ký khi giao dịch bị hủy hoặc không còn là khoản chi.
 *
 * - Bản ghi chưa có đánh giá (pending/skipped) bị xóa cùng lời nhắc.
 * - Bản ghi đã đánh giá được giữ lại để không mất dữ liệu người dùng; nó tự
 *   ẩn khỏi nhật ký vì mọi truy vấn chỉ lấy giao dịch `posted`. Khi giao dịch
 *   được khôi phục, bản ghi cũ được dùng lại, không sinh bản trùng.
 */
export async function removeReflection(db, userId, transactionId, session) {
  const r = await db
    .collection("reflections")
    .findOne({ userId, transactionId }, { session });
  if (!r) return null;
  await db
    .collection("notifications")
    .deleteMany({ userId, entityId: r._id, type: "review_due" }, { session });
  if (r.status !== "rated")
    await db
      .collection("reflections")
      .deleteOne({ _id: r._id, userId }, { session });
  return r;
}

/**
 * Đồng bộ nhật ký theo trạng thái hiện tại của giao dịch.
 * Dùng sau mỗi lần tạo/sửa/hủy/khôi phục giao dịch.
 */
export async function syncReflection(db, userId, t, session) {
  if (t.type === "expense" && t.status === "posted")
    return autoTrackReview(db, userId, t, session);
  await removeReflection(db, userId, t._id, session);
  return null;
}

/**
 * Bổ sung nhật ký cho các giao dịch chi đã tồn tại trước khi bật cơ chế tự động
 * (dữ liệu cũ, dữ liệu nhập CSV/khôi phục). Chạy lại nhiều lần vẫn an toàn vì
 * khoá duy nhất là `transactionId`.
 */
export async function backfillReflections(db, userId, session) {
  const user = await db
    .collection("users")
    .findOne({ _id: userId }, { session });
  const delay = reviewDelayDays(user);
  const existing = await db
    .collection("reflections")
    .find({ userId }, { session })
    .project({ transactionId: 1, dueAt: 1 })
    .toArray();
  const known = new Map(
    existing.map((r) => [r.transactionId.toHexString(), r]),
  );
  const rows = await db
    .collection("transactions")
    .find({ userId, status: "posted", type: "expense" }, { session })
    .project({ amount: 1, occurredAt: 1, categoryId: 1, note: 1, type: 1 })
    .toArray();
  let created = 0;
  for (const t of rows) {
    if (known.has(t._id.toHexString())) {
      const dueAt = reviewDueAt(t, delay);
      const prev = known.get(t._id.toHexString());
      if (prev.dueAt?.getTime?.() !== dueAt.getTime())
        await db
          .collection("reflections")
          .updateOne(
            { userId, transactionId: t._id },
            { $set: { dueAt, updatedAt: now() } },
            { session },
          );
      continue;
    }
    await autoTrackReview(db, userId, t, session);
    created++;
  }
  return { created, scanned: rows.length };
}

export async function createEntry(db, userId, input, key, session) {
  const t = {
    ...base(userId),
    ...(await validateEntry(db, userId, input, session)),
    status: "posted",
    idempotencyKey: key,
    version: I(1),
    source: input.source || "manual",
  };
  // Khóa chi tiêu cứng: kiểm tra hạn mức và ghi giao dịch trong cùng một khoá
  // của (kỳ, danh mục), nên nhiều request đồng thời không thể cùng vượt hạn mức.
  // Danh mục không có hạn mức / không có kỳ bao phủ thì ghi bình thường.
  const persist = async () => {
    await link(db, userId, t, session);
    await applyImpacts(db, userId, impacts(t), session);
    await db.collection("transactions").insertOne(t, { session });
    return t;
  };
  const created =
    t.type === "expense"
      ? await withBudgetLimit(
          db,
          userId,
          {
            categoryId: t.categoryId,
            amount: B(t.amount),
            occurredAt: t.occurredAt,
            session,
          },
          persist,
        )
      : await persist();
  if (t.type === "expense") {
    await budgetAlerts(db, userId, session);
    // Tự động vào Nhật ký Đáng tiền — không cần thao tác của người dùng.
    await autoTrackReview(db, userId, t, session);
  }
  return created;
}
export async function notify(
  db,
  userId,
  type,
  entityId,
  scheduledAt,
  dedupeKey,
  session,
) {
  await db
    .collection("notifications")
    .updateOne(
      { userId, dedupeKey },
      {
        $setOnInsert: {
          ...base(userId),
          type,
          entityId,
          scheduledAt,
          status: "pending",
          dedupeKey,
          attempts: I(0),
        },
      },
      { upsert: true, session },
    );
}
export async function changeEntry(db, userId, id, input, mode, session) {
  const old = await owned(db, "transactions", userId, id, session);
  fail(
    Number(old.version) === input.expectedVersion,
    "VERSION_CONFLICT",
    "Dữ liệu đã thay đổi; hãy tải lại.",
  );
  let t;
  if (mode === "edit") {
    fail(old.status === "posted", "VOIDED_TRANSACTION", "Giao dịch đã bị hủy.");
    // Keep business links unless explicitly voided; prevent silently detaching bills.
    const clean = {
      ...input,
      billOccurrenceId: old.billOccurrenceId?.toHexString(),
      purchaseIntentId: old.purchaseIntentId?.toHexString(),
    };
    if (input.attachmentIds === undefined) clean.attachments = old.attachments;
    if (input.merchant === undefined) clean.merchant = old.merchant;
    if (input.receiptLines === undefined && input.type === "expense")
      clean.receiptLines = old.receiptLines?.map(({ name, amount }) => ({
        name,
        amount: B(amount).toString(),
      }));
    t = {
      ...base(userId),
      ...(await validateEntry(db, userId, clean, session)),
      _id: old._id,
      createdAt: old.createdAt,
      status: "posted",
      source: old.source || "manual",
      idempotencyKey: old.idempotencyKey,
      version: I(Number(old.version) + 1),
    };
  } else if (mode === "void") {
    fail(old.status === "posted", "ALREADY_VOIDED", "Giao dịch đã hủy.");
    t = {
      ...old,
      status: "voided",
      voidedAt: now(),
      updatedAt: now(),
      version: I(Number(old.version) + 1),
    };
  } else {
    fail(old.status === "voided", "NOT_VOIDED", "Giao dịch đang có hiệu lực.");
    t = {
      ...old,
      status: "posted",
      updatedAt: now(),
      version: I(Number(old.version) + 1),
    };
    delete t.voidedAt;
    // Revalidate referenced resources before restoring.
    await validateEntry(
      db,
      userId,
      {
        ...t,
        amount: B(t.amount).toString(),
        occurredAt: t.occurredAt.toISOString(),
        ...Object.fromEntries(
          [
            "walletId",
            "categoryId",
            "fromWalletId",
            "toWalletId",
            "billOccurrenceId",
            "purchaseIntentId",
          ]
            .filter((k) => t[k])
            .map((k) => [k, t[k].toHexString()]),
        ),
      },
      session,
    );
  }

  // Ghi thay đổi. Sửa/khôi phục một khoản chi phải qua kiểm tra hạn mức với số
  // liệu mới, bỏ qua tác động cũ của chính giao dịch (tránh tính trùng).
  const commit = async () => {
    if (mode === "edit") {
      await unlink(db, userId, old, session);
      await link(db, userId, t, session);
      await applyImpacts(
        db,
        userId,
        [...impacts(old, -1n), ...impacts(t)],
        session,
      );
    } else if (mode === "void") {
      await unlink(db, userId, old, session);
      await applyImpacts(db, userId, impacts(old, -1n), session);
    } else {
      await link(db, userId, t, session);
      await applyImpacts(db, userId, impacts(t), session);
    }
    await db
      .collection("transactions")
      .replaceOne({ _id: old._id, userId }, t, { session });
    return t;
  };
  if (mode !== "void" && t.type === "expense")
    await withBudgetLimit(
      db,
      userId,
      {
        categoryId: t.categoryId,
        amount: B(t.amount),
        occurredAt: t.occurredAt,
        excludeTransactionId: old._id,
        session,
      },
      commit,
    );
  else await commit();
  await db
    .collection("audit_events")
    .insertOne(
      {
        ...base(userId),
        entityId: old._id,
        action: mode,
        before: old,
        after: t,
      },
      { session },
    );
  if (old.type === "expense" || t.type === "expense")
    await budgetAlerts(db, userId, session);
  // Đồng bộ bộ đếm quan sát được sau khi hủy/sửa: danh mục được mở khóa ngay
  // vì hạn mức được tính lại từ giao dịch thật đang có hiệu lực.
  await syncBudgetCounters(db, userId, [old, t], session);
  // Đồng bộ nhật ký: giữ đúng một bản ghi khoá theo transactionId.
  // - Sửa số tiền/danh mục/ngày: bản ghi giữ nguyên _id và đánh giá cũ, dữ liệu
  //   hiển thị lấy từ giao dịch nên tự khớp; hạn đánh giá tính lại theo ngày chi.
  // - Hủy giao dịch hoặc đổi sang loại không phải chi: gỡ khỏi nhật ký.
  // - Khôi phục giao dịch chi: dùng lại bản ghi cũ nếu còn, nếu không thì tạo.
  await syncReflection(db, userId, t, session);
  await db
    .collection("insights")
    .updateMany(
      { userId, evidenceTransactionIds: old._id },
      { $set: { status: "dismissed", updatedAt: now() } },
      { session },
    );
  return t;
}
