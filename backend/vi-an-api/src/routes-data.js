import { parse } from "csv-parse/sync";
import { stringify } from "csv-stringify/sync";
import { BSON, Binary } from "mongodb";
const { EJSON } = BSON;
import { createHmac, timingSafeEqual } from "node:crypto";
import {
  base,
  owned,
  oid,
  L,
  I,
  B,
  fail,
  now,
  json,
  hash,
  csvSafe,
} from "./common.js";
import * as S from "./schemas.js";
import { validateEntry, createEntry } from "./ledger.js";

const financialCollections = [
  "wallets",
  "categories",
  "transactions",
  "budget_plans",
  "goals",
  "goal_allocations",
  "bill_templates",
  "bill_occurrences",
  "purchase_intents",
  "reflections",
  "insights",
  "challenges",
  "notifications",
  "attachments",
];
export function dataRoutes(app, ctx, r) {
  const db = ctx.db;
  const sign = (s) =>
    createHmac("sha256", ctx.backupSecret || "docs-only")
      .update(s)
      .digest("hex");
  r(
    "POST",
    "/attachments",
    {
      write: true,
      body: S.obj({
        filename: S.text,
        mimeType: S.z.enum(["image/jpeg", "image/png", "image/webp"]),
        base64: S.z.string().min(1).max(2_800_000),
      }),
      tag: "Attachments",
      summary: "Tải ảnh hóa đơn PNG/JPEG/WebP tối đa 2 MB",
    },
    async (req, reply, session) => {
      const content = Buffer.from(req.input.base64, "base64");
      fail(
        content.length > 0 && content.length <= 2_000_000,
        "INVALID_ATTACHMENT",
        "Ảnh vượt giới hạn 2 MB.",
        422,
      );
      const valid =
        req.input.mimeType === "image/png"
          ? content
              .subarray(0, 8)
              .equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))
          : req.input.mimeType === "image/jpeg"
            ? content[0] === 255 && content[1] === 216 && content[2] === 255
            : content.subarray(0, 4).toString() === "RIFF" &&
              content.subarray(8, 12).toString() === "WEBP";
      fail(
        valid,
        "INVALID_ATTACHMENT",
        "Nội dung ảnh không khớp định dạng.",
        422,
      );
      const meta = {
        ...base(req.owner),
        filename: req.input.filename,
        mimeType: req.input.mimeType,
        size: content.length,
      };
      await db
        .collection("attachments")
        .insertOne({ ...meta, content: new Binary(content) }, { session });
      return { ...meta, url: "/api/v1/attachments/" + meta._id };
    },
  );
  r(
    "GET",
    "/attachments/:id",
    { tag: "Attachments", raw: true, summary: "Đọc ảnh hóa đơn có xác thực" },
    async (req, reply) => {
      const file = await owned(db, "attachments", req.owner, req.params.id);
      reply
        .type(file.mimeType)
        .header("X-Content-Type-Options", "nosniff")
        .header("Cache-Control", "private, no-store");
      return Buffer.from(file.content.buffer);
    },
  );
  r(
    "POST",
    "/imports/preview",
    {
      write: true,
      body: S.obj({
        csv: S.z.string().min(1).max(2_000_000),
        mapping: S.obj({
          type: S.text,
          amount: S.text,
          occurredAt: S.text,
          walletId: S.text.optional(),
          fromWalletId: S.text.optional(),
          toWalletId: S.text.optional(),
          categoryId: S.text.optional(),
          note: S.text.optional(),
        }),
      }),
      tag: "Data",
      summary: "Đọc CSV, ghép cột, kiểm tra lỗi và nghi trùng",
    },
    async (req, reply, session) => {
      let source;
      try {
        source = parse(req.input.csv, {
          columns: true,
          skip_empty_lines: true,
          bom: true,
          max_record_size: 10000,
        });
      } catch {
        fail(false, "INVALID_CSV", "CSV không đúng cấu trúc.", 422);
      }
      fail(
        source.length <= 500,
        "IMPORT_TOO_LARGE",
        "Mỗi lần nhập tối đa 500 dòng.",
        422,
      );
      const rows = [];
      for (const [index, row] of source.entries()) {
        try {
          const raw = Object.fromEntries(
            Object.entries(req.input.mapping)
              .filter(([k, v]) => row[v] !== "" && row[v] !== undefined)
              .map(([k, v]) => [k, row[v]]),
          );
          const input = S.entry.parse(raw);
          fail(
            input.type !== "adjustment",
            "INVALID_IMPORT_TYPE",
            "CSV hỗ trợ thu, chi và chuyển ví.",
            422,
          );
          const t = await validateEntry(db, req.owner, input, session);
          const duplicate = await db
            .collection("transactions")
            .findOne(
              {
                userId: req.owner,
                status: "posted",
                type: t.type,
                amount: t.amount,
                occurredAt: t.occurredAt,
                ...(t.walletId
                  ? { walletId: t.walletId }
                  : { fromWalletId: t.fromWalletId, toWalletId: t.toWalletId }),
                ...(t.categoryId ? { categoryId: t.categoryId } : {}),
                note: t.note || "",
              },
              { session },
            );
          const fingerprint = hash(input);
          const repeat = rows.some((x) => x.fingerprint === fingerprint);
          rows.push({
            index,
            input,
            fingerprint,
            suspectedDuplicate: !!duplicate || repeat,
            error: null,
          });
        } catch (e) {
          rows.push({ index, error: e.message, input: null });
        }
      }
      const job = {
        ...base(req.owner),
        rows,
        status: "preview",
        expiresAt: new Date(Date.now() + 3600000),
      };
      await db.collection("import_jobs").insertOne(job, { session });
      return job;
    },
  );
  r(
    "POST",
    "/imports/:id/commit",
    {
      write: true,
      body: S.obj({
        selectedRows: S.z.array(S.z.number().int().min(0)).min(1).max(500),
        includeSuspectedDuplicates: S.z.boolean().default(false),
      }),
      tag: "Data",
      summary:
        "Xác nhận các dòng được nhập, toàn bộ cùng thành công hoặc rollback",
    },
    async (req, reply, session) => {
      const job = await owned(
        db,
        "import_jobs",
        req.owner,
        req.params.id,
        session,
      );
      fail(
        job.expiresAt > now(),
        "PREVIEW_EXPIRED",
        "Bản xem trước đã hết hạn.",
      );
      if (job.status === "committed")
        return { imported: job.imported, alreadyCommitted: true };
      const selected = [...new Set(req.input.selectedRows)];
      const ids = [];
      for (const index of selected) {
        const row = job.rows.find((x) => x.index === index);
        fail(
          row && !row.error,
          "INVALID_IMPORT_ROW",
          "Có dòng lỗi hoặc không tồn tại.",
          422,
        );
        fail(
          !row.suspectedDuplicate || req.input.includeSuspectedDuplicates,
          "DUPLICATE_REVIEW_REQUIRED",
          "Xác nhận rõ việc nhập dòng nghi trùng.",
          422,
        );
        const t = await createEntry(
          db,
          req.owner,
          { ...row.input, source: "import" },
          "import:" + job._id + ":" + index,
          session,
        );
        ids.push(t._id);
      }
      await db
        .collection("import_jobs")
        .updateOne(
          { _id: job._id },
          {
            $set: {
              status: "committed",
              imported: ids.length,
              transactionIds: ids,
              updatedAt: now(),
            },
          },
          { session },
        );
      return { imported: ids.length, transactionIds: ids };
    },
  );
  r(
    "GET",
    "/exports/transactions.csv",
    {
      query: S.obj({
        startAt: S.timestamp.optional(),
        endAt: S.timestamp.optional(),
        walletId: S.id.optional(),
      }),
      tag: "Data",
      raw: true,
      summary: "Xuất giao dịch CSV",
    },
    async (req, reply) => {
      const filter = { userId: req.owner, status: "posted" };
      if (req.filters.startAt || req.filters.endAt)
        filter.occurredAt = {
          ...(req.filters.startAt
            ? { $gte: new Date(req.filters.startAt) }
            : {}),
          ...(req.filters.endAt ? { $lt: new Date(req.filters.endAt) } : {}),
        };
      if (req.filters.walletId)
        filter.$or = ["walletId", "fromWalletId", "toWalletId"].map((k) => ({
          [k]: oid(req.filters.walletId),
        }));
      const tx = await db
        .collection("transactions")
        .find(filter)
        .sort({ occurredAt: -1 })
        .limit(10001)
        .toArray();
      fail(
        tx.length <= 10000,
        "EXPORT_TOO_LARGE",
        "Chọn khoảng thời gian nhỏ hơn để xuất tối đa 10.000 dòng.",
        422,
      );
      const rows = tx.map((t) => {
        const v = json(t);
        return {
          id: v._id,
          type: v.type,
          amount: v.amount,
          occurredAt: v.occurredAt,
          walletId: v.walletId || "",
          fromWalletId: v.fromWalletId || "",
          toWalletId: v.toWalletId || "",
          categoryId: v.categoryId || "",
          note: csvSafe(v.note || ""),
        };
      });
      reply
        .type("text/csv; charset=utf-8")
        .header(
          "Content-Disposition",
          'attachment; filename="vi-an-transactions.csv"',
        );
      return (
        "\uFEFF" +
        stringify(rows, {
          header: true,
          columns: [
            "id",
            "type",
            "amount",
            "occurredAt",
            "walletId",
            "fromWalletId",
            "toWalletId",
            "categoryId",
            "note",
          ],
        })
      );
    },
  );
  r(
    "GET",
    "/backup",
    {
      tag: "Data",
      summary: "Tạo bản sao dữ liệu có chữ ký; không chứa thông tin đăng nhập",
    },
    async (req) => {
      fail(
        ctx.transactionCapable,
        "REPLICA_SET_REQUIRED",
        "Cần replica set để sao lưu snapshot nhất quán.",
        503,
      );
      const session = ctx.client.startSession();
      let payload;
      try {
        payload = await session.withTransaction(
          async () => {
            const collections = {};
            let count = 0;
            for (const name of financialCollections) {
              collections[name] = await db
                .collection(name)
                .find({ userId: req.owner }, { session })
                .limit(10001)
                .toArray();
              count += collections[name].length;
              fail(
                count <= 10000,
                "BACKUP_TOO_LARGE",
                "Bản sao trong app tối đa 10.000 bản ghi.",
                422,
              );
            }
            const user = await db
              .collection("users")
              .findOne({ _id: req.owner }, { session });
            return EJSON.stringify(
              {
                formatVersion: 1,
                userId: req.owner,
                createdAt: now(),
                profile: {
                  displayName: user.displayName,
                  nextPayday: user.nextPayday,
                  settings: user.settings,
                  paydayDay: user.paydayDay,
                },
                collections,
              },
              { relaxed: false },
            );
          },
          {
            readConcern: { level: "snapshot" },
            writeConcern: { w: "majority" },
          },
        );
      } finally {
        await session.endSession();
      }
      fail(
        Buffer.byteLength(payload) < 4_000_000,
        "BACKUP_TOO_LARGE",
        "Bản sao vượt giới hạn 4 MB.",
        422,
      );
      return { payload, signature: sign(payload) };
    },
  );
  r(
    "POST",
    "/backup/preview",
    {
      write: true,
      body: S.obj({
        payload: S.z.string().max(4_000_000),
        signature: S.z.string().regex(/^[a-f\d]{64}$/),
      }),
      tag: "Data",
      summary: "Xem tác động khôi phục bản sao của cùng người dùng",
    },
    async (req, reply, session) => {
      fail(
        timingSafeEqual(
          Buffer.from(req.input.signature, "hex"),
          Buffer.from(sign(req.input.payload), "hex"),
        ),
        "INVALID_BACKUP",
        "Chữ ký bản sao không hợp lệ.",
        422,
      );
      const snapshot = EJSON.parse(req.input.payload, { relaxed: false });
      fail(
        snapshot.formatVersion.valueOf() === 1 &&
          snapshot.userId.equals(req.owner),
        "INVALID_BACKUP",
        "Bản sao không thuộc tài khoản hoặc sai phiên bản.",
        422,
      );
      const counts = {};
      for (const c of financialCollections) {
        fail(
          Array.isArray(snapshot.collections[c]),
          "INVALID_BACKUP",
          "Thiếu collection.",
          422,
        );
        for (const doc of snapshot.collections[c])
          fail(
            doc.userId.equals(req.owner),
            "INVALID_BACKUP",
            "Sai chủ sở hữu.",
            422,
          );
        counts[c] = {
          current: await db
            .collection(c)
            .countDocuments({ userId: req.owner }, { session }),
          replacement: snapshot.collections[c].length,
        };
      }
      const preview = {
        ...base(req.owner),
        kind: "restore",
        snapshot,
        counts,
        expiresAt: new Date(Date.now() + 15 * 60000),
      };
      await db.collection("backup_previews").insertOne(preview, { session });
      return {
        previewId: preview._id,
        mode: "replace-own-financial-data",
        counts,
        expiresAt: preview.expiresAt,
        confirmationText: "KHOI PHUC VI AN",
      };
    },
  );
  r(
    "POST",
    "/backup/:id/restore",
    {
      write: true,
      body: S.obj({ confirmation: S.z.literal("KHOI PHUC VI AN") }),
      tag: "Data",
      summary: "Khôi phục dữ liệu theo preview đã xác nhận",
    },
    async (req, reply, session) => {
      const p = await owned(
        db,
        "backup_previews",
        req.owner,
        req.params.id,
        session,
      );
      fail(
        p.kind === "restore" && p.expiresAt > now() && !p.usedAt,
        "PREVIEW_EXPIRED",
        "Preview hết hạn hoặc đã dùng.",
      );
      for (const c of financialCollections) {
        await db.collection(c).deleteMany({ userId: req.owner }, { session });
        if (p.snapshot.collections[c].length)
          await db
            .collection(c)
            .insertMany(p.snapshot.collections[c], { session });
      }
      await db
        .collection("api_requests")
        .deleteMany({ userId: req.owner }, { session });
      await db
        .collection("import_jobs")
        .deleteMany({ userId: req.owner }, { session });
      const profile = Object.fromEntries(
        Object.entries(p.snapshot.profile).filter(
          ([, v]) => v !== null && v !== undefined,
        ),
      );
      if (p.snapshot.profile.nextPayday === null) profile.nextPayday = null;
      await db
        .collection("users")
        .updateOne(
          { _id: req.owner },
          {
            $set: { ...profile, updatedAt: now() },
            $inc: { tokenVersion: I(1) },
          },
          { session },
        );
      await db
        .collection("backup_previews")
        .updateOne({ _id: p._id }, { $set: { usedAt: now() } }, { session });
      return { restored: true, loginRequired: true };
    },
  );
  r(
    "POST",
    "/data/erase-preview",
    {
      write: true,
      body: S.obj({}),
      tag: "Data",
      summary: "Xem phạm vi xóa toàn bộ dữ liệu tài chính của tài khoản",
    },
    async (req, reply, session) => {
      const counts = {};
      for (const c of financialCollections)
        counts[c] = await db
          .collection(c)
          .countDocuments({ userId: req.owner }, { session });
      const p = {
        ...base(req.owner),
        kind: "erase",
        expiresAt: new Date(Date.now() + 15 * 60000),
      };
      await db.collection("backup_previews").insertOne(p, { session });
      return {
        previewId: p._id,
        counts,
        confirmationText: "XOA DU LIEU VI AN",
      };
    },
  );
  r(
    "POST",
    "/data/:id/erase",
    {
      write: true,
      body: S.obj({ confirmation: S.z.literal("XOA DU LIEU VI AN") }),
      tag: "Data",
      summary: "Xóa dữ liệu tài chính sau khi xác nhận preview",
    },
    async (req, reply, session) => {
      const p = await owned(
        db,
        "backup_previews",
        req.owner,
        req.params.id,
        session,
      );
      fail(
        p.kind === "erase" && p.expiresAt > now() && !p.usedAt,
        "PREVIEW_EXPIRED",
        "Preview hết hạn hoặc đã dùng.",
      );
      for (const c of [
        ...financialCollections,
        "audit_events",
        "import_jobs",
        "api_requests",
        "backup_previews",
      ])
        await db.collection(c).deleteMany({ userId: req.owner }, { session });
      await db
        .collection("users")
        .updateOne(
          { _id: req.owner },
          {
            $set: {
              nextPayday: null,
              settings: { hideAmounts: false, reviewDelayDays: I(7) },
              updatedAt: now(),
            },
            $inc: { tokenVersion: I(1) },
          },
          { session },
        );
      return { erased: true, loginRequired: true };
    },
  );
}
