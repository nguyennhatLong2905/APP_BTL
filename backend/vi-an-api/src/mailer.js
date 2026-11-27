import nodemailer from "nodemailer";
import { ApiError } from "./common.js";

function escapeHtml(text) {
  return String(text ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function getSmtpConfig() {
  const host = process.env.SMTP_HOST?.trim() || "";
  const port = Number(process.env.SMTP_PORT || 587);
  const secure = process.env.SMTP_SECURE?.trim() === "true" || port === 465;
  const user = process.env.SMTP_USER?.trim() || "";
  const pass = process.env.SMTP_PASS?.trim() || "";
  const from =
    process.env.SMTP_FROM?.trim() ||
    (user ? `"Ví An" <${user}>` : '"Ví An" <no-reply@vian.app>');

  return { host, port, secure, user, pass, from };
}

export function isSmtpConfigured() {
  const cfg = getSmtpConfig();
  return Boolean(cfg.host && cfg.user && cfg.pass);
}

/**
 * Gửi email chứa mã OTP đặt lại mật khẩu.
 * Nếu chưa cấu hình SMTP_* trong .env:
 * - Ở môi trường dev/test: in mã OTP ra console server để tiện kiểm thử.
 * - Ở môi trường production: báo lỗi 503 để tránh âm thầm bỏ qua email.
 */
export async function sendPasswordResetOtpEmail({
  to,
  otp,
  displayName,
  expiresMinutes = 10,
  logger,
  purpose = "reset",
}) {
  if (!isSmtpConfigured()) {
    if (purpose === "register" || process.env.NODE_ENV === "production") {
      throw new ApiError(
        503,
        "EMAIL_NOT_CONFIGURED",
        purpose === "register"
          ? "Chưa cấu hình máy chủ gửi email đăng ký. Không thể xác minh Gmail."
          : "Hệ thống chưa cấu hình máy chủ gửi email.",
      );
    }
    const banner = [
      "",
      `================ [Ví An - DEV OTP ${purpose.toUpperCase()} FALLBACK] ================`,
      `Email nhận   : ${to}`,
      `Mã OTP       : ${otp}`,
      `Hiệu lực     : ${expiresMinutes} phút`,
      "Ghi chú      : Chưa cấu hình SMTP_HOST/SMTP_USER/SMTP_PASS trong .env",
      "============================================================",
      "",
    ].join("\n");
    console.info(banner);
    logger?.info({ to, expiresMinutes }, "Dev fallback OTP logged to console");
    return { delivered: "console" };
  }

  const cfg = getSmtpConfig();
  const transporter = nodemailer.createTransport({
    host: cfg.host,
    port: cfg.port,
    secure: cfg.secure,
    auth: {
      user: cfg.user,
      pass: cfg.pass,
    },
    connectionTimeout: 5000,
    greetingTimeout: 5000,
    socketTimeout: 7000,
  });

  const safeName = escapeHtml(displayName || "bạn");
  const safeOtp = escapeHtml(otp);

  const text = [
    `Xin chào ${displayName || "bạn"},`,
    "",
    purpose === "register"
      ? `Mã OTP xác minh đăng ký Ví An của bạn là: ${otp}`
      : `Mã OTP đặt lại mật khẩu Ví An của bạn là: ${otp}`,
    `Mã có hiệu lực trong ${expiresMinutes} phút.`,
    "",
    "Vui lòng không chia sẻ mã này cho bất kỳ ai. Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này.",
  ].join("\n");

  const html = `
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; max-width: 520px; margin: 0 auto; padding: 24px; background: #f5faf9; border-radius: 16px;">
      <div style="background: #ffffff; border-radius: 12px; padding: 28px; border: 1px solid #e3efec;">
          <h2 style="margin: 0 0 12px; color: #0f5b47; font-size: 20px;">${purpose === "register" ? "Xác minh đăng ký Ví An" : "Đặt lại mật khẩu Ví An"}</h2>
        <p style="margin: 0 0 16px; color: #333333; font-size: 14px; line-height: 1.6;">
          Xin chào <strong>${safeName}</strong>,
        </p>
        <p style="margin: 0 0 16px; color: #333333; font-size: 14px; line-height: 1.6;">
          ${purpose === "register" ? "Đây là mã xác minh (OTP) để hoàn tất đăng ký tài khoản Ví An của bạn:" : "Đây là mã xác minh (OTP) để đặt lại mật khẩu tài khoản Ví An của bạn:"}
        </p>
        <div style="margin: 20px 0; padding: 16px; background: #eaf8f5; border: 1px dashed #2c7873; border-radius: 10px; text-align: center;">
          <span style="font-size: 30px; font-weight: 800; letter-spacing: 8px; color: #0f5b47;">${safeOtp}</span>
        </div>
        <p style="margin: 0 0 12px; color: #555555; font-size: 13px; line-height: 1.5;">
          Mã có hiệu lực trong <strong>${expiresMinutes} phút</strong>. Tuyệt đối không chia sẻ mã này cho bất kỳ ai.
        </p>
        <p style="margin: 0; color: #888888; font-size: 12px; line-height: 1.5;">
          Nếu bạn không thực hiện yêu cầu này, bạn có thể bỏ qua email này một cách an toàn.
        </p>
      </div>
    </div>
  `;

  try {
    const info = await transporter.sendMail({
      from: cfg.from,
      to,
      subject: `[Ví An] ${purpose === "register" ? "Mã xác minh đăng ký" : "Mã xác minh đặt lại mật khẩu"}: ${otp}`,
      text,
      html,
    });
    logger?.info({
      to,
      messageId: info.messageId,
      response: info.response,
      purpose,
    }, "OTP email delivered to SMTP");
    return { delivered: "smtp" };
  } catch (err) {
    logger?.error({ err, to }, "Failed to send password reset OTP email");
    throw new ApiError(
      502,
      "EMAIL_SEND_FAILED",
      "Không thể gửi email xác minh. Vui lòng kiểm tra cấu hình SMTP hoặc thử lại sau.",
    );
  }
}

