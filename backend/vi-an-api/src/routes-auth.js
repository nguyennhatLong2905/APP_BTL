import { ObjectId } from "mongodb";
import {
  base,
  I,
  L,
  now,
  fail,
  passwordHash,
  passwordMatches,
  owned,
} from "./common.js";
import * as S from "./schemas.js";
export function authRoutes(app, ctx, config, r) {
  const db = ctx.db;
  const token = (user) =>
    app.jwt.sign(
      { sub: user._id.toHexString(), ver: Number(user.tokenVersion || 0) },
      { expiresIn: "1d" },
    );
  r(
    "POST",
    "/auth/register",
    {
      publicRoute: true,
      body: S.signup,
      tag: "Auth",
      summary: "Đăng ký tài khoản",
    },
    async (req) => {
      fail(
        ctx.transactionCapable,
        "REPLICA_SET_REQUIRED",
        "Cần replica set để đăng ký.",
        503,
      );
      const b = req.input,
        email = b.email.toLowerCase(),
        encoded = passwordHash(b.password),
        session = ctx.client.startSession();
      let user;
      try {
        await session.withTransaction(async () => {
          user = {
            _id: new ObjectId(),
            authSubject: "local:" + email,
            displayName: b.displayName,
            timezone: "Asia/Ho_Chi_Minh",
            currency: "VND",
            nextPayday: b.nextPayday ? new Date(b.nextPayday) : null,
            settings: { hideAmounts: false, reviewDelayDays: I(7) },
            tokenVersion: I(0),
            createdAt: now(),
            updatedAt: now(),
          };
          await db.collection("users").insertOne(user, { session });
          await db
            .collection("auth_accounts")
            .insertOne(
              { ...base(user._id), email, passwordHash: encoded },
              { session },
            );
          for (const [name, kind] of [
            ["Ăn uống", "expense"],
            ["Đi lại", "expense"],
            ["Mua sắm", "expense"],
            ["Hóa đơn", "expense"],
            ["Học tập", "expense"],
            ["Khác", "expense"],
            ["Thu nhập", "income"],
          ])
            await db
              .collection("categories")
              .insertOne(
                { ...base(user._id), name, kind, status: "active" },
                { session },
              );
        });
      } finally {
        await session.endSession();
      }
      return { accessToken: token(user), user };
    },
  );
  r(
    "POST",
    "/auth/login",
    { publicRoute: true, body: S.login, tag: "Auth", summary: "Đăng nhập" },
    async (req) => {
      const a = await db
        .collection("auth_accounts")
        .findOne({ email: req.input.email.toLowerCase() });
      fail(
        a && passwordMatches(req.input.password, a.passwordHash),
        "INVALID_LOGIN",
        "Email hoặc mật khẩu không đúng.",
        401,
      );
      const user = await db.collection("users").findOne({ _id: a.userId });
      fail(user, "INVALID_LOGIN", "Tài khoản không tồn tại.", 401);
      return { accessToken: token(user), user };
    },
  );
  r(
    "POST",
    "/auth/demo",
    {
      publicRoute: true,
      body: S.obj({}),
      tag: "Auth",
      summary: "Token cho dữ liệu An trên máy local",
    },
    async () => {
      fail(
        config.allowDemo === true,
        "DEMO_DISABLED",
        "Đăng nhập demo đang tắt.",
        403,
      );
      const user = await db
        .collection("users")
        .findOne({ authSubject: "demo:an" });
      fail(user, "DEMO_NOT_FOUND", "Chưa có dữ liệu mẫu.", 404);
      return { accessToken: token(user), user };
    },
  );
  r("GET", "/me", { tag: "Profile", summary: "Hồ sơ và thiết lập" }, (req) =>
    db
      .collection("users")
      .findOne(
        { _id: req.owner },
        { projection: { authSubject: 0, apiRevision: 0 } },
      ),
  );
  r(
    "PATCH",
    "/me",
    {
      write: true,
      body: S.profile,
      tag: "Profile",
      summary: "Cập nhật ngày lương, ẩn số tiền và thiết lập",
    },
    async (req, reply, session) => {
      const b = req.input,
        set = { updatedAt: now() };
      if (b.displayName) set.displayName = b.displayName;
      if ("nextPayday" in b)
        set.nextPayday = b.nextPayday ? new Date(b.nextPayday) : null;
      if (b.paydayDay) set.paydayDay = I(b.paydayDay);
      if (b.settings)
        for (const [k, v] of Object.entries(b.settings)) {
          if (k === "defaultWalletId") {
            const w = await owned(db, "wallets", req.owner, v, session);
            fail(w.status === "active", "WALLET_ARCHIVED", "Ví đã lưu trữ.");
            set["settings." + k] = w._id;
          } else
            set["settings." + k] =
              k === "workIncome"
                ? L(v)
                : ["reviewDelayDays", "workHours"].includes(k)
                  ? I(v)
                  : v;
        }
      await db
        .collection("users")
        .updateOne({ _id: req.owner }, { $set: set }, { session });
      return db.collection("users").findOne({ _id: req.owner }, { session });
    },
  );
  r(
    "POST",
    "/auth/logout-all",
    {
      write: true,
      body: S.obj({}),
      tag: "Auth",
      summary: "Thu hồi toàn bộ token",
    },
    async (req, reply, session) => {
      await db
        .collection("users")
        .updateOne(
          { _id: req.owner },
          { $inc: { tokenVersion: I(1) } },
          { session },
        );
      return { revoked: true };
    },
  );
}
