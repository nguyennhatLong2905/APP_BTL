import test from "node:test";
import assert from "node:assert/strict";
import { Long, ObjectId } from "mongodb";
import {
  json,
  daysBetween,
  hash,
  L,
  passwordHash,
  passwordMatches,
  escapeRegex,
} from "../src/common.js";
import { impacts } from "../src/ledger.js";
test("money serialization preserves values above Number.MAX_SAFE_INTEGER", () =>
  assert.equal(json(L("9007199254740993")), "9007199254740993"));
test("payday day count follows Vietnam calendar, not elapsed hours", () =>
  assert.equal(
    daysBetween(
      new Date("2026-10-02T23:30:00+07:00"),
      new Date("2026-10-16T00:00:00+07:00"),
      "Asia/Ho_Chi_Minh",
    ),
    14,
  ));
test("transfer impacts conserve total money", () =>
  assert.equal(
    impacts({
      type: "transfer",
      fromWalletId: new ObjectId(),
      toWalletId: new ObjectId(),
      amount: L(50000),
    }).reduce((s, [, n]) => s + n, 0n),
    0n,
  ));
test("idempotency payload hash is order independent", () =>
  assert.equal(hash({ a: 1, b: 2 }), hash({ b: 2, a: 1 })));
test("password hash verifies without storing plaintext", () => {
  const stored = passwordHash("my-long-password");
  assert(!stored.includes("my-long-password"));
  assert(passwordMatches("my-long-password", stored));
  assert(!passwordMatches("wrong", stored));
});
test("search treats regular expression metacharacters literally", () =>
  assert.equal(new RegExp(escapeRegex("a+b")).test("aaab"), false));
