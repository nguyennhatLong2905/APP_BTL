import {
  createHash,
  createHmac,
  randomBytes,
  randomInt,
  timingSafeEqual,
} from "node:crypto";
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
import { sendPasswordResetOtpEmail } from "./mailer.js";
import * as S from "./schemas.js";
export function authRoutes(app, ctx, config, r) {
  const db = ctx.db;
  const otpSecret = config.jwtSecret || "vi-an-dev-otp-secret";
  const otpTtlMs = 10 * 60 * 1000;
  const otpCooldownMs = 60 * 1000;
  const maxOtpAttempts = 5;
  const hashOtp = (email, salt, otp) =>
    createHmac("sha256", otpSecret)
      .update(`${email}:${salt}:${otp}`)
      .digest("hex");
  const sha256Hex = (value) =>
    createHash("sha256").update(value).digest("hex");
  const safeHexEqual = (a, b) => {
    if (typeof a !== "string" || typeof b !== "string" || a.length !== b.length)
      return false;
    return timingSafeEqual(Buffer.from(a, "hex"), Buffer.from(b, "hex"));
  };
  const sendOtp = config.sendOtp || sendPasswordResetOtpEmail;
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
      const b = req.input,
        email = b.email.toLowerCase(),
        encoded = passwordHash(b.password);

      // Từ chối sớm khi email đã đăng ký, tránh lỗi E11000 thô từ Mongo
      const existing = await db
        .collection("users")
        .findOne({ authSubject: "local:" + email }, { projection: { _id: 1 } });
      fail(
        !existing,
        "EMAIL_EXISTS",
        "Email này đã được đăng ký. Dùng đăng nhập hoặc email khác.",
        409,
      );

      let user;
      const doInsert = async (opts) => {
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
        await db.collection("users").insertOne(user, opts);
        await db
          .collection("auth_accounts")
          .insertOne(
            { ...base(user._id), email, passwordHash: encoded },
            opts
          );
        for (const [name, kind] of [
          ["Ăn uống", "expense"],
          ["Đi lại", "expense"],
          ["Mua sắm", "expense"],
          ["Hóa đơn", "expense"],
          ["Học tập", "expense"],
          ["Khác", "expense"],
          ["Thu nhập", "income"],
        ]) {
          await db
            .collection("categories")
            .insertOne(
              { ...base(user._id), name, kind, status: "active" },
              opts
            );
        }
      };

      const insert = async () => {
        if (ctx.transactionCapable) {
          const session = ctx.client.startSession();
          try {
            await session.withTransaction(() => doInsert({ session }));
          } finally {
            await session.endSession();
          }
        } else {
          // Fallback: Chạy bình thường không cần Transaction khi Dev ở Local
          await doInsert({});
        }
      };

      try {
        await insert();
      } catch (e) {
        // Hai request trùng email cùng lúc vượt qua check đầu
        if (e.code === 11000 || e.code === 121)
          fail(
            false,
            "EMAIL_EXISTS",
            "Email này đã được đăng ký. Dùng đăng nhập hoặc email khác.",
            409,
          );
        throw e;
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
  r(
    "POST",
    "/auth/change-password",
    {
      body: S.changePassword,
      tag: "Auth",
      summary: "Đổi mật khẩu",
    },
    async (req) => {
      const { currentPassword, newPassword } = req.input;

      // Lấy auth_account của user hiện tại
      const authAccount = await db
        .collection("auth_accounts")
        .findOne({ userId: req.owner });
      fail(authAccount, "ACCOUNT_NOT_FOUND", "Tài khoản không tồn tại.", 404);

      // Kiểm tra mật khẩu hiện tại
      fail(
        passwordMatches(currentPassword, authAccount.passwordHash),
        "WRONG_PASSWORD",
        "Mật khẩu hiện tại không đúng.",
        401,
      );

      // Không cho đặt lại mật khẩu giống cũ
      fail(
        !passwordMatches(newPassword, authAccount.passwordHash),
        "SAME_PASSWORD",
        "Mật khẩu mới phải khác mật khẩu hiện tại.",
        400,
      );

      // Hash mật khẩu mới và cập nhật auth_accounts
      const newHash = passwordHash(newPassword);
      await db
        .collection("auth_accounts")
        .updateOne(
          { _id: authAccount._id },
          { $set: { passwordHash: newHash, updatedAt: now() } },
        );

      // Tăng tokenVersion → invalidate toàn bộ JWT cũ
      await db
        .collection("users")
        .updateOne(
          { _id: req.owner },
          { $inc: { tokenVersion: I(1) }, $set: { updatedAt: now() } },
        );

      // Lấy user mới nhất để ký token mới
      const user = await db
        .collection("users")
        .findOne({ _id: req.owner });

      return { accessToken: token(user) };
    },
  );
  r(
    "POST",
    "/auth/forgot-password",
    {
      publicRoute: true,
      body: S.forgotPassword,
      tag: "Auth",
      summary: "Gửi mã OTP đặt lại mật khẩu qua email",
    },
    async (req) => {
      const email = req.input.email.toLowerCase();
      const authAccount = await db.collection("auth_accounts").findOne({ email });
      fail(
        authAccount,
        "EMAIL_NOT_FOUND",
        "Không tìm thấy tài khoản với email này.",
        404,
      );
      const user = await db
        .collection("users")
        .findOne({ _id: authAccount.userId });
      fail(user, "EMAIL_NOT_FOUND", "Tài khoản không tồn tại.", 404);

      const currentTime = now();
      const cooldownCutoff = new Date(currentTime.getTime() - otpCooldownMs);
      const recent = await db.collection("password_reset_otps").findOne(
        { email, usedAt: null, createdAt: { $gt: cooldownCutoff } },
        { sort: { createdAt: -1 } },
      );
      if (recent) {
        const waitSeconds = Math.max(
          1,
          Math.ceil(
            (recent.createdAt.getTime() + otpCooldownMs - currentTime.getTime()) /
              1000,
          ),
        );
        fail(
          false,
          "OTP_COOLDOWN",
          `Vui lòng đợi ${waitSeconds} giây trước khi gửi lại mã OTP.`,
          429,
        );
      }

      const otp = String(randomInt(100000, 1000000));
      const salt = randomBytes(16).toString("hex");
      const otpHash = hashOtp(email, salt, otp);
      const otpExpiresAt = new Date(currentTime.getTime() + otpTtlMs);

      await db
        .collection("password_reset_otps")
        .deleteMany({ email, usedAt: null });

      const otpDoc = {
        _id: new ObjectId(),
        email,
        userId: user._id,
        salt,
        otpHash,
        attempts: I(0),
        otpExpiresAt,
        expiresAt: otpExpiresAt,
        verifiedAt: null,
        resetTokenHash: null,
        resetTokenExpiresAt: null,
        usedAt: null,
        createdAt: currentTime,
        updatedAt: currentTime,
      };
      await db.collection("password_reset_otps").insertOne(otpDoc);

      let delivery;
      try {
        delivery = await sendOtp({
          to: email,
          otp,
          displayName: user.displayName,
          expiresMinutes: 10,
          logger: app.log,
        });
      } catch (err) {
        await db
          .collection("password_reset_otps")
          .deleteOne({ _id: otpDoc._id });
        throw err;
      }

      return {
        sent: true,
        email,
        expiresInSeconds: Math.floor(otpTtlMs / 1000),
        resendAfterSeconds: Math.floor(otpCooldownMs / 1000),
        deliveryChannel: delivery?.delivered || "smtp",
      };
    },
  );
  r(
    "POST",
    "/auth/verify-reset-otp",
    {
      publicRoute: true,
      body: S.verifyResetOtp,
      tag: "Auth",
      summary: "Xác minh mã OTP đặt lại mật khẩu",
    },
    async (req) => {
      const email = req.input.email.toLowerCase();
      const otp = req.input.otp;
      const currentTime = now();

      const record = await db
        .collection("password_reset_otps")
        .findOne({ email, usedAt: null }, { sort: { createdAt: -1 } });

      fail(
        record && record.otpExpiresAt > currentTime,
        "OTP_EXPIRED",
        "Mã OTP không hợp lệ hoặc đã hết hạn. Vui lòng gửi lại mã mới.",
        400,
      );

      const attempts = Number(record.attempts || 0);
      fail(
        attempts < maxOtpAttempts,
        "OTP_TOO_MANY_ATTEMPTS",
        "Bạn đã nhập sai OTP quá 5 lần. Vui lòng gửi lại mã mới.",
        429,
      );

      const expectedHash = hashOtp(email, record.salt, otp);
      if (!safeHexEqual(expectedHash, record.otpHash)) {
        const nextAttempts = attempts + 1;
        await db.collection("password_reset_otps").updateOne(
          { _id: record._id },
          { $inc: { attempts: I(1) }, $set: { updatedAt: currentTime } },
        );
        const remaining = maxOtpAttempts - nextAttempts;
        if (remaining <= 0) {
          fail(
            false,
            "OTP_TOO_MANY_ATTEMPTS",
            "Bạn đã nhập sai OTP quá 5 lần. Vui lòng gửi lại mã mới.",
            429,
          );
        }
        fail(
          false,
          "INVALID_OTP",
          `Mã OTP không chính xác. Còn ${remaining} lần thử.`,
          400,
        );
      }

      const resetToken = randomBytes(32).toString("hex");
      const resetTokenHash = sha256Hex(resetToken);
      const resetTokenExpiresAt = new Date(currentTime.getTime() + otpTtlMs);

      await db.collection("password_reset_otps").updateOne(
        { _id: record._id },
        {
          $set: {
            verifiedAt: currentTime,
            resetTokenHash,
            resetTokenExpiresAt,
            expiresAt: resetTokenExpiresAt,
            updatedAt: currentTime,
          },
        },
      );

      return {
        verified: true,
        resetToken,
        expiresInSeconds: Math.floor(otpTtlMs / 1000),
      };
    },
  );
  r(
    "POST",
    "/auth/reset-password",
    {
      publicRoute: true,
      body: S.resetPassword,
      tag: "Auth",
      summary: "Đặt lại mật khẩu sau khi xác minh OTP",
    },
    async (req) => {
      const email = req.input.email.toLowerCase();
      const { resetToken, newPassword } = req.input;
      const currentTime = now();
      const resetTokenHash = sha256Hex(resetToken);

      const record = await db.collection("password_reset_otps").findOne(
        {
          email,
          resetTokenHash,
          usedAt: null,
        },
        { sort: { createdAt: -1 } },
      );

      fail(
        record &&
          record.verifiedAt &&
          record.resetTokenExpiresAt &&
          record.resetTokenExpiresAt > currentTime,
        "INVALID_RESET_TOKEN",
        "Phiên đặt lại mật khẩu không hợp lệ hoặc đã hết hạn. Vui lòng xác minh lại OTP.",
        400,
      );

      const authAccount = await db
        .collection("auth_accounts")
        .findOne({ userId: record.userId });
      fail(authAccount, "ACCOUNT_NOT_FOUND", "Tài khoản không tồn tại.", 404);

      fail(
        !passwordMatches(newPassword, authAccount.passwordHash),
        "SAME_PASSWORD",
        "Mật khẩu mới phải khác mật khẩu hiện tại.",
        400,
      );

      const newHash = passwordHash(newPassword);
      await db.collection("auth_accounts").updateOne(
        { _id: authAccount._id },
        { $set: { passwordHash: newHash, updatedAt: currentTime } },
      );

      await db.collection("users").updateOne(
        { _id: record.userId },
        { $inc: { tokenVersion: I(1) }, $set: { updatedAt: currentTime } },
      );

      await db.collection("password_reset_otps").updateMany(
        { email, usedAt: null },
        {
          $set: {
            usedAt: currentTime,
            resetTokenHash: null,
            updatedAt: currentTime,
          },
        },
      );

      return { reset: true };
    },
  );
}
