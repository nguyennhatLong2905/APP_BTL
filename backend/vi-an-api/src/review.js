import { DateTime } from "luxon";
import { B, L, oid, fail, fraction, daysBetween } from "./common.js";
import { report, budgetView } from "./views.js";

/**
 * Phân tích cho màn "Nhìn lại".
 *
 * Toàn bộ số liệu đều suy ra từ `transactions` (status=posted) và `reflections`
 * đã được đánh giá. Không có giá trị hardcode: khi thiếu dữ liệu, các trường
 * nhận giá trị null/[] và cờ `hasEnoughData=false` để UI hiển thị trạng thái
 * "chưa đủ thông tin" thay vì bịa nhận xét.
 */

export const REVIEW_MIN_SAMPLES = 3; // tối thiểu để nêu nhận xét cá nhân
export const REVIEW_STRONG_SIGNAL = 5; // tối thiểu theo danh mục để kết luận mạnh

const tz = (user) => user?.timezone || "Asia/Ho_Chi_Minh";

/** Tuần ISO (thứ 2 → chủ nhật) chứa `at`, theo múi giờ người dùng. */
export function weekBounds(at = new Date(), zone = "Asia/Ho_Chi_Minh") {
  const d = DateTime.fromJSDate(new Date(at), { zone }).startOf("day");
  const monday = d.minus({ days: d.weekday - 1 });
  const start = monday.startOf("day");
  const end = start.plus({ days: 7 });
  return { start: start.toJSDate(), end: end.toJSDate(), startAt: start, endAt: end };
}

/** Cửa sổ tuần từ query startAt/endAt, mặc định tuần hiện tại. */
export function reviewWindow({ startAt, endAt }, zone) {
  if (startAt && endAt) {
    const a = DateTime.fromISO(String(startAt), { zone });
    const b = DateTime.fromISO(String(endAt), { zone });
    fail(a.isValid && b.isValid && a < b, "INVALID_PERIOD",
      "Ngày kết thúc phải sau ngày bắt đầu.", 422);
    return { start: a.toJSDate(), end: b.toJSDate(), startAt: a, endAt: b };
  }
  return weekBounds(startAt || new Date(), zone);
}

const iso = (d) => DateTime.fromJSDate(d).toUTC().toISO();

/** Bảng danh mục để gắn tên vào byCategory. */
export async function categoryMap(db, userId) {
  const rows = await db.collection("categories").find({ userId }).toArray();
  return new Map(rows.map((c) => [c._id.toHexString(), c]));
}

/** Tổng hợp tuần: thu, chi, theo danh mục (có tên), so với tuần trước. */
export async function weekStats(db, userId, wins, zone) {
  const r = await report(db, userId, wins.start, wins.end);
  const cats = await categoryMap(db, userId);
  const expense = B(r.expense);
  const prevExpense = B(r.previousExpense);

  const byCategory = r.byCategory
    .filter((x) => x.type === "expense")
    .map((x) => {
      const c = x.categoryId ? cats.get(x.categoryId.toHexString()) : null;
      const amount = B(x.amount);
      return {
        categoryId: x.categoryId,
        name: c?.name || "Khác",
        kind: c?.kind || "expense",
        amount,
        count: x.count,
        percent: fraction(amount, expense),
      };
    })
    .sort((a, b) => (b.amount > a.amount ? 1 : b.amount < a.amount ? -1 : 0));

  const top = byCategory[0] || null;
  const prevByCategory = new Map();
  // Tuần trước: dùng lại report theo cửa sổ trước để so từng danh mục.
  const prevRows = await db
    .collection("transactions")
    .aggregate(
      [
        {
          $match: {
            userId,
            status: "posted",
            type: "expense",
            occurredAt: { $gte: r.previousStartAt, $lt: r.startAt },
          },
        },
        { $group: { _id: "$categoryId", amount: { $sum: "$amount" }, count: { $sum: 1 } } },
      ],
    )
    .toArray();
  for (const row of prevRows) if (row._id) prevByCategory.set(row._id.toHexString(), row);

  const categories = byCategory.map((c) => {
    const key = c.categoryId ? c.categoryId.toHexString() : "";
    const prev = prevByCategory.get(key);
    const prevAmount = prev ? B(prev.amount) : 0n;
    return {
      ...c,
      previousAmount: prevAmount,
      changePercent: fraction(c.amount - prevAmount, prevAmount),
      transactionCount: c.count,
      topTransactionCount: 0,
    };
  });

  const trend =
    prevExpense === 0n && expense === 0n
      ? "flat"
      : prevExpense === 0n
        ? "up"
        : expense > prevExpense
          ? "up"
          : expense < prevExpense
            ? "down"
            : "flat";

  return {
    startAt: wins.start,
    endAt: wins.end,
    previousStartAt: r.previousStartAt,
    income: B(r.income),
    expense,
    net: B(r.net),
    previousExpense: prevExpense,
    expenseChangePercent: fraction(expense - prevExpense, prevExpense),
    trend,
    topCategory: top,
    categories,
    hasData: r.byCategory.length > 0,
    dayCount: daysBetween(wins.start, wins.end, zone),
  };
}

/**
 * Nhận xét ngắn dựa trên số liệu thật.
 * Trả về mảng rỗng khi không đủ dữ liệu — UI hiển thị trạng thái trống.
 */
export function weekNarrative(stats) {
  const notes = [];
  if (!stats.hasData || stats.expense === 0n) return notes;

  if (stats.trend === "down" && stats.expenseChangePercent !== null) {
    notes.push(
      `Chi tiêu tuần này giảm ${Math.abs(stats.expenseChangePercent)}% so với tuần trước.`,
    );
  } else if (stats.trend === "up" && stats.expenseChangePercent !== null) {
    notes.push(
      `Chi tiêu tuần này tăng ${Math.abs(stats.expenseChangePercent)}% so với tuần trước.`,
    );
  } else {
    notes.push("Chi tiêu tuần này gần như không đổi so với tuần trước.");
  }

  if (stats.topCategory && stats.topCategory.percent !== null) {
    notes.push(
      `${stats.topCategory.name} chiếm ${stats.topCategory.percent}% tổng chi (${stats.topCategory.count} giao dịch).`,
    );
  }
  return notes;
}

/**
 * Trạng thái nhật ký suy ra từ dữ liệu thật.
 *
 * - `tracking`: giao dịch chi mới, chưa đủ số ngày chờ (mặc định 7).
 * - `awaiting_review`: đã đủ 7 ngày và chưa đánh giá → cần người dùng xử lý.
 * - `rated`: người dùng đã chọn một mức đánh giá.
 * - `skipped`: người dùng chủ động bỏ qua.
 *
 * Không có trạng thái nào do hệ thống tự gán thay người dùng.
 */
export function journalState(reflection, at = new Date()) {
  if (reflection.status === "rated") return "rated";
  if (reflection.status === "skipped") return "skipped";
  const due = reflection.dueAt ? new Date(reflection.dueAt) : null;
  return due && due <= at ? "awaiting_review" : "tracking";
}

/** Số ngày còn lại tới hạn đánh giá (0 khi đã tới hạn). */
export function daysUntilReview(dueAt, at = new Date()) {
  if (!dueAt) return 0;
  const diff = new Date(dueAt).getTime() - at.getTime();
  if (diff <= 0) return 0;
  return Math.ceil(diff / 86400000);
}

/**
 * Một mục nhật ký hoàn chỉnh cho UI, dữ liệu lấy trực tiếp từ giao dịch thật
 * (id, tên, số tiền, danh mục, ngày chi, ghi chú) để không bao giờ lệch với
 * giao dịch gốc khi giao dịch bị sửa.
 */
export function journalItem(reflection, transaction, cats, at = new Date()) {
  const state = journalState(reflection, at);
  const category = transaction.categoryId
    ? cats.get(transaction.categoryId.toHexString()) || null
    : null;
  return {
    // Với dữ liệu cũ chưa kịp bổ sung bản ghi, dùng id giao dịch làm id mục
    // nhật ký; API đánh giá chấp nhận cả reflection id lẫn transaction id.
    _id: reflection._id || transaction._id,
    hasReflectionRecord: !!reflection._id,
    transactionId: reflection.transactionId || transaction._id,
    status: reflection.status,
    state,
    rating: reflection.rating || null,
    note: reflection.note || null,
    ratedAt: reflection.ratedAt || null,
    dueAt: reflection.dueAt || null,
    daysRemaining: state === "tracking" ? daysUntilReview(reflection.dueAt, at) : 0,
    isDue: state !== "tracking",
    transaction: {
      _id: transaction._id,
      amount: transaction.amount,
      occurredAt: transaction.occurredAt,
      note: transaction.note || null,
      type: transaction.type,
      categoryId: transaction.categoryId || null,
      categoryName: category?.name || null,
    },
    categoryName: category?.name || null,
  };
}

/** Tóm tắt nhật ký để UI hiển thị đếm và empty state chính xác. */
export function journalSummary(items) {
  const count = (s) => items.filter((x) => x.state === s).length;
  return {
    total: items.length,
    tracking: count("tracking"),
    awaitingReview: count("awaiting_review"),
    rated: count("rated"),
    skipped: count("skipped"),
    reviewed: count("rated") + count("skipped"),
  };
}

/**
 * Toàn bộ nhật ký của người dùng.
 *
 * Nguồn sự thật là `transactions`: mọi giao dịch `posted` + `expense` đều xuất
 * hiện, kể cả khi bản ghi `reflections` chưa kịp bổ sung (dữ liệu cũ). Giao dịch
 * thu nhập, chuyển ví nội bộ, điều chỉnh số dư và giao dịch đã hủy không bao
 * giờ vào nhật ký — nhờ đó hoàn tiền/điều chỉnh không bị tính là chi tiêu.
 */
export async function journal(db, userId, { at = new Date() } = {}) {
  const rows = await db
    .collection("transactions")
    .aggregate([
      { $match: { userId, status: "posted", type: "expense" } },
      { $sort: { occurredAt: -1, _id: -1 } },
      { $limit: 500 },
      {
        $lookup: {
          from: "reflections",
          localField: "_id",
          foreignField: "transactionId",
          as: "reflection",
        },
      },
      { $unwind: { path: "$reflection", preserveNullAndEmptyArrays: true } },
    ])
    .toArray();
  const cats = await categoryMap(db, userId);
  return rows.map((t) => {
    const r = t.reflection || {
      _id: null,
      status: "pending",
      dueAt: new Date(t.occurredAt.getTime() + 7 * 86400000),
    };
    return journalItem(r, t, cats, at);
  });
}


/**
 * Thấu hiểu bản thân: tổng hợp đánh giá theo danh mục.
 * Chỉ trả về luận điểm khi số mẫu đủ lớn; kèm tỷ lệ và số lượng làm căn cứ.
 */
export async function selfInsight(db, userId) {
  const rows = await db
    .collection("reflections")
    .aggregate(
      [
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
        { $match: { "t.userId": userId, "t.status": "posted", "t.type": "expense" } },
        { $sort: { ratedAt: -1 } },
        { $limit: 300 },
      ],
    )
    .toArray();
  const cats = await categoryMap(db, userId);
  const byCat = new Map();
  for (const row of rows) {
    const key = row.t.categoryId ? row.t.categoryId.toHexString() : "none";
    if (!byCat.has(key)) byCat.set(key, []);
    byCat.get(key).push(row);
  }
  const groups = [];
  for (const [key, items] of byCat) {
    const c = cats.get(key);
    const total = items.length;
    const good = items.filter((x) => x.rating === "worth_it").length;
    const bad = items.filter((x) => x.rating === "reconsider").length;
    groups.push({
      categoryId: key === "none" ? null : items[0].t.categoryId,
      name: c?.name || "Khác",
      sampleCount: total,
      worthIt: good,
      reconsider: bad,
      neutral: total - good - bad,
      worthItPercent: Math.round((good / total) * 100),
      reconsiderPercent: Math.round((bad / total) * 100),
      evidenceTransactionIds: items.slice(0, 5).map((x) => x.t._id),
    });
  }
  groups.sort((a, b) => b.sampleCount - a.sampleCount);

  const totalSamples = rows.length;
  const enough = totalSamples >= REVIEW_MIN_SAMPLES;
  const positive = groups.filter(
    (g) => g.sampleCount >= 2 && g.worthItPercent >= 60,
  );
  const negative = groups.filter(
    (g) => g.sampleCount >= 2 && g.reconsiderPercent >= 50,
  );

  const statements = [];
  if (enough) {
    for (const g of positive.slice(0, 2)) {
      statements.push({
        kind: "positive",
        text: `Bạn thường đánh giá cao các khoản chi ${g.name}.`,
        categoryId: g.categoryId,
        percent: g.worthItPercent,
        sampleCount: g.sampleCount,
        count: g.worthIt,
        rating: "worth_it",
        evidenceTransactionIds: g.evidenceTransactionIds,
      });
    }
    for (const g of negative.slice(0, 2)) {
      statements.push({
        kind: "negative",
        text: `Các khoản ${g.name} thường được đánh giá Muốn cân nhắc lại.`,
        categoryId: g.categoryId,
        percent: g.reconsiderPercent,
        sampleCount: g.sampleCount,
        count: g.reconsider,
        rating: "reconsider",
        evidenceTransactionIds: g.evidenceTransactionIds,
      });
    }
  }

  return {
    sampleCount: totalSamples,
    ratedCount: totalSamples,
    hasEnoughData: enough,
    minimumSamples: REVIEW_MIN_SAMPLES,
    strongSignalSamples: REVIEW_STRONG_SIGNAL,
    groups,
    statements,
  };
}

/**
 * Gợi ý ngân sách từ dữ liệu thật.
 *
 * Hai nguồn tín hiệu, ưu tiên tín hiệu mạnh hơn:
 *  1. Đánh giá thật: danh mục được đánh giá "Đáng tiền" nhưng sắp hết hạn mức,
 *     hoặc bị đánh giá "Muốn cân nhắc lại" mà vẫn còn dư nhiều.
 *  2. Mức chi thực tế 4 tuần gần nhất: danh mục đã vượt hạn mức (gợi ý nâng)
 *     hoặc chỉ dùng dưới một nửa hạn mức (gợi ý hạ), kể cả khi chưa có đánh giá
 *     — để mục Gợi ý ngân sách không rỗng ngay từ khi người dùng mới dùng app.
 *
 * Mỗi gợi ý gắn với một dòng hạn mức trong kỳ ngân sách đang mở, kèm lý do và
 * giao dịch căn cứ. KHÔNG tự sửa ngân sách — chỉ trả về đề xuất; việc áp dụng
 * phải qua xác nhận của người dùng.
 *
 * Trả kèm `reason`/`nextStep` khi danh sách rỗng để UI giải thích cụ thể thay
 * vì câu chung "chưa có gợi ý phù hợp".
 */
export async function budgetSuggestions(db, userId, zone, at = new Date()) {
  const plan =
    (await db.collection("budget_plans").findOne(
      { userId, status: "active", startAt: { $lte: at }, endAt: { $gt: at } },
      { sort: { updatedAt: -1, createdAt: -1 } },
    )) ||
    (await db.collection("budget_plans").findOne(
      { userId, status: "active" },
      { sort: { updatedAt: -1, createdAt: -1 } },
    ));
  const cats = await categoryMap(db, userId);
  const insight = await selfInsight(db, userId);
  const suggestions = [];

  // Cửa sổ đo mức chi thực tế: 4 tuần gần nhất. Nếu người dùng chưa chi trong
  // 4 tuần (ví dụ dữ liệu demo cũ hơn, hoặc ít dùng app), lùi cửa sổ về 4 tuần
  // tính tới giao dịch chi gần nhất để vẫn có căn cứ thật thay vì rỗng.
  const now = DateTime.fromJSDate(at, { zone }).startOf("day");
  const groupSpend = (from, to) =>
    db
      .collection("transactions")
      .aggregate([
        {
          $match: {
            userId,
            status: "posted",
            type: "expense",
            occurredAt: { $gte: from, $lt: to },
          },
        },
        {
          $group: {
            _id: "$categoryId",
            amount: { $sum: "$amount" },
            count: { $sum: 1 },
            ids: { $push: "$_id" },
          },
        },
      ])
      .toArray();
  let rows = await groupSpend(now.minus({ weeks: 4 }).toJSDate(), at);
  let windowStart = now.minus({ weeks: 4 });
  if (!rows.length) {
    const latest = await db
      .collection("transactions")
      .find({ userId, status: "posted", type: "expense" })
      .sort({ occurredAt: -1 })
      .limit(1)
      .project({ occurredAt: 1 })
      .toArray();
    if (latest.length) {
      const anchor = DateTime.fromJSDate(latest[0].occurredAt, { zone });
      windowStart = anchor.minus({ weeks: 4 });
      rows = await groupSpend(
        windowStart.toJSDate(),
        anchor.plus({ days: 1 }).toJSDate(),
      );
    }
  }
  const spendByCat = new Map(rows.map((r) => [r._id.toHexString(), r]));

  const limitFor = (catId) =>
    plan?.limits?.find((l) => l.categoryId.equals(catId)) || null;

  // Thống kê mức dùng hạn mức trong kỳ ngân sách đang mở — dùng lại đúng
  // công thức budgetView để không có công thức song song.
  //
  // Nếu kỳ ngân sách không bao phủ giao dịch gần đây (kỳ đã hết hoặc người
  // dùng mới đổi kỳ), số chi trong kỳ bằng 0; khi đó dùng mức chi 4 tuần gần
  // nhất làm tham chiếu để vẫn đưa ra được gợi ý có căn cứ thật.
  const planView = plan ? await budgetView(db, userId, plan) : null;
  const usage = (planView?.limits || []).map((l) => {
    const limit = B(l.limit);
    const spentPlan = B(l.spent);
    const recent = spendByCat.get(l.categoryId.toHexString());
    // Chỉ dùng fallback 4 tuần khi kỳ ngân sách không có chi nào; tránh cộng
    // dồn hai nguồn vào cùng một con số (không có công thức song song).
    const spent = spentPlan > 0n ? spentPlan : recent ? B(recent.amount) : 0n;
    return {
      categoryId: l.categoryId,
      categoryName: cats.get(l.categoryId.toHexString())?.name || "Khác",
      limit,
      spent,
      spentPlan,
      percent: fraction(spent, limit),
      transactions: recent?.count || 0,
    };
  });

  const ceil10k = (n) => ((n + 9999n) / 10000n) * 10000n;
  const floor10k = (n) => (n / 10000n) * 10000n;
  const seen = new Set();
  const push = (s) => {
    const key = String(s.categoryId);
    if (seen.has(key)) return;
    seen.add(key);
    suggestions.push(s);
  };

  // 1) Đánh giá "Đáng tiền" nhưng sắp/đã hết hạn mức → nâng hạn mức.
  for (const g of insight.groups) {
    if (!g.categoryId || g.sampleCount < 2 || g.worthItPercent < 60) continue;
    const line = limitFor(g.categoryId);
    if (!line) continue;
    const u = usage.find((x) => x.categoryId.equals(g.categoryId));
    if (!u || u.percent === null || u.percent < 80) continue;
    const limit = u.limit;
    const proposedRounded = ceil10k((u.spent > limit ? u.spent : limit) * 11n / 10n);
    if (proposedRounded <= limit) continue;
    push({
      kind: "increase_limit",
      categoryId: g.categoryId,
      categoryName: u.categoryName,
      budgetId: plan?._id || null,
      currentLimit: limit,
      proposedLimit: proposedRounded,
      usedPercent: u.percent,
      reason:
        `${g.worthItPercent}% trong ${g.sampleCount} đánh giá về ${g.categoryName} là "Đáng tiền", ` +
        `và bạn đã dùng ${u.percent}% hạn mức kỳ này.`,
      evidenceTransactionIds: g.evidenceTransactionIds,
      evidenceSpend: u.spent,
    });
  }

  // 2) Đánh giá "Muốn cân nhắc lại" mà vẫn dư hạn mức → giảm hạn mức.
  for (const g of insight.groups) {
    if (!g.categoryId || g.sampleCount < 2 || g.reconsiderPercent < 50) continue;
    const line = limitFor(g.categoryId);
    if (!line) continue;
    const u = usage.find((x) => x.categoryId.equals(g.categoryId));
    if (!u || u.percent === null || u.percent >= 90) continue;
    const proposedRounded = ceil10k(u.spent > 0n ? u.spent : u.limit / 4n);
    if (proposedRounded >= u.limit || proposedRounded < 10000n) continue;
    push({
      kind: "decrease_limit",
      categoryId: g.categoryId,
      categoryName: u.categoryName,
      budgetId: plan?._id || null,
      currentLimit: u.limit,
      proposedLimit: proposedRounded,
      usedPercent: u.percent,
      reason:
        `${g.reconsiderPercent}% trong ${g.sampleCount} đánh giá về ${u.categoryName} là "Muốn cân nhắc lại". ` +
        `Hạ hạn mức về sát mức chi thực tế giúp bạn có thêm khoảng lặng trước khi chi.`,
      evidenceTransactionIds: g.evidenceTransactionIds,
      evidenceSpend: u.spent,
    });
  }

  // 3) Chưa đủ đánh giá: dựa vào mức chi thực tế của kỳ ngân sách.
  //    - Đã chạm/vượt hạn mức → nâng để không bị "vỡ" ngân sách.
  for (const u of usage) {
    if (u.percent === null || u.percent < 95) continue;
    const limit = u.limit;
    const proposedRounded = ceil10k((u.spent > limit ? u.spent : limit) * 11n / 10n);
    if (proposedRounded <= limit) continue;
    push({
      kind: "increase_limit",
      categoryId: u.categoryId,
      categoryName: u.categoryName,
      budgetId: plan?._id || null,
      currentLimit: limit,
      proposedLimit: proposedRounded,
      usedPercent: u.percent,
      reason:
        `Bạn đã dùng ${u.percent}% hạn mức ${u.categoryName} ` +
        `(${u.spentPlan > 0n ? "trong kỳ này" : "theo chi thực tế 4 tuần gần nhất"}, ` +
        `${u.transactions} giao dịch). Nâng hạn mức giúp kế hoạch khớp với chi thực tế.`,
      evidenceTransactionIds: await topSpendIds(db, userId, u.categoryId),
      evidenceSpend: u.spent,
    });
  }

  //    - Dùng ít hơn hẳn nhịp chi kỳ vọng → giảm nhẹ 20%.
  //      Chỉ xét sau khi kỳ đã đi qua một nửa để không cắt hạn mức quá sớm.
  const elapsedPercent = plan
    ? Math.max(
        0,
        Math.min(
          100,
          Math.round(
            ((at.getTime() - plan.startAt.getTime()) /
              Math.max(1, plan.endAt.getTime() - plan.startAt.getTime())) *
              100,
          ),
        ),
      )
    : 0;
  for (const u of usage) {
    if (elapsedPercent < 50) break;
    if (u.percent === null || u.percent > 60) continue;
    if (u.spent <= 0n || u.transactions < 2) continue;
    // Chi thực tế thấp hơn một nửa nhịp đã trôi qua → hạn mức đang rộng.
    if (u.percent > elapsedPercent / 2) continue;
    const proposedRounded = floor10k((u.limit * 80n) / 100n);
    if (proposedRounded >= u.limit || proposedRounded < 10000n) continue;
    push({
      kind: "decrease_limit",
      categoryId: u.categoryId,
      categoryName: u.categoryName,
      budgetId: plan?._id || null,
      currentLimit: u.limit,
      proposedLimit: proposedRounded,
      usedPercent: u.percent,
      reason:
        `${elapsedPercent}% kỳ ngân sách đã trôi qua nhưng ${u.categoryName} mới dùng ` +
        `${u.percent}% hạn mức (${u.transactions} giao dịch). Hạ 20% để phần dư chuyển sang mục tiêu khác.`,
      evidenceTransactionIds: await topSpendIds(db, userId, u.categoryId),
      evidenceSpend: u.spent,
    });
  }

  // Tối đa 3 gợi ý, giữ thứ tự ưu tiên: tín hiệu đánh giá trước, rồi tới mức
  // chi thực tế (đã push theo đúng thứ tự này).
  return {
    budgetId: plan?._id || null,
    budgetName: plan?.name || null,
    hasBudget: !!plan,
    minimumSamples: REVIEW_MIN_SAMPLES,
    suggestions: suggestions.slice(0, 3),
    // Mức dùng hạn mức thật để UI vẫn có thông tin hữu ích khi chưa có gợi ý.
    usage: usage
      .filter((u) => u.percent !== null)
      .sort((a, b) => (b.percent || 0) - (a.percent || 0))
      .slice(0, 4)
      .map((u) => ({
        categoryId: u.categoryId,
        categoryName: u.categoryName,
        limit: u.limit,
        spent: u.spent,
        percent: u.percent,
        transactions: u.transactions,
      })),
    emptyReason: emptyBudgetReason({ plan, usage, suggestions, insight }),
  };
}

/** Vì sao chưa có gợi ý — để UI nói đúng việc người dùng cần làm tiếp. */
function emptyBudgetReason({ plan, usage, suggestions, insight }) {
  if (suggestions.length) return null;
  if (!plan)
    return {
      code: "no_budget",
      reason: "Chưa có kỳ ngân sách đang mở nên chưa thể so sánh hạn mức.",
      nextStep:
        "Tạo kỳ ngân sách ở tab Kế hoạch, sau đó quay lại đây để nhận gợi ý theo chi thực tế.",
    };
  if (!usage.some((u) => u.spent > 0n))
    return {
      code: "no_spending",
      reason:
        "Chưa có khoản chi nào trong kỳ ngân sách hoặc 4 tuần gần nhất nên chưa có cơ sở điều chỉnh.",
      nextStep:
        "Ghi các khoản chi hằng ngày; sau vài giao dịch Ví An sẽ so sánh với hạn mức và đề xuất điều chỉnh.",
    };
  if (insight.sampleCount === 0)
    return {
      code: "no_ratings",
      reason:
        "Mức chi hiện tại đang nằm trong khoảng hợp lý so với hạn mức, nên chưa cần đổi hạn mức.",
      nextStep:
        "Đánh giá các khoản chi sau 7 ngày để Ví An hiểu bạn thấy khoản nào đáng tiền và tinh chỉnh chính xác hơn.",
    };
  return {
    code: "balanced",
    reason:
      "Chi thực tế và đánh giá của bạn đang khớp với hạn mức hiện tại, chưa có điểm nào cần điều chỉnh.",
    nextStep:
      "Tiếp tục ghi chi và đánh giá; gợi ý sẽ xuất hiện khi một danh mục lệch khỏi hạn mức.",
  };
}

/** Vài giao dịch lớn nhất của danh mục trong 4 tuần — làm căn cứ hiển thị. */
async function topSpendIds(db, userId, categoryId, limit = 5) {
  const rows = await db
    .collection("transactions")
    .find({ userId, status: "posted", type: "expense", categoryId })
    .sort({ occurredAt: -1 })
    .limit(limit)
    .project({ _id: 1 })
    .toArray();
  return rows.map((r) => r._id);
}

/** Chi tiết giao dịch làm căn cứ cho một gợi ý / luận điểm. */
export async function evidenceTransactions(db, userId, ids) {
  if (!ids?.length) return [];
  const rows = await db
    .collection("transactions")
    .find({ userId, _id: { $in: ids.map((x) => (typeof x === "string" ? oid(x) : x)) } })
    .sort({ occurredAt: -1 })
    .toArray();
  const cats = await categoryMap(db, userId);
  return rows.map((t) => ({
    _id: t._id,
    amount: t.amount,
    occurredAt: t.occurredAt,
    note: t.note || null,
    type: t.type,
    categoryId: t.categoryId || null,
    categoryName: t.categoryId ? cats.get(t.categoryId.toHexString())?.name || null : null,
  }));
}

/** Danh sách tuần có giao dịch chi, mới nhất trước — cho bộ chọn tuần. */
export async function reviewWeeks(db, userId, zone, limit = 12) {
  const rows = await db
    .collection("transactions")
    .find({ userId, status: "posted", type: { $in: ["expense", "income"] } })
    .project({ occurredAt: 1 })
    .sort({ occurredAt: -1 })
    .limit(2000)
    .toArray();
  const seen = new Map();

  // Luôn đảm bảo tuần hiện tại có mặt trong danh sách tuần
  const currentWeek = weekBounds(new Date(), zone);
  const currentKey = iso(currentWeek.start);
  seen.set(currentKey, {
    startAt: currentWeek.start,
    endAt: currentWeek.end,
    label: `${DateTime.fromJSDate(currentWeek.start, { zone }).toFormat("dd/MM")} – ${DateTime.fromJSDate(
      new Date(currentWeek.end.getTime() - 1),
      { zone },
    ).toFormat("dd/MM/yyyy")}`,
  });

  for (const t of rows) {
    const w = weekBounds(t.occurredAt, zone);
    const key = iso(w.start);
    if (!seen.has(key)) {
      seen.set(key, {
        startAt: w.start,
        endAt: w.end,
        label: `${DateTime.fromJSDate(w.start, { zone }).toFormat("dd/MM")} – ${DateTime.fromJSDate(
          new Date(w.end.getTime() - 1),
          { zone },
        ).toFormat("dd/MM/yyyy")}`,
      });
    }
    if (seen.size >= limit) break;
  }
  return [...seen.values()];
}

export { iso, tz };
