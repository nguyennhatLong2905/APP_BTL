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

### Step 3: Chuyển sang nhánh `frontend` và Tạo nhánh cá nhân `dung`
```bash
# Kéo tất cả các nhánh mới từ GitHub về
git fetch origin

# Chuyển sang nhánh frontend
git checkout frontend
git pull origin frontend

# Tạo nhánh cá nhân dung từ nhánh frontend
git checkout -b dung

# Đẩy nhánh dung lên GitHub
git push -u origin dung
```

> 🎉 **Chúc mừng Dũng!** Đến đây Dũng đã sẵn sàng bắt đầu code trên nhánh `dung` của mình.

---

## 🔄 3. QUY TRÌNH LÀM VIỆC HÀNG NGÀY (DAILY WORKFLOW)

Mỗi khi Dũng bắt đầu code một màn hình/tính năng mới hoặc muốn đồng bộ code với Long, Dũng hãy làm theo 4 bước chuẩn dưới đây:

### 📥 Bước 1: Kéo code mới nhất từ nhánh `frontend` về nhánh `dung`
Trước khi bắt đầu viết code mới, hãy lấy code mới nhất mà Long đã gộp vào `frontend`:
```bash
# Đảm bảo đang ở nhánh dung
git checkout dung

# Lấy code mới nhất từ frontend gộp vào nhánh dung
git pull origin frontend
```

### 💻 Bước 2: Viết code tính năng theo Figma
Tiến hành viết code màn hình/tính năng trong thư mục tương ứng (`lib/features/...`).
- 💡 **Lưu ý:** Tận dụng lại các Widget UI Kit dùng chung đã được viết sẵn trong `lib/core/widgets/`:
  - `CurrencyTextField`: Ô nhập số tiền tự động định dạng tiền tệ (ví dụ: `100.000 ₫`).
  - `PrimaryButton`: Nút bấm chuẩn UI kèm hiệu ứng Loading.
  - `LoadingDialog`: Pop-up xoay tròn đè màn hình khi gọi API.
  - `AppSnackBar`: Hiển thị thông báo thành công (xanh) hoặc lỗi (đỏ).
  - `AppTheme`: Bảng màu chuẩn Thu nhập (Emerald Green), Chi tiêu (Red).

### 📤 Bước 3: Commit và Push code lên nhánh `dung`
Khi làm xong một màn hình hoặc đoạn tính năng:
```bash
# Thêm các file thay đổi
git add .

# Commit với thông điệp rõ ràng
git commit -m "feat: implement transaction form screen from figma"

# Đẩy code lên nhánh dung trên GitHub
git push origin dung
```

### 🔀 Bước 4: Tạo Pull Request (PR) gộp code vào `frontend`
1. Truy cập vào trang GitHub dự án: `https://github.com/nguyennhatLong2905/APP_BTL`
2. Nhấp vào nút **Compare & pull request** (hoặc vào mục **Pull Requests** -> **New Pull Request**).
3. Chọn:
   - **base (gộp vào):** `frontend`
   - **compare (từ nhánh):** `dung`
4. Bấm **Create pull request**. Long sẽ duyệt (Approve) và Merge code của Dũng vào nhánh `frontend`!

---

## 🛠️ 4. CẤU TRÚC THƯ MỤC CẦN LƯU Ý
- Code giao diện & logic màn hình làm việc trong thư mục: `lib/features/`
- Màu sắc, font chữ, UI dùng chung lấy ở: `lib/core/theme/` và `lib/core/widgets/`

Chúc 2 bạn phối hợp mượt mà và hoàn thành dự án xuất sắc! 🔥
