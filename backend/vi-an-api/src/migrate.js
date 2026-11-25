import vm from "node:vm";
import { readFile } from "node:fs/promises";
import { ObjectId, Long, Int32 } from "mongodb";
import { backfillReflections } from "./ledger.js";
export async function initialize(db, { seed = false } = {}) {
  const commands = [];
  const fake = new Proxy(
    {
      getCollectionNames: () => [],
      createCollection: (name, options) =>
        commands.push(["collection", name, options]),
      getCollection: () => ({ countDocuments: () => 0 }),
    },
    {
      get: (t, k) =>
        k in t
          ? t[k]
          : {
              createIndex: (key, options) =>
                commands.push(["index", k, key, options]),
              countDocuments: () => 0,
              insertOne: (doc) => commands.push(["insert", k, [doc]]),
              insertMany: (docs) => commands.push(["insert", k, docs]),
            },
    },
  );
  const context = {
    db: { getSiblingDB: () => fake },
    ObjectId: (s) => new ObjectId(s),
    NumberLong: (s) => Long.fromString(s),
    NumberInt: (n) => new Int32(n),
    print: () => {},
    Date,
  };
  vm.runInNewContext(
    await readFile(
      new URL("../database/01-schema.js", import.meta.url),
      "utf8",
    ),
    context,
  );
  const names = (
    await db.listCollections({}, { nameOnly: true }).toArray()
  ).map((c) => c.name);
  for (const [op, name, a, b] of commands) {
    if (op === "collection") {
      if (name === "users") {
        a.validator.$jsonSchema.required =
          a.validator.$jsonSchema.required.filter((k) => k !== "nextPayday");
        a.validator.$jsonSchema.properties.nextPayday = {
          bsonType: ["date", "null"],
        };
      }
      if (names.includes(name)) await db.command({ collMod: name, ...a });
      else await db.createCollection(name, a);
    } else if (op === "index") await db.collection(name).createIndex(a, b);
  }
  for (const name of [
    "auth_accounts",
    "password_reset_otps",
    "api_requests",
    "audit_events",
    "import_jobs",
    "backup_previews",
    "attachments",
  ])
    if (!names.includes(name))
      await db.createCollection(name).catch((e) => {
        if (e.code !== 48) throw e;
      });
  await db
    .collection("auth_accounts")
    .createIndex({ email: 1 }, { unique: true });
  await db
    .collection("auth_accounts")
    .createIndex({ userId: 1 }, { unique: true });
  await db
    .collection("password_reset_otps")
    .createIndex({ email: 1, createdAt: -1 });
  await db
    .collection("password_reset_otps")
    .createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
  await db
    .collection("api_requests")
    .createIndex({ userId: 1, key: 1 }, { unique: true });
  await db.collection("audit_events").createIndex({ userId: 1, createdAt: -1 });
  await db
    .collection("import_jobs")
    .createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
  await db
    .collection("backup_previews")
    .createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
  if (seed) {
    for (const name of ["users", "wallets", "transactions"])
      if (await db.collection(name).countDocuments({}))
        throw new Error(
          "Seed refused: database already has users/wallets/transactions.",
        );
    commands.length = 0;
    vm.runInNewContext(
      await readFile(
        new URL("../database/02-seed.js", import.meta.url),
        "utf8",
      ),
      context,
    );
    for (const [op, name, docs] of commands)
      if (op === "insert") await db.collection(name).insertMany(docs);
  }
  // Nhật ký Đáng tiền là cơ chế tự động: bổ sung bản ghi cho mọi giao dịch chi
  // đã tồn tại (dữ liệu cũ, dữ liệu nhập CSV, khôi phục bản sao). Idempotent.
  for await (const user of db.collection("users").find({}, { projection: { _id: 1 } }))
    await backfillReflections(db, user._id);
}
