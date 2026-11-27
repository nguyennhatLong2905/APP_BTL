import test from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { MongoClient, ObjectId } from "mongodb";
import { atomic } from "../src/common.js";
import { buildApp } from "../src/app.js";
import { initialize } from "../src/migrate.js";

function createFakeCtx(transactionCapable) {
  const calls = [];
  const userId = new ObjectId();
  const session = {
    withTransaction: async (fn) => {
      calls.push("withTransaction");
      return fn();
    },
    endSession: async () => {
      calls.push("endSession");
    },
  };
  const ctx = {
    transactionCapable,
    client: { startSession: () => session },
    db: {
      collection: (name) => ({
        updateOne: async () => {
          calls.push(`updateOne:${name}`);
          return { matchedCount: 1 };
        },
        findOne: async () => {
          calls.push(`findOne:${name}`);
          return null;
        },
        insertOne: async () => {
          calls.push(`insertOne:${name}`);
          return { insertedId: new ObjectId() };
        },
      }),
    },
  };
  return { ctx, userId, calls };
}

test("atomic uses withTransaction when transactionCapable is true", async () => {
  const { ctx, userId, calls } = createFakeCtx(true);
  const res = await atomic(ctx, userId, "key-1", "POST:/test", { a: 1 }, async () => ({
    ok: true,
  }));
  assert.deepEqual(res, { ok: true });
  assert(calls.includes("withTransaction"));
  assert(calls.includes("endSession"));
});

test("atomic falls back without withTransaction when transactionCapable is false", async () => {
  const { ctx, userId, calls } = createFakeCtx(false);
  const res = await atomic(ctx, userId, "key-2", "POST:/test", { a: 1 }, async () => ({
    ok: true,
  }));
  assert.deepEqual(res, { ok: true });
  assert(!calls.includes("withTransaction"));
  assert(calls.includes("endSession"));
});

const mongoUri = process.env.MONGODB_URI || "mongodb://127.0.0.1:27017/";

test("standalone MongoDB (transactionCapable: false) creates transactions and backups", async (t) => {
  const client = new MongoClient(mongoUri, {
    promoteLongs: false,
    serverSelectionTimeoutMS: 3000,
  });

  try {
    await client.connect();
  } catch (err) {
    t.skip(`Local MongoDB unavailable at ${mongoUri}: ${err.message}`);
    return;
  }

  const db = client.db(`vi_an_standalone_test_${Date.now()}`);
  let app;

  t.after(async () => {
    await app?.close();
    await db.dropDatabase().catch(() => {});
    await client.close();
  });

  await initialize(db, { seed: true });
  app = await buildApp(
    {
      client,
      db,
      transactionCapable: false,
      backupSecret: "test-secret-at-least-32-characters-long",
    },
    {
      allowDemo: true,
      jwtSecret: "test-secret-at-least-32-characters-long",
    },
  );

  const login = await app.inject({
    method: "POST",
    url: "/api/v1/auth/demo",
    payload: {},
  });
  assert.equal(login.statusCode, 200, login.body);
  const token = login.json().data.accessToken;

  const formRes = await app.inject({
    method: "GET",
    url: "/api/v1/screens/add-transaction",
    headers: { authorization: `Bearer ${token}` },
  });
  assert.equal(formRes.statusCode, 200, formRes.body);
  const form = formRes.json().data;
  const wallet = form.wallets[0];
  const category = form.categories.find((c) => c.kind === "expense");

  const txRes = await app.inject({
    method: "POST",
    url: "/api/v1/transactions",
    headers: {
      authorization: `Bearer ${token}`,
      "idempotency-key": randomUUID(),
    },
    payload: {
      type: "expense",
      amount: "50000",
      walletId: wallet._id,
      categoryId: category._id,
      occurredAt: new Date().toISOString(),
      note: "Standalone transaction test",
    },
  });
  assert.equal(txRes.statusCode, 200, txRes.body);

  const backupRes = await app.inject({
    method: "GET",
    url: "/api/v1/backup",
    headers: { authorization: `Bearer ${token}` },
  });
  assert.equal(backupRes.statusCode, 200, backupRes.body);
  assert.ok(backupRes.json().data.payload);
});

