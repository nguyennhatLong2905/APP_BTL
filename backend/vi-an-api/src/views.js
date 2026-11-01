import {
  B,
  L,
  oid,
  now,
  fail,
  daysBetween,
  fraction,
  localDay,
  escapeRegex,
  readSnapshot,
} from "./common.js";
export async function overview(
  db,
  userId,
  { at = new Date(), payday, session } = {},
) {
  if (!session)
    return readSnapshot(db, (s) =>
      overview(db, userId, { at, payday, session: s }),
    );
  const user = await db
    .collection("users")
    .findOne({ _id: userId }, { session });
  fail(user, "NOT_FOUND", "Không tìm thấy người dùng.", 404);
  const wallets = await db
    .collection("wallets")
    .find({ userId, status: "active" }, { session })
    .toArray();
  const goals = await db
    .collection("goals")
    .find({ userId, status: "active", protect: true }, { session })
    .toArray();
  const allocations = await db
    .collection("goal_allocations")
    .find({ userId, goalId: { $in: goals.map((g) => g._id) } }, { session })
    .toArray();
  const nextPayday = payday || user.nextPayday;
  const missing = [];
  if (!wallets.length) missing.push("wallets");
  if (!nextPayday) missing.push("nextPayday");
  const days = nextPayday ? daysBetween(at, nextPayday, user.timezone) : null;
  if (days !== null && days <= 0) missing.push("nextPaydayInFuture");
  const bills = nextPayday
    ? await db
        .collection("bill_occurrences")
        .find(
          { userId, status: "unpaid", dueAt: { $lt: new Date(nextPayday) } },
          { session },
        )
        .sort({ dueAt: 1 })
        .toArray()
    : [];
  const total = wallets.reduce((s, w) => s + B(w.balance), 0n);
  const protectedMoney = allocations.reduce((s, a) => s + B(a.amount), 0n);
  const unpaid = bills.reduce((s, b) => s + B(b.amount), 0n);
  const available = nextPayday ? total - protectedMoney - unpaid : null;
  return {
    asOf: at,
    nextPayday: nextPayday || null,
    daysRemaining: days,
    missingData: missing,
    currency: "VND",
    total,
    unpaidBills: unpaid,
    protectedMoney,
    available,
    dailyReference: days > 0 ? available / BigInt(days) : null,
    wallets,
    bills,
  };
}
export async function budgetView(db, userId, plan, session) {
  const rows = await db
    .collection("transactions")
    .aggregate(
      [
        {
          $match: {
            userId,
            status: "posted",
            type: "expense",
            occurredAt: { $gte: plan.startAt, $lt: plan.endAt },
          },
        },
        { $group: { _id: "$categoryId", amount: { $sum: "$amount" } } },
      ],
      { session },
    )
    .toArray();
  const amounts = new Map(rows.map((r) => [r._id.toHexString(), B(r.amount)]));
  const limits = plan.limits.map((l) => {
    const spent = amounts.get(l.categoryId.toHexString()) || 0n,
      limit = B(l.limit);
    return {
      ...l,
      spent,
      remaining: limit - spent,
      percent: fraction(spent, limit),
      warning:
        spent * 100n >= limit * BigInt(Number(plan.warningPercent || 80)),
    };
  });
  return {
    ...plan,
    limits,
    totalLimit: limits.reduce((s, l) => s + B(l.limit), 0n),
    totalSpent: limits.reduce((s, l) => s + l.spent, 0n),
  };
}
export async function goalView(db, userId, goal, session) {
  const allocations = await db
    .collection("goal_allocations")
    .find({ userId, goalId: goal._id }, { session })
    .toArray();
  const allocated = allocations.reduce((s, a) => s + B(a.amount), 0n);
  return {
    ...goal,
    allocations,
    allocated,
    percent: fraction(allocated, B(goal.targetAmount)),
  };
}
export async function simulate(
  db,
  userId,
  { price, billOccurrenceId, delayDays = 0, at = new Date() },
  session,
) {
  if (!session)
    return readSnapshot(db, (s) =>
      simulate(db, userId, { price, billOccurrenceId, delayDays, at }, s),
    );
  const user = await db
    .collection("users")
    .findOne({ _id: userId }, { session });
  const shifted = user.nextPayday
    ? new Date(user.nextPayday.getTime() + delayDays * 86400000)
    : undefined;
  const o = await overview(db, userId, { at, payday: shifted, session });
  let released = 0n;
  if (billOccurrenceId) {
    const bill = o.bills.find((b) => b._id.toHexString() === billOccurrenceId);
    fail(
      bill,
      "NOT_RESERVED_BILL",
      "Hóa đơn chưa được dự phòng trong kỳ này.",
      422,
    );
    released = B(bill.amount);
  }
  const after = o.available === null ? null : o.available - B(price) + released;
  return {
    isSimulation: true,
    before: o,
    price: B(price),
    releasedReservation: released,
    availableAfter: after,
    dailyAfter:
      after !== null && o.daysRemaining > 0
        ? after / BigInt(o.daysRemaining)
        : null,
    assumptions: [
      "Chưa cộng thu nhập chưa nhận.",
      "Hóa đơn và quỹ bảo vệ đã được giữ riêng.",
    ],
  };
}
export async function report(db, userId, start, end, session) {
  const aggregate = async (a, b) =>
    db
      .collection("transactions")
      .aggregate(
        [
          {
            $match: {
              userId,
              status: "posted",
              type: { $in: ["expense", "income"] },
              occurredAt: { $gte: a, $lt: b },
            },
          },
          {
            $group: {
              _id: { type: "$type", categoryId: "$categoryId" },
              amount: { $sum: "$amount" },
              count: { $sum: 1 },
            },
          },
        ],
        { session },
      )
      .toArray();
  const current = await aggregate(start, end),
    previousStart = new Date(start.getTime() - (end - start)),
    previous = await aggregate(previousStart, start);
  const total = (rows, type) =>
    rows
      .filter((r) => r._id.type === type)
      .reduce((s, r) => s + B(r.amount), 0n);
  const expense = total(current, "expense"),
    previousExpense = total(previous, "expense");
  const income = total(current, "income");
  return {
    startAt: start,
    endAt: end,
    previousStartAt: previousStart,
    income,
    expense,
    net: income - expense,
    previousExpense,
    expenseChangePercent: fraction(expense - previousExpense, previousExpense),
    byCategory: current.map((r) => ({
      type: r._id.type,
      categoryId: r._id.categoryId,
      amount: r.amount,
      count: r.count,
    })),
  };
}
export function entryMatch(userId, q, includeCursor = true) {
  const filter = { userId, status: q.status || "posted" };
  if (q.type) filter.type = q.type;
  if (q.categoryId) filter.categoryId = oid(q.categoryId);
  if (q.walletId)
    filter.$or = ["walletId", "fromWalletId", "toWalletId"].map((k) => ({
      [k]: oid(q.walletId),
    }));
  if (q.startAt || q.endAt)
    filter.occurredAt = {
      ...(q.startAt ? { $gte: new Date(q.startAt) } : {}),
      ...(q.endAt ? { $lt: new Date(q.endAt) } : {}),
    };
  if (q.search) filter.note = { $regex: escapeRegex(q.search), $options: "i" };
  if (q.amount) filter.amount = L(q.amount);
  if (q.cursor && includeCursor) {
    let c;
    try {
      c = JSON.parse(Buffer.from(q.cursor, "base64url").toString());
      fail(
        /^[a-f\d]{24}$/i.test(c.id) && !Number.isNaN(Date.parse(c.at)),
        "BAD_CURSOR",
        "Cursor không hợp lệ.",
        422,
      );
    } catch {
      fail(false, "BAD_CURSOR", "Cursor không hợp lệ.", 422);
    }
    filter.$and = [
      {
        $or: [
          { occurredAt: { $lt: new Date(c.at) } },
          { occurredAt: new Date(c.at), _id: { $lt: oid(c.id) } },
        ],
      },
    ];
  }
  return filter;
}
export async function listEntries(db, userId, q) {
  const limit = q.limit || 30,
    items = await db
      .collection("transactions")
      .find(entryMatch(userId, q))
      .sort({ occurredAt: -1, _id: -1 })
      .limit(limit + 1)
      .toArray();
  const more = items.length > limit;
  if (more) items.pop();
  const last = items.at(-1);
  return {
    items,
    nextCursor: more
      ? Buffer.from(
          JSON.stringify({
            id: last._id.toHexString(),
            at: last.occurredAt.toISOString(),
          }),
        ).toString("base64url")
      : null,
  };
}
