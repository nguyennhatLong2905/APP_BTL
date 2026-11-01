import { budgetAlerts } from "./signals.js";
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
export async function createEntry(db, userId, input, key, session) {
  const t = {
    ...base(userId),
    ...(await validateEntry(db, userId, input, session)),
    status: "posted",
    idempotencyKey: key,
    version: I(1),
    source: input.source || "manual",
  };
  await link(db, userId, t, session);
  await applyImpacts(db, userId, impacts(t), session);
  await db.collection("transactions").insertOne(t, { session });
  if (t.type === "expense") await budgetAlerts(db, userId, session);
  if (input.trackReview && t.type === "expense")
    await trackReview(db, userId, t._id, session);
  return t;
}
export async function trackReview(db, userId, transactionId, session) {
  const t = await owned(db, "transactions", userId, transactionId, session);
  fail(
    t.type === "expense" && t.status === "posted",
    "INVALID_REFLECTION",
    "Chỉ đánh giá khoản chi đang có hiệu lực.",
  );
  const user = await db
    .collection("users")
    .findOne({ _id: userId }, { session });
  const delay = user.settings?.reviewDelayDays ?? 7;
  const dueAt = new Date(t.occurredAt.getTime() + Number(delay) * 86400000);
  const existing = await db
    .collection("reflections")
    .findOne({ userId, transactionId: t._id }, { session });
  if (existing) return existing;
  const r = { ...base(userId), transactionId: t._id, dueAt, status: "pending" };
  await db.collection("reflections").insertOne(r, { session });
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
    await unlink(db, userId, old, session);
    await link(db, userId, t, session);
    await applyImpacts(
      db,
      userId,
      [...impacts(old, -1n), ...impacts(t)],
      session,
    );
  } else if (mode === "void") {
    fail(old.status === "posted", "ALREADY_VOIDED", "Giao dịch đã hủy.");
    t = {
      ...old,
      status: "voided",
      voidedAt: now(),
      updatedAt: now(),
      version: I(Number(old.version) + 1),
    };
    await unlink(db, userId, old, session);
    await applyImpacts(db, userId, impacts(old, -1n), session);
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
    await link(db, userId, t, session);
    await applyImpacts(db, userId, impacts(t), session);
  }
  await db
    .collection("transactions")
    .replaceOne({ _id: old._id, userId }, t, { session });
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
  const r = await db
    .collection("reflections")
    .findOne({ userId, transactionId: old._id }, { session });
  if (input.trackReview && t.type === "expense" && mode !== "void")
    await trackReview(db, userId, t._id, session);
  if (r) {
    if (mode === "void" || t.type !== "expense")
      await db
        .collection("notifications")
        .updateMany(
          { userId, entityId: r._id, status: "pending" },
          { $set: { status: "cancelled", updatedAt: now() } },
          { session },
        );
    else {
      const u = await db
        .collection("users")
        .findOne({ _id: userId }, { session });
      const dueAt = new Date(
        t.occurredAt.getTime() +
          Number(u.settings?.reviewDelayDays ?? 7) * 86400000,
      );
      await db
        .collection("reflections")
        .updateOne(
          { _id: r._id, userId },
          { $set: { dueAt, updatedAt: now() } },
          { session },
        );
      if (r.status === "pending")
        await db
          .collection("notifications")
          .updateMany(
            {
              userId,
              entityId: r._id,
              status: { $in: ["pending", "cancelled"] },
            },
            {
              $set: { status: "pending", scheduledAt: dueAt, updatedAt: now() },
            },
            { session },
          );
    }
  }
  await db
    .collection("insights")
    .updateMany(
      { userId, evidenceTransactionIds: old._id },
      { $set: { status: "dismissed", updatedAt: now() } },
      { session },
    );
  return t;
}
