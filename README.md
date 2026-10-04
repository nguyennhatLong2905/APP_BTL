# 📊 EXPENSE TRACKER APP — QUẢN LÝ CHI TIÊU CÁ NHÂN

> **Dự án Môn học / Đồ án Phát triển Ứng dụng Di động**  
> **Frontend:** Flutter (Dart) | **State Management:** Riverpod 3.x | **Network:** Dio | **Router:** GoRouter  
> **Backend Integration:** NestJS (TypeScript) + MongoDB (NoSQL)  
> **Kiến trúc:** Clean Architecture (Feature-First)

---

## 📌 1. GIỚI THIỆU DỰ ÁN (PROJECT OVERVIEW)

**Expense Tracker App** là ứng dụng di động hỗ trợ quản lý tài chính cá nhân toàn diện, giúp người dùng theo dõi các khoản thu/chi, phân loại danh mục chi tiêu, quản lý ví tài khoản và xem báo cáo phân tích trực quan.

Dự án được xây dựng trên nền tảng **Flutter** chuẩn **Clean Architecture**, tách biệt rõ ràng các tầng nghiệp vụ (`Domain`, `Data`, `Presentation`), đảm bảo khả năng mở rộng (Scalability), dễ kiểm thử (Testability) và thuận tiện cho công tác làm việc nhóm (Team Collaboration).

---

## 👥 2. ĐỘI NGŨ PHÁT TRIỂN & PHÂN CÔNG CÔNG VIỆC (TEAM & ROLES)

| Vai trò | Thành viên | Nhiệm vụ chính (Sprint 1) | Branch phụ trách |
| :--- | :--- | :--- | :--- |
| **Tech Lead / Architect** | `nguyennhatLong2905` | Thiết lập Clean Architecture Base, Dio Network, Helper MongoDB, UI Kit dùng chung | `main` |
| **Frontend Developer 1** | FE 1 (`Ducdao` / `Linhleve` / `Tuan Hai`) | Module `Auth` (Đăng nhập, Đăng ký), Secure Storage JWT Token, Router Guard | `feature/auth-and-storage` |
| **Frontend Developer 2** | FE 2 (`Ducdao` / `Linhleve` / `Tuan Hai`) | Dashboard tổng quan, Form Thêm Thu/Chi, Currency Formatting, Transaction Model | `feature/transaction-and-dashboard` |

---

## 🏗️ 3. KIẾN TRÚC & CÔNG NGHỆ (ARCHITECTURE & TECH STACK)

### 🛠️ Tech Stack Chi Tiết
- **Framework:** Flutter (Dart SDK >= 3.10)
- **State Management:** Flutter Riverpod 3.x (`riverpod_annotation`, `NotifierProvider`)
- **Navigation:** GoRouter (Hỗ trợ Router Redirect Guard khi chưa Đăng nhập)
- **Network Client:** Dio 5.x + Interceptors (Auth Token Interceptor, Error Interceptor, Log Interceptor)
- **Secure Storage:** `flutter_secure_storage` (Lưu vết JWT Token an toàn)
- **Backend Interop:** NestJS REST API + MongoDB Mongoose (`MongoDbHelper` tự động mapper `_id` -> `id` & parse thời gian ISO 8601)

### 📂 Cấu Trúc Thư Mục (Feature-First Clean Architecture)
```
lib/
├── core/                       # Thành phần dùng chung (Shared Kernel)
│   ├── network/                # EnvConfig, AuthInterceptor, ErrorInterceptor, MongoDbHelper
│   ├── storage/                # LocalStorageService, SecureStorageService
│   ├── theme/                  # AppTheme (Color Palette chuyên dụng Thu/Chi)
│   ├── widgets/                # Bộ UI Kit (CurrencyTextField, PrimaryButton, LoadingDialog, AppSnackBar)
│   └── router/                 # GoRouter Config & Locale Awareness
├── features/                   # Các Module tính năng (Feature-First)
│   ├── auth/                   # [FE 1] Đăng nhập, Đăng ký, Quản lý tài khoản
│   ├── transaction/            # [FE 2] Quản lý Thu/Chi, Hóa đơn
│   ├── wallet/                 # Quản lý Ví & Tài khoản ngân hàng
│   └── report/                 # Báo cáo thống kê & Biểu đồ
├── main.dart                   # Entry Point ứng dụng
└── ...
```

---

## ⚡ 4. HƯỚNG DẪN KHỞI CHẠY DỰ ÁN (GETTING STARTED)

### Yêu cầu môi trường (Prerequisites)
- Flutter SDK: `>= 3.10.0`
- Dart SDK: `>= 3.0.0`
- Android Studio / VS Code (đã cài Flutter & Dart Extensions)

### Các bước cài đặt & chạy ứng dụng

```bash
# 1. Clone repository về máy
git clone https://github.com/nguyennhatLong2905/APP_BTL.git

# 2. Di chuyển vào thư mục dự án
cd APP_BTL

# 3. Tải các package dependencies
flutter pub get

# 4. Khởi chạy ứng dụng (trên Android Emulator / iOS Simulator / Device)
flutter run
```

---

## 🔄 5. QUY TRÌNH LÀM VIỆC VỚI GIT (GIT WORKFLOW FOR TEAM)

Để đảm bảo nguồn code trên branch `main` luôn hoạt động ổn định và không xảy ra xung đột (Conflict):

1. **Tuyệt đối không push trực tiếp lên branch `main`**.
2. **Tạo branch riêng cho từng tính năng:**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/<ten-tinh-nang>
   ```
3. **Commit code theo chuẩn Conventional Commits:**
   - `feat:` Thêm tính năng mới (Ví dụ: `feat: implement login screen`)
   - `fix:` Sửa lỗi (Ví dụ: `fix: currency input textfield format`)
   - `style:` Cập nhật UI / Theme
   - `docs:` Cập nhật tài liệu
4. **Tạo Pull Request (PR):**
   - Khi hoàn thành tính năng, push branch lên GitHub và gửi **Pull Request (PR)** vào branch `main`.
   - Tech Lead review code trước khi phê duyệt gộp code (Merge).

---

## 🧪 6. KIỂM THỬ (TESTING)

```bash
# Chạy toàn bộ Unit Tests & Widget Tests
flutter test
```

---

## 📄 7. GIẤY PHÉP (LICENSE)

Dự án được phát triển dưới giấy phép [MIT License](LICENSE).
