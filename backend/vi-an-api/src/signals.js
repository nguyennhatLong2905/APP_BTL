import { base, B, L, I, now, owned, fail, hash, oid } from "./common.js";
import * as S from "./schemas.js";
import { budgetView } from "./views.js";

// Called only inside the same transaction as the financial write.
export async function budgetAlerts(db, userId, session) {
  const plans = await db
    .collection("budget_plans")
    .find({ userId, status: "active" }, { session })
    .toArray();
  for (const plan of plans) {
    const view = await budgetView(db, userId, plan, session);
    for (const row of view.limits) {
      const dedupeKey = "budget:" + plan._id + ":" + row.categoryId;
      if (row.warning && B(row.spent) > 0n) {
        await db.collection("notifications").updateOne(
          { userId, dedupeKey },
          {
            $set: {
              status: "pending",
              updatedAt: now(),
              details: {
                categoryId: row.categoryId,
                spent: L(row.spent),
                limit: row.limit,
              },
            },
            $setOnInsert: {
              _id: base(userId)._id,
              userId,
              createdAt: now(),
              type: "budget_warning",
              entityId: plan._id,
              scheduledAt: now(),
              dedupeKey,
              attempts: I(0),
            },
          },
          { upsert: true, session },
        );
      } else
        await db
          .collection("notifications")
          .updateMany(
            { userId, dedupeKey, status: "pending" },
            { $set: { status: "cancelled", updatedAt: now() } },
            { session },
          );
    }
  }
}

export function signalRoutes(ctx, r) {
  const db = ctx.db;
  r(
    "POST",
    "/insights/generate",
    {
      write: true,
      body: S.obj({}),
      tag: "Reflection",
      summary: "Sinh gợi ý từ tối thiểu 5 đánh giá thực tế mỗi danh mục",
    },
    async (req, reply, session) => {
      const rows = await db
        .collection("reflections")
        .aggregate(
          [
            { $match: { userId: req.owner, status: "rated" } },
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
                "t.userId": req.owner,
                "t.status": "posted",
                "t.type": "expense",
              },
            },
            { $sort: { ratedAt: -1 } },
            { $limit: 100 },
          ],
          { session },
        )
        .toArray();
      const groups = new Map();
      for (const row of rows) {
        const key = row.t.categoryId.toHexString();
        if (!groups.has(key)) groups.set(key, []);
        groups.get(key).push(row);
      }
      const suggestions = [];
      for (const [catId, items] of groups) {
        if (items.length < 5) continue;
        const good = items.filter((x) => x.rating === "worth_it").length,
          bad = items.filter((x) => x.rating === "reconsider").length;
        const type =
          bad / items.length >= 0.6
            ? "cooldown_suggestion"
            : good / items.length >= 0.6
              ? "budget_suggestion"
              : null;
        if (!type) continue;
        const cat = await owned(db, "categories", req.owner, catId, session),
          ids = items.map((x) => x.t._id),
          evidenceKey = hash({
            type,
            ratings: items.map((x) => String(x.t._id) + ":" + x.rating).sort(),
          });
        const old = await db
          .collection("insights")
          .findOne({ userId: req.owner, evidenceKey }, { session });
        if (old) {
          suggestions.push(old);
          continue;
        }
        const i = {
          ...base(req.owner),
          type,
          title:
            type === "cooldown_suggestion"
              ? "Thử chờ 48 giờ trước khi mua"
              : "Xem lại ngân sách " + cat.name,
          body: `${type === "cooldown_suggestion" ? bad : good}/${items.length} khoản trong danh mục ${cat.name} được đánh giá ${type === "cooldown_suggestion" ? "cần cân nhắc lại" : "đáng tiền"}. Đây là mẫu đánh giá của bạn, không đại diện toàn bộ chi tiêu.`,
          evidenceTransactionIds: ids,
          evidenceKey,
          status: "new",
          generatedAt: now(),
          modelVersion: "rules-v1",
          action:
            type === "cooldown_suggestion"
              ? { type: "start_challenge", challengeType: "cooldown_48h" }
              : { type: "adjust_budget", categoryId: oid(catId) },
        };
        await db.collection("insights").insertOne(i, { session });
        suggestions.push(i);
      }
      return {
        sampleCount: rows.length,
        minimumPerCategory: 5,
        items: suggestions,
      };
    },
  );
  r(
    "POST",
    "/insights/:id/apply",
    {
      write: true,
      body: S.obj({ budgetId: S.id.optional(), newLimit: S.money.optional() }),
      tag: "Reflection",
      summary: "Xác nhận gợi ý: đổi hạn mức đã chọn hoặc tạo thử thách 48h",
    },
    async (req, reply, session) => {
      const i = await owned(db, "insights", req.owner, req.params.id, session);
      fail(i.status === "new", "INSIGHT_HANDLED", "Gợi ý đã được xử lý.");
      let result;
      if (
        i.action?.type === "start_challenge" &&
        i.action.challengeType === "cooldown_48h"
      ) {
        const c = {
          ...base(req.owner),
          type: "cooldown_48h",
          startAt: now(),
          endAt: new Date(Date.now() + 48 * 3600000),
          status: "active",
        };
        await db.collection("challenges").insertOne(c, { session });
        result = { challenge: c };
      } else if (i.action?.type === "adjust_budget") {
        fail(
          req.input.budgetId && req.input.newLimit !== undefined,
          "BUDGET_CONFIRMATION_REQUIRED",
          "Chọn kỳ ngân sách và hạn mức mới.",
          422,
        );
        const p = await owned(
          db,
          "budget_plans",
          req.owner,
          req.input.budgetId,
          session,
        );
        fail(p.status === "active", "BUDGET_CLOSED", "Ngân sách đã đóng.");
        const line = p.limits.find((x) =>
          x.categoryId.equals(i.action.categoryId),
        );
        fail(
          line,
          "CATEGORY_NOT_IN_BUDGET",
          "Danh mục chưa có trong kỳ ngân sách.",
          422,
        );
        const previousLimit = line.limit;
        line.limit = L(req.input.newLimit);
        p.updatedAt = now();
        await db
          .collection("budget_plans")
          .replaceOne({ _id: p._id, userId: req.owner }, p, { session });
        await budgetAlerts(db, req.owner, session);
        result = {
          previousLimit,
          budget: await budgetView(db, req.owner, p, session),
        };
      } else
        fail(false, "UNSUPPORTED_ACTION", "Gợi ý này chỉ để tham khảo.", 422);
      await db
        .collection("insights")
        .updateOne(
          { _id: i._id, userId: req.owner },
          { $set: { status: "accepted", updatedAt: now() } },
          { session },
        );
      return result;
    },
  );
}
