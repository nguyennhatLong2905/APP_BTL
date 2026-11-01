import { DateTime } from "luxon";
import { base, now, I, atomic, localDay } from "./common.js";
import { notify } from "./ledger.js";
export async function generateBills(db, userId, session, at = new Date()) {
  const user = await db
    .collection("users")
    .findOne({ _id: userId }, { session });
  const zone = user.timezone || "Asia/Ho_Chi_Minh";
  const horizon = DateTime.fromJSDate(at, { zone })
    .plus({ years: 1 })
    .endOf("day");
  const templates = await db
    .collection("bill_templates")
    .find({ userId, active: true }, { session })
    .toArray();
  let created = 0;
  for (const t of templates) {
    const first = await db
      .collection("bill_occurrences")
      .find({ userId, templateId: t._id }, { session })
      .sort({ dueAt: 1 })
      .limit(1)
      .next();
    const origin = DateTime.fromJSDate(t.startAt || first?.dueAt || at, {
      zone,
    }).startOf("day");
    for (let n = 0; n < 1200; n++) {
      let date =
        t.frequency === "once"
          ? origin
          : t.frequency === "monthly"
            ? origin.plus({ months: n })
            : origin.plus({ years: n });
      if (t.frequency === "monthly" && t.dueDay)
        date = date.set({ day: Math.min(Number(t.dueDay), date.daysInMonth) });
      if (date > horizon) break;
      const dueAt = date.toJSDate();
      const existing = await db
        .collection("bill_occurrences")
        .findOne(
          {
            userId,
            templateId: t._id,
            $or: [
              { scheduledFor: dueAt },
              { scheduledFor: { $exists: false }, dueAt },
            ],
          },
          { session },
        );
      if (!existing) {
        const bill = {
          ...base(userId),
          templateId: t._id,
          name: t.name,
          amount: t.estimatedAmount,
          categoryId: t.categoryId,
          dueAt,
          scheduledFor: dueAt,
          status: "unpaid",
        };
        await db.collection("bill_occurrences").insertOne(bill, { session });
        await notify(
          db,
          userId,
          "bill_due",
          bill._id,
          date
            .minus({ days: Number(t.reminderDaysBefore ?? 3) })
            .set({ hour: 9 })
            .toJSDate(),
          "bill:" + bill._id,
          session,
        );
        created++;
      }
      if (t.frequency === "once") break;
    }
  }
  await db
    .collection("challenges")
    .updateMany(
      { userId, status: "active", endAt: { $lte: at } },
      { $set: { status: "completed", updatedAt: now() } },
      { session },
    );
  return { created };
}
export async function runJobs(ctx) {
  if (!ctx.transactionCapable) return;
  for await (const user of ctx.db.collection("users").find({})) {
    try {
      const key =
        "scheduler:" + localDay(new Date(), user.timezone).toISODate();
      await atomic(ctx, user._id, key, "scheduler", {}, (s) =>
        generateBills(ctx.db, user._id, s),
      );
    } catch (e) {
      ctx.log?.error({ err: e }, "Scheduled job failed");
    }
  }
}
