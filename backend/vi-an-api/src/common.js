import { ObjectId, Long, Int32 } from "mongodb";
import {
  createHash,
  randomBytes,
  scryptSync,
  timingSafeEqual,
} from "node:crypto";
import { DateTime } from "luxon";
import { z } from "zod";

export class ApiError extends Error {
  constructor(status, code, message, details) {
    super(message);
    Object.assign(this, { statusCode: status, code, details });
  }
}
export const fail = (ok, code, message, status = 409) => {
  if (!ok) throw new ApiError(status, code, message);
};
export const oid = (s) => new ObjectId(s);
export const id = z.string().regex(/^[a-f\d]{24}$/i);
export const money = z.string().regex(/^(0|[1-9]\d{0,15})$/);
export const positive = money.refine(
  (v) => BigInt(v) > 0n,
  "Số tiền phải lớn hơn 0",
);
export const timestamp = z.string().datetime({ offset: true });
export const text = z.string().trim().min(1).max(160);
export const note = z.string().max(2000);
export const version = z.number().int().min(1);
export const L = (n) => Long.fromString(String(n));
export const I = (n) => new Int32(n);
export const B = (n) => (n == null ? 0n : BigInt(n.toString()));
export const now = () => new Date();
export const base = (userId) => ({
  _id: new ObjectId(),
  userId,
  createdAt: now(),
  updatedAt: now(),
});
export function json(value) {
  if (value == null) return value;
  if (value instanceof ObjectId) return value.toHexString();
  if (Long.isLong(value) || typeof value === "bigint") return value.toString();
  if (value instanceof Int32) return value.valueOf();
  if (value instanceof Date) return value.toISOString();
  if (Array.isArray(value)) return value.map(json);
  if (typeof value === "object")
    return Object.fromEntries(
      Object.entries(value).map(([k, v]) => [k, json(v)]),
    );
  return value;
}
export function canonical(value) {
  if (Array.isArray(value)) return value.map(canonical);
  if (value && typeof value === "object")
    return Object.fromEntries(
      Object.keys(value)
        .sort()
        .map((k) => [k, canonical(value[k])]),
    );
  return value;
}
export const hash = (value) =>
  createHash("sha256")
    .update(JSON.stringify(canonical(value)))
    .digest("hex");
export function passwordHash(password) {
  const salt = randomBytes(16).toString("hex");
  return salt + ":" + scryptSync(password, salt, 64).toString("hex");
}
export function passwordMatches(password, stored) {
  const [salt, digest] = stored.split(":");
  const expected = Buffer.from(digest, "hex");
  const actual = scryptSync(password, salt, 64);
  return expected.length === actual.length && timingSafeEqual(expected, actual);
}
export const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
export const localDay = (date, tz = "Asia/Ho_Chi_Minh") =>
  DateTime.fromJSDate(new Date(date), { zone: tz }).startOf("day");
export const daysBetween = (a, b, tz) =>
  Math.round(localDay(b, tz).diff(localDay(a, tz), "days").days);
export function bounds(start, end) {
  const a = new Date(start),
    b = new Date(end);
  fail(a < b, "INVALID_PERIOD", "Ngày kết thúc phải sau ngày bắt đầu.", 422);
  return { a, b };
}
export const fraction = (a, b) =>
  b === 0n ? null : Number((a * 10000n) / b) / 100;
export const sumRows = (rows) => rows.reduce((s, x) => s + B(x.amount), 0n);
export function csvSafe(s) {
  return /^[=+\-@\t\r]/.test(String(s)) ? "'" + s : s;
}

export async function owned(db, col, userId, idValue, session) {
  const v = await db
    .collection(col)
    .findOne(
      { _id: typeof idValue === "string" ? oid(idValue) : idValue, userId },
      { session },
    );
  fail(v, "NOT_FOUND", "Không tìm thấy dữ liệu.", 404);
  return v;
}
export async function atomic(ctx, userId, key, scope, body, action) {
  fail(
    ctx.transactionCapable,
    "REPLICA_SET_REQUIRED",
    "Chạy MongoDB replica set theo README để ghi dữ liệu.",
    503,
  );
  const digest = hash({ scope, body }),
    session = ctx.client.startSession();
  try {
    return await session.withTransaction(
      async () => {
        // Serialize financial writes per user to protect read-dependent invariants.
        const locked = await ctx.db
          .collection("users")
          .updateOne(
            { _id: userId },
            { $inc: { apiRevision: I(1) } },
            { session },
          );
        fail(
          locked.matchedCount === 1,
          "USER_NOT_FOUND",
          "Người dùng không tồn tại.",
          401,
        );
        const previous = await ctx.db
          .collection("api_requests")
          .findOne({ userId, key }, { session });
        if (previous) {
          fail(
            previous.digest === digest,
            "IDEMPOTENCY_CONFLICT",
            "Khóa này đã được dùng với yêu cầu khác.",
          );
          return previous.result;
        }
        const result = json(await action(session));
        await ctx.db
          .collection("api_requests")
          .insertOne(
            { ...base(userId), key, digest, scope, result },
            { session },
          );
        return result;
      },
      {
        readConcern: { level: "snapshot" },
        writeConcern: { w: "majority" },
        readPreference: "primary",
      },
    );
  } finally {
    await session.endSession();
  }
}

export async function readSnapshot(db, action) {
  const session = db.client.startSession({ snapshot: true });
  try {
    return await action(session);
  } finally {
    await session.endSession();
  }
}
