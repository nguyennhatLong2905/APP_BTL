import test from "node:test";
import assert from "node:assert/strict";
import { MongoClient, ObjectId } from "mongodb";
import { MongoMemoryReplSet } from "mongodb-memory-server";
import { initialize } from "../src/migrate.js";
import { buildApp } from "../src/app.js";
import { randomUUID } from "node:crypto";
import { L } from "../src/common.js";
import { mkdir, writeFile } from "node:fs/promises";
const DEMO = "000000000000000000000001",
  CASH = "000000000000000000000002",
  BANK = "000000000000000000000003",
  FOOD = "00000000000000000000000a";
test(
  "API integration with a real ephemeral MongoDB replica set",
  { timeout: 240000 },
  async (t) => {
    const repl = await MongoMemoryReplSet.create({
      binary: {
        version: process.env.MONGOMS_VERSION || "8.0.13",
        downloadDir:
          process.env.MONGOMS_DOWNLOAD_DIR || "/tmp/vi-an-mongodb-binaries",
      },
      replSet: { count: 1 },
    });
    const client = new MongoClient(repl.getUri(), { promoteLongs: false });
    await client.connect();
    const db = client.db("vi_an_test");
    let app;
    t.after(async () => {
      await app?.close();
      await client.close();
      await repl.stop();
    });
    await initialize(db, { seed: true });
    await initialize(db); // Non-destructive migration rerun.
    app = await buildApp(
      {
        client,
        db,
        transactionCapable: true,
        backupSecret: "integration-only-secret",
      },
      {
        allowDemo: true,
        jwtSecret: "integration-only-secret-at-least-32-characters",
      },
    );
    const login = await app.inject({
      method: "POST",
      url: "/api/v1/auth/demo",
      payload: {},
    });
    assert.equal(login.statusCode, 200, login.body);
    let token = login.json().data.accessToken;
    async function call(
      method,
      url,
      body,
      key = randomUUID(),
      tok = token,
      expected = 200,
    ) {
      const response = await app.inject({
        method,
        url: "/api/v1" + url,
        headers: { authorization: "Bearer " + tok, "idempotency-key": key },
        ...(body ? { payload: body } : {}),
      });
      assert.equal(response.statusCode, expected, response.body);
      return response.json().data;
    }
    const entry = {
      type: "expense",
      amount: "50000",
      walletId: CASH,
      categoryId: FOOD,
      occurredAt: new Date().toISOString(),
      note: "Integration breakfast",
      trackReview: true,
    };
    let created;
    await t.test("auth and schema failures are explicit", async () => {
      const unauth = await app.inject({ url: "/api/v1/wallets" });
      assert.equal(unauth.statusCode, 401);
      await call(
        "POST",
        "/transactions",
        { ...entry, amount: 50000 },
        undefined,
        token,
        400,
      );
      const noKey = await app.inject({
        method: "POST",
        url: "/api/v1/transactions",
        headers: { authorization: "Bearer " + token },
        payload: entry,
      });
      assert.equal(noKey.statusCode, 400);
    });
    await t.test("six screen APIs and exact money strings", async () => {
      const o = await call("GET", "/dashboard");
      assert.equal(o.total, "8000000");
      assert.equal(o.available, "2100000");
      await mkdir(new URL("../examples/", import.meta.url), {
        recursive: true,
      });
      const save = (name, data) =>
        writeFile(
          new URL("../examples/" + name + ".json", import.meta.url),
          JSON.stringify({ data }, null, 2) + "\n",
        );
      await save("dashboard", o);
      for (const [name, path] of [
        ["add-transaction", "/screens/add-transaction"],
        ["transactions", "/screens/transactions?limit=3"],
        ["plans", "/screens/plans"],
        [
          "review",
          "/screens/review?startAt=2026-09-25T00%3A00%3A00%2B07%3A00&endAt=2026-10-02T00%3A00%3A00%2B07%3A00",
        ],
      ])
        await save(name, await call("GET", path));
      const sim = await call("POST", "/simulations/purchase", {
        price: "900000",
      });
      assert.equal(sim.availableAfter, "1200000");
      await save("purchase-simulation", sim);
    });
    await t.test(
      "create expense, duplicate retry, conflict and balance",
      async () => {
        created = await call(
          "POST",
          "/transactions",
          entry,
          "expense-create-001",
        );
        const retry = await call(
          "POST",
          "/transactions",
          entry,
          "expense-create-001",
        );
        assert.equal(retry._id, created._id);
        await call(
          "POST",
          "/transactions",
          { ...entry, amount: "60000" },
          "expense-create-001",
          token,
          409,
        );
        assert.equal(
          (
            await db.collection("wallets").findOne({ _id: new ObjectId(CASH) })
          ).balance.toString(),
          "550000",
        );
        assert.equal(
          await db
            .collection("reflections")
            .countDocuments({ transactionId: new ObjectId(created._id) }),
          1,
        );
      },
    );
    await t.test(
      "edit, stale version, void and undo remain balanced",
      async () => {
        const edit = await call("PUT", "/transactions/" + created._id, {
          ...entry,
          amount: "80000",
          expectedVersion: 1,
        });
        assert.equal(edit.version, 2);
        await call(
          "POST",
          "/transactions/" + created._id + "/void",
          { expectedVersion: 1 },
          undefined,
          token,
          409,
        );
        const voided = await call(
          "POST",
          "/transactions/" + created._id + "/void",
          { expectedVersion: 2 },
        );
        assert.equal(voided.status, "voided");
        assert.equal(
          (
            await db.collection("wallets").findOne({ _id: new ObjectId(CASH) })
          ).balance.toString(),
          "600000",
        );
        await call("POST", "/transactions/" + created._id + "/restore", {
          expectedVersion: 3,
        });
        assert.equal(
          (
            await db.collection("wallets").findOne({ _id: new ObjectId(CASH) })
          ).balance.toString(),
          "520000",
        );
      },
    );
    await t.test(
      "parallel spending does not overdraw and a transfer conserves total",
      async () => {
        const before = (await call("GET", "/dashboard")).total;
        await call("POST", "/transactions", {
          type: "transfer",
          amount: "100000",
          fromWalletId: BANK,
          toWalletId: CASH,
          occurredAt: new Date().toISOString(),
        });
        assert.equal((await call("GET", "/dashboard")).total, before);
        const results = await Promise.all(
          [1, 2].map((n) =>
            app.inject({
              method: "POST",
              url: "/api/v1/transactions",
              headers: {
                authorization: "Bearer " + token,
                "idempotency-key": "parallel-spend-" + n,
              },
              payload: { ...entry, amount: "400000" },
            }),
          ),
        );
        assert.deepEqual(results.map((x) => x.statusCode).sort(), [200, 409]);
      },
    );
    await t.test(
      "bill payment releases reservation and void restores it",
      async () => {
        const before = (await call("GET", "/dashboard")).available;
        const tx = await call("POST", "/bills/00000000000000000000019a/pay", {
          walletId: BANK,
          occurredAt: new Date().toISOString(),
        });
        assert.equal((await call("GET", "/dashboard")).available, before);
        await call(
          "POST",
          "/bills/00000000000000000000019a/pay",
          { walletId: BANK, occurredAt: new Date().toISOString() },
          undefined,
          token,
          409,
        );
        await call("POST", "/transactions/" + tx._id + "/void", {
          expectedVersion: 1,
        });
        assert.equal((await call("GET", "/dashboard")).available, before);
      },
    );
    await t.test(
      "allocated money cannot be spent or over-allocated",
      async () => {
        const p = await call("POST", "/goals", {
          name: "Cash reserve",
          targetAmount: "1000000",
          protect: true,
        });
        await call("PUT", "/goals/" + p._id + "/allocation", {
          walletId: CASH,
          amount: "200000",
        });
        await call(
          "POST",
          "/transactions",
          { ...entry, amount: "50000" },
          undefined,
          token,
          409,
        );
        await call(
          "PUT",
          "/goals/" + p._id + "/allocation",
          { walletId: CASH, amount: "99999999" },
          undefined,
          token,
          409,
        );
        await call("PUT", "/goals/" + p._id + "/allocation", {
          walletId: CASH,
          amount: "0",
        });
      },
    );
    await t.test(
      "one user cannot read or mutate another user wallet",
      async () => {
        const b = await call("POST", "/auth/register", {
          email: "other@example.test",
          password: "a-very-long-password",
          displayName: "Other",
        });
        await call(
          "PATCH",
          "/wallets/" + CASH,
          { name: "Stolen" },
          undefined,
          b.accessToken,
          404,
        );
        await call(
          "POST",
          "/transactions",
          entry,
          undefined,
          b.accessToken,
          404,
        );
      },
    );
    await t.test("CSV preview, commit, repeat, export", async () => {
      const csv =
        "type,amount,occurredAt,walletId,categoryId,note\nincome,10000," +
        new Date().toISOString() +
        "," +
        BANK +
        ",000000000000000000000010,Bonus";
      const j = await call("POST", "/imports/preview", {
        csv,
        mapping: {
          type: "type",
          amount: "amount",
          occurredAt: "occurredAt",
          walletId: "walletId",
          categoryId: "categoryId",
          note: "note",
        },
      });
      assert.equal(j.rows[0].error, null);
      const a = await call("POST", "/imports/" + j._id + "/commit", {
        selectedRows: [0],
      });
      assert.equal(a.imported, 1);
      const b = await call("POST", "/imports/" + j._id + "/commit", {
        selectedRows: [0],
      });
      assert.equal(b.alreadyCommitted, true);
      const response = await app.inject({
        url: "/api/v1/exports/transactions.csv",
        headers: { authorization: "Bearer " + token },
      });
      assert.equal(response.statusCode, 200);
      assert(response.body.includes("Bonus"));
    });
    await t.test(
      "simultaneous retries with one key debit only once",
      async () => {
        const payload = { ...entry, walletId: BANK, amount: "3" };
        const before = (
          await db.collection("wallets").findOne({ _id: new ObjectId(BANK) })
        ).balance.toBigInt();
        const [a, b] = await Promise.all([
          call("POST", "/transactions", payload, "same-key-parallel"),
          call("POST", "/transactions", payload, "same-key-parallel"),
        ]);
        assert.equal(a._id, b._id);
        assert.equal(
          (
            await db.collection("wallets").findOne({ _id: new ObjectId(BANK) })
          ).balance.toBigInt(),
          before - 3n,
        );
      },
    );
    await t.test(
      "receipt upload, owner check and expense attachment",
      async () => {
        const base64 =
          "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jHZkAAAAASUVORK5CYII=";
        const a = await call("POST", "/attachments", {
          filename: "receipt.png",
          mimeType: "image/png",
          base64,
        });
        const media = await app.inject({
          url: a.url,
          headers: { authorization: "Bearer " + token },
        });
        assert.equal(media.statusCode, 200);
        assert.equal(media.rawPayload.toString("base64"), base64);
        const tx = await call("POST", "/transactions", {
          ...entry,
          walletId: BANK,
          amount: "10",
          attachmentIds: [a._id],
        });
        assert.equal(tx.attachments[0].storageKey, a._id);
        await call(
          "POST",
          "/attachments",
          { filename: "bad.png", mimeType: "image/png", base64: "YWJj" },
          undefined,
          token,
          422,
        );
        const other = await call("POST", "/auth/login", {
          email: "other@example.test",
          password: "a-very-long-password",
        });
        await call(
          "GET",
          "/attachments/" + a._id,
          undefined,
          undefined,
          other.accessToken,
          404,
        );
      },
    );
    await t.test(
      "pagination retains whole-day totals and literal search",
      async () => {
        for (const amount of ["11", "13"])
          await call("POST", "/transactions", {
            ...entry,
            walletId: BANK,
            amount,
            note: "pagination+a",
          });
        const a = await call(
          "GET",
          "/screens/transactions?limit=1&search=pagination%2Ba",
        );
        assert.equal(a.items.length, 1);
        assert(a.nextCursor);
        assert.equal(a.groups[0].totalExpense, "24");
        const b = await call(
          "GET",
          "/screens/transactions?limit=1&search=pagination%2Ba&cursor=" +
            a.nextCursor,
        );
        assert.equal(b.groups[0].totalExpense, "24");
        assert.notEqual(a.items[0]._id, b.items[0]._id);
      },
    );
    await t.test(
      "purchase simulation is read-only, saving goal is unallocated, buy and undo",
      async () => {
        const before = await call("GET", "/dashboard");
        const p = await call("POST", "/purchases", {
          name: "Book",
          price: "10000",
          categoryId: FOOD,
        });
        const g = await call("POST", "/purchases/" + p._id + "/saving-plan", {
          targetAt: "2027-01-01T00:00:00+07:00",
          dailySaving: "1000",
        });
        assert.equal(
          await db
            .collection("goal_allocations")
            .countDocuments({ goalId: new ObjectId(g._id) }),
          0,
        );
        await call("POST", "/simulations/purchase", { price: "10000" });
        assert.equal((await call("GET", "/dashboard")).total, before.total);
        const bought = await call("POST", "/purchases/" + p._id + "/buy", {
          walletId: BANK,
          occurredAt: new Date().toISOString(),
        });
        assert.equal(
          (await call("GET", "/purchases/" + p._id)).purchase.status,
          "purchased",
        );
        await call(
          "POST",
          "/transactions/" + bought.transaction._id + "/void",
          { expectedVersion: 1 },
        );
        assert.equal(
          (await call("GET", "/purchases/" + p._id)).purchase.status,
          "waiting",
        );
      },
    );
    await t.test(
      "bill recurrence clamps month end; rescheduling does not recreate original occurrence",
      async () => {
        const template = await call("POST", "/bill-templates", {
          name: "Month end",
          estimatedAmount: "10",
          categoryId: FOOD,
          frequency: "monthly",
          startAt: "2026-12-31T00:00:00+07:00",
        });
        let bills = await db
          .collection("bill_occurrences")
          .find({ templateId: new ObjectId(template._id) })
          .sort({ dueAt: 1 })
          .toArray();
        assert(
          bills.some(
            (b) => b.dueAt.toISOString() === "2027-02-27T17:00:00.000Z",
          ),
        );
        const count = bills.length;
        await call("PATCH", "/bills/" + bills[1]._id, {
          dueAt: "2027-01-30T00:00:00+07:00",
        });
        await call("POST", "/jobs/run", {});
        assert.equal(
          await db
            .collection("bill_occurrences")
            .countDocuments({ templateId: new ObjectId(template._id) }),
          count,
        );
      },
    );
    await t.test(
      "import rolls back all rows if one expense exceeds balance",
      async () => {
        const when = new Date().toISOString(),
          cols = "type,amount,occurredAt,walletId,categoryId,note\n";
        const csv =
          cols +
          `income,10,${when},${BANK},000000000000000000000010,Atomic\nexpense,999999999,${when},${BANK},${FOOD},Atomic`;
        const p = await call("POST", "/imports/preview", {
          csv,
          mapping: {
            type: "type",
            amount: "amount",
            occurredAt: "occurredAt",
            walletId: "walletId",
            categoryId: "categoryId",
            note: "note",
          },
        });
        const before = (await call("GET", "/dashboard")).total;
        await call(
          "POST",
          "/imports/" + p._id + "/commit",
          { selectedRows: [0, 1] },
          undefined,
          token,
          409,
        );
        assert.equal((await call("GET", "/dashboard")).total, before);
        assert.equal(
          await db
            .collection("transactions")
            .countDocuments({ note: "Atomic" }),
          0,
        );
      },
    );
    await t.test(
      "real ratings produce explainable suggestions and require explicit budget confirmation",
      async () => {
        for (let n = 0; n < 5; n++) {
          const tx = await call("POST", "/transactions", {
            ...entry,
            walletId: BANK,
            amount: "1",
          });
          const ref = await db
            .collection("reflections")
            .findOne({ transactionId: new ObjectId(tx._id) });
          await call("PUT", "/reflections/" + ref._id, {
            status: "rated",
            rating: "worth_it",
          });
        }
        const generated = await call("POST", "/insights/generate", {}),
          suggestion = generated.items.find(
            (x) =>
              x.type === "budget_suggestion" && x.action.categoryId === FOOD,
          );
        assert(suggestion);
        assert(suggestion.evidenceTransactionIds.length >= 5);
        await call(
          "POST",
          "/insights/" + suggestion._id + "/apply",
          {},
          undefined,
          token,
          422,
        );
        const plan = (await call("GET", "/budgets")).find(
          (p) =>
            p.status === "active" &&
            p.limits.some((x) => x.categoryId === FOOD),
        );
        const result = await call(
          "POST",
          "/insights/" + suggestion._id + "/apply",
          { budgetId: plan._id, newLimit: "1900000" },
        );
        assert.equal(
          result.budget.limits.find((x) => x.categoryId === FOOD).limit,
          "1900000",
        );
      },
    );
    await t.test(
      "budget threshold notification updates without duplicate records",
      async () => {
        const p = await call("POST", "/budgets", {
          name: "Warning check",
          periodType: "month",
          startAt: "2026-10-01T00:00:00+07:00",
          endAt: "2026-11-01T00:00:00+07:00",
          limits: [{ categoryId: FOOD, limit: "1" }],
        });
        const q = {
          userId: new ObjectId(DEMO),
          entityId: new ObjectId(p._id),
          type: "budget_warning",
        };
        assert.equal(await db.collection("notifications").countDocuments(q), 1);
        await call("POST", "/transactions", {
          ...entry,
          walletId: BANK,
          amount: "1",
        });
        assert.equal(await db.collection("notifications").countDocuments(q), 1);
        await call("POST", "/budgets/" + p._id + "/close", {});
        assert.equal(
          (await db.collection("notifications").findOne(q)).status,
          "cancelled",
        );
      },
    );
    await t.test(
      "empty onboarding and confirmed data erasure are user scoped",
      async () => {
        const other = await call("POST", "/auth/login", {
            email: "other@example.test",
            password: "a-very-long-password",
          }),
          tok = other.accessToken;
        const o = await call("GET", "/dashboard", undefined, undefined, tok);
        assert.equal(o.available, null);
        assert(o.missingData.includes("nextPayday"));
        await call(
          "POST",
          "/wallets",
          {
            name: "Temp",
            type: "cash",
            openingBalance: "20",
            openingAt: new Date().toISOString(),
          },
          undefined,
          tok,
        );
        const before = (await call("GET", "/dashboard")).total,
          p = await call("POST", "/data/erase-preview", {}, undefined, tok);
        await call(
          "POST",
          "/data/" + p.previewId + "/erase",
          { confirmation: "wrong" },
          undefined,
          tok,
          400,
        );
        assert.equal(
          (await call("GET", "/wallets", undefined, undefined, tok)).length,
          1,
        );
        await call(
          "POST",
          "/data/" + p.previewId + "/erase",
          { confirmation: "XOA DU LIEU VI AN" },
          undefined,
          tok,
        );
        assert.equal((await call("GET", "/dashboard")).total, before);
        await call("GET", "/wallets", undefined, undefined, tok, 401);
      },
    );
    await t.test("signed backup preview and restore", async () => {
      const saved = await call("GET", "/backup");
      await call(
        "POST",
        "/backup/preview",
        { ...saved, signature: "0".repeat(64) },
        undefined,
        token,
        422,
      );
      const p = await call("POST", "/backup/preview", saved);
      assert(p.counts.transactions.replacement > 7);
      await call("POST", "/backup/" + p.previewId + "/restore", {
        confirmation: "KHOI PHUC VI AN",
      });
      await call("GET", "/wallets", undefined, undefined, token, 401);
      token = (
        await app.inject({
          method: "POST",
          url: "/api/v1/auth/demo",
          payload: {},
        })
      ).json().data.accessToken;
      await call("GET", "/wallets");
    });
  },
);
