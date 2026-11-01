# 📘 CẨM NANG HƯỚNG DẪN QUY TRÌNH LÀM VIỆC DÀNH CHO DŨNG & LONG

> **Dự án:** Expense Tracker App (Flutter)  
> **Repository:** `https://github.com/nguyennhatLong2905/APP_BTL.git`  
> **Mô hình Git:** `main` ⬅️ `frontend` ⬅️ `long` / `dung`

---

## 🎯 1. TỔNG QUAN HỆ THỐNG CÁC NHÁNH (GIT BRANCHES)

- **`main`**: Nhánh nguồn gốc chính của dự án.
- **`frontend`**: Nhánh tích hợp chung của nhóm Frontend (tất cả code tính năng của Long và Dũng sẽ được gộp vào đây).
- **`long`**: Nhánh làm việc cá nhân của bạn Long.
- **`dung`**: Nhánh làm việc cá nhân của bạn Dũng.

> ⚠️ **QUAN TRỌNG:** Trong quá trình làm việc, Long và Dũng **CHỈ code trên nhánh riêng** của mình.  
> **KHÔNG pull từ `frontend`**, **KHÔNG merge vào `frontend`** cho đến khi hoàn thành toàn bộ công việc.  
> **CHỈ Long** mới được phép merge code vào nhánh `frontend`.

---

## 🚀 2. HƯỚNG DẪN CHO BẠN DŨNG BẮT ĐẦU DỰ ÁN (CHỈ LÀM 1 LẦN ĐẦU)

### Step 1: Clone dự án về máy
Mở **Terminal / PowerShell** trên máy tính và chạy:
```bash
# Clone dự án về máy (Git sẽ tự động tạo thư mục tên APP_BTL)
git clone https://github.com/nguyennhatLong2905/APP_BTL.git

# Di chuyển vào thư mục dự án
cd APP_BTL

# Tải các thư viện của Flutter
flutter pub get
```

> 💡 **Lưu ý:** Sau khi làm xong Step 1, Dũng hãy mở thư mục `APP_BTL` bằng **Android Studio** hoặc **VS Code**. 
> Nếu sau đó Dũng mở Terminal **ngay bên trong Android Studio / VS Code**, Terminal đã ở sẵn trong thư mục `APP_BTL` rồi, Dũng **không cần** gõ `cd APP_BTL` nữa nhé!

### Step 2: Cấu hình danh tính Git (nếu máy chưa cấu hình)
```bash
git config --global user.email "email-github-cua-dung@gmail.com"
git config --global user.name "ten-github-cua-dung"
```

### Step 3: Chuyển sang nhánh `dung`
```bash
# Kéo tất cả các nhánh mới từ GitHub về
git fetch origin

# Chuyển sang nhánh dung (đã được tạo sẵn)
git checkout dung
git pull origin dung
```

> 🎉 **Chúc mừng Dũng!** Đến đây Dũng đã sẵn sàng bắt đầu code trên nhánh `dung` của mình.

---

## 🔄 3. QUY TRÌNH LÀM VIỆC HÀNG NGÀY (DAILY WORKFLOW)

> ⚠️ **NGUYÊN TẮC VÀNG:** Mỗi người **LÀM VIỆC ĐỘC LẬP** trên nhánh riêng.  
> **KHÔNG kéo code từ `frontend`** trong quá trình làm việc.  
> **KHÔNG merge** vào bất kỳ nhánh nào khác.

### 💻 Bước 1: Đảm bảo đang ở nhánh của mình
```bash
# Dũng
git checkout dung

# Long
git checkout long
```

### 💻 Bước 2: Viết code tính năng theo Figma
Tiến hành viết code màn hình/tính năng trong thư mục tương ứng (`lib/features/...`).
- 💡 **Lưu ý:** Tận dụng lại các Widget UI Kit dùng chung đã được viết sẵn trong `lib/core/widgets/`:
  - `CurrencyTextField`: Ô nhập số tiền tự động định dạng tiền tệ (ví dụ: `100.000 ₫`).
  - `PrimaryButton`: Nút bấm chuẩn UI kèm hiệu ứng Loading.
  - `LoadingDialog`: Pop-up xoay tròn đè màn hình khi gọi API.
  - `AppSnackBar`: Hiển thị thông báo thành công (xanh) hoặc lỗi (đỏ).
  - `AppTheme`: Bảng màu chuẩn Thu nhập (Emerald Green), Chi tiêu (Red).

### 📤 Bước 3: Commit và Push code lên nhánh CÁ NHÂN
Khi làm xong một màn hình hoặc đoạn tính năng:
```bash
# Thêm các file thay đổi (CHỈ add feature folder của mình)
git add lib/features/wallet/   # Dũng
# hoặc
git add lib/features/home/     # Long

# Commit với thông điệp rõ ràng
git commit -m "feat(wallet): implement smart spending page"

# Đẩy code lên nhánh CỦA MÌNH trên GitHub
git push origin dung    # Dũng
# hoặc
git push origin long    # Long
```

### ✅ Bước 4: Khi HOÀN THÀNH TẤT CẢ các màn hình

**👨‍💻 Dũng** (khi xong 3 màn hình):
```bash
# 1. Đảm bảo đã commit & push hết code
git status   # Phải clean (nothing to commit)
git push origin dung

# 2. Báo Long
# "Anh Long ơi, em đã hoàn thành xong 3 màn hình rồi.
#  Anh merge code giúp em nhé!"

# 3. Chờ Long merge → XONG! Không cần làm gì thêm.
```

**👨‍💻 Long** (người merge - khi cả 2 đã hoàn thành):
```bash
# 1. Đảm bảo branch long đã xong & push hết
git checkout long
git push origin long

# 2. Merge long vào frontend trước
git checkout frontend
git pull origin frontend
git merge long --no-ff -m "feat: merge Long's work (4 screens)"
git push origin frontend

# 3. Merge dung vào frontend
git merge dung --no-ff -m "feat: merge Dung's work (3 screens)"

# 4. Giải quyết conflict (nếu có)
# 5. Test tổng thể
flutter run

# 6. Push lên frontend
git push origin frontend
```

---

## ⚠️ 4. QUY TẮC VÀNG - TRÁNH CONFLICT

### ✅ **ĐƯỢC PHÉP:**
1. Chỉ code trong **feature folder được giao**
2. Tạo **widgets riêng** trong folder của mình
3. Tạo **models/providers riêng** cho feature
4. Update file `TASKS_LONG.md` hoặc `TASKS_DUNG.md` của mình
5. Commit & push lên **nhánh CỦA MÌNH** bất cứ lúc nào

### ❌ **TUYỆT ĐỐI KHÔNG:**
1. ❌ Động vào feature folder của người khác
2. ❌ Sửa file shared (main.dart, routes, theme) - **TRÁNH HOÀN TOÀN**
3. ❌ Pull từ `frontend` trong quá trình làm việc
4. ❌ Merge bất kỳ branch nào vào branch của mình
5. ❌ Push trực tiếp lên `frontend` hoặc `main` (CHỈ Long merge khi xong)
6. ❌ Force push (`git push -f`)

---

## 🛠️ 5. CẤU TRÚC THƯ MỤC CẦN LƯU Ý

**Long - CHỈ code trong:**
- `lib/features/auth/` - Splash Screen
- `lib/features/home/` - Dashboard
- `lib/features/transaction/` - Thêm Giao Dịch
- `lib/features/report/` - Lịch Sử Giao Dịch

**Dũng - CHỈ code trong:**
- `lib/features/wallet/` - Mua Hay Chờ
- `lib/features/settings/` - Kế Hoạch Chi Tiêu
- `lib/features/notifications/` - Nhìn Lại Nhật Ký

**Dùng chung:**
- Màu sắc, font chữ, UI: `lib/core/theme/` và `lib/core/widgets/`

---

Chúc 2 bạn phối hợp mượt mà và hoàn thành dự án xuất sắc! 🔥

---

**Cập nhật lần cuối:** 2026-10-15
