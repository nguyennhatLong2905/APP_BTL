import test from "node:test";
import assert from "node:assert/strict";
import { MongoClient } from "mongodb";
import { buildApp } from "../src/app.js";
import { initialize } from "../src/migrate.js";

const mongoUri = process.env.MONGODB_URI || "mongodb://127.0.0.1:27017/";

test("forgot-password -> verify-reset-otp -> reset-password end-to-end flow", async (t) => {
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

  const dbName = `vi_an_forgot_pw_test_${Date.now()}`;
  const db = client.db(dbName);
  const sentEmails = [];
  let app;

  t.after(async () => {
    await app?.close();
    await db.dropDatabase().catch(() => {});
    await client.close();
  });

  await initialize(db);
  app = await buildApp(
    {
      client,
      db,
      transactionCapable: false,
      backupSecret: "test-secret-at-least-32-characters-long",
    },
    {
      allowDemo: false,
      jwtSecret: "test-secret-at-least-32-characters-long",
      sendOtp: async ({ to, otp, displayName }) => {
        sentEmails.push({ to, otp, displayName });
        return { delivered: "mock" };
      },
    },
  );

  const email = "otp-test@example.com";
  const initialPassword = "oldPassword12345";
  const newPassword = "newPassword12345";

  // 1. Register user
  const regRes = await app.inject({
    method: "POST",
    url: "/api/v1/auth/register",
    payload: {
      email,
      password: initialPassword,
      displayName: "Tester",
    },
  });
  assert.equal(regRes.statusCode, 200, regRes.body);
  const oldToken = regRes.json().data.accessToken;

  // 2. Request OTP for unknown email -> 404
  const notFoundRes = await app.inject({
    method: "POST",
    url: "/api/v1/auth/forgot-password",
    payload: { email: "missing@example.com" },
  });
  assert.equal(notFoundRes.statusCode, 404);

  // 3. Request OTP -> 200 and captures 6-digit OTP
  const forgotRes = await app.inject({
    method: "POST",
    url: "/api/v1/auth/forgot-password",
    payload: { email },
  });
  assert.equal(forgotRes.statusCode, 200, forgotRes.body);
  assert.equal(sentEmails.length, 1);
  assert.match(sentEmails[0].otp, /^\d{6}$/);

  // 4. Cooldown blocks immediate resend -> 429
  const cooldownRes = await app.inject({
    method: "POST",
    url: "/api/v1/auth/forgot-password",
    payload: { email },
  });
  assert.equal(cooldownRes.statusCode, 429);

  // 5. Wrong OTP -> 400 with remaining attempts
  const wrongOtp = sentEmails[0].otp === "000000" ? "111111" : "000000";
  const wrongOtpRes = await app.inject({
    method: "POST",
    url: "/api/v1/auth/verify-reset-otp",
    payload: { email, otp: wrongOtp },
  });
  assert.equal(wrongOtpRes.statusCode, 400);
  assert.equal(wrongOtpRes.json().error.code, "INVALID_OTP");

  // 6. Correct OTP -> 200 and returns resetToken
  const verifyRes = await app.inject({
    method: "POST",
    url: "/api/v1/auth/verify-reset-otp",
    payload: { email, otp: sentEmails[0].otp },
  });
  assert.equal(verifyRes.statusCode, 200, verifyRes.body);
  const { resetToken } = verifyRes.json().data;
  assert.ok(resetToken && resetToken.length >= 32);

  // 7. Reset with same password -> 400 SAME_PASSWORD
  const samePwRes = await app.inject({
    method: "POST",
    url: "/api/v1/auth/reset-password",
    payload: { email, resetToken, newPassword: initialPassword },
  });
  assert.equal(samePwRes.statusCode, 400);
  assert.equal(samePwRes.json().error.code, "SAME_PASSWORD");

  // 8. Reset with new password -> 200
  const resetRes = await app.inject({
    method: "POST",
    url: "/api/v1/auth/reset-password",
    payload: { email, resetToken, newPassword },
  });
  assert.equal(resetRes.statusCode, 200, resetRes.body);
  assert.equal(resetRes.json().data.reset, true);

  // 9. Reusing same resetToken fails -> 400
  const reuseRes = await app.inject({
    method: "POST",
    url: "/api/v1/auth/reset-password",
    payload: { email, resetToken, newPassword: "anotherPassword999" },
  });
  assert.equal(reuseRes.statusCode, 400);

  // 10. Old JWT is invalidated due to tokenVersion increment -> 401
  const meOldRes = await app.inject({
    method: "GET",
    url: "/api/v1/me",
    headers: { authorization: `Bearer ${oldToken}` },
  });
  assert.equal(meOldRes.statusCode, 401);

  // 11. Old password no longer works, new password logs in -> 200
  const oldLoginRes = await app.inject({
    method: "POST",
    url: "/api/v1/auth/login",
    payload: { email, password: initialPassword },
  });
  assert.equal(oldLoginRes.statusCode, 401);

  const newLoginRes = await app.inject({
    method: "POST",
    url: "/api/v1/auth/login",
    payload: { email, password: newPassword },
  });
  assert.equal(newLoginRes.statusCode, 200, newLoginRes.body);
});

