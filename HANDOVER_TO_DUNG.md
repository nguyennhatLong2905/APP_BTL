# 🤝 Bàn Giao Branch Cho Dũng

> **Ngày:** 2026-10-06  
> **Từ:** Long  
> **Đến:** Dũng

---

## 📋 Thông Tin Branch

**Branch của Dũng:** `dung`  
**GitHub Repo:** https://github.com/nguyennhatLong2905/APP_BTL.git

---

## 🚀 Hướng Dẫn Bắt Đầu Cho Dũng

### **Bước 1: Clone Repo**

```bash
# Mở Terminal/Command Prompt
# Vào folder muốn làm việc

git clone https://github.com/nguyennhatLong2905/APP_BTL.git
cd APP/App
```

### **Bước 2: Checkout Branch `dung`**

```bash
git checkout dung
git pull origin dung
```

### **Bước 3: Đọc Tài Liệu**

Đọc **KỸ** 2 files này:

1. **`TASK_DIVISION.md`** - Tổng quan (5 phút)
2. **`TASKS_DUNG.md`** - Chi tiết công việc của Dũng (20 phút)

```bash
# Mở trong VS Code hoặc editor
code TASK_DIVISION.md
code TASKS_DUNG.md
```

### **Bước 4: Xem Design**

Mở file: `docs/design/FIGMA_SCREENS.md`

Hoặc xem trực tiếp các ảnh:
- `docs/design/mua-hay-cho.png` - Màn Mua Hay Chờ
- `docs/design/ke-hoach-chi-tieu.png` - Màn Kế Hoạch Chi Tiêu
- `docs/design/nhin-lai-nhat-ky.png` - Màn Nhìn Lại Nhật Ký

### **Bước 5: Setup Flutter**

```bash
# Kiểm tra Flutter
flutter --version

# Cài dependencies
flutter pub get

# Test app
flutter run
```

**Nếu lỗi:**
- Đọc phần "HƯỚNG DẪN CÀI ĐẶT THƯ VIỆN" trong `TASKS_DUNG.md`
- Đọc phần "TROUBLESHOOTING" trong `TASKS_DUNG.md`

---

## 🎯 Nhiệm Vụ Của Dũng

### **Tổng cộng: 3 Màn Hình**

| # | Màn Hình | Ưu Tiên | Ước Lượng |
|---|----------|---------|-----------|
| 1 | Mua Hay Chờ (Smart Spending) | P1 | 1.5-2 ngày |
| 2 | Kế Hoạch Chi Tiêu (Budget Planning) | P1 | 2-2.5 ngày |
| 3 | Nhìn Lại Nhật Ký (Timeline) | P2 | 1.5-2 ngày |

**Tổng:** ~5-6.5 ngày

---

## 📁 Feature Folders Của Dũng

**CHỈ code trong 3 folders này:**

```
lib/features/wallet/          ← Màn Mua Hay Chờ
lib/features/settings/        ← Màn Kế Hoạch Chi Tiêu
lib/features/notifications/   ← Màn Nhìn Lại Nhật Ký
```

**❌ TUYỆT ĐỐI KHÔNG động vào:**
- `lib/features/auth/` (của Long)
- `lib/features/home/` (của Long)
- `lib/features/transaction/` (của Long)
- `lib/features/report/` (của Long)
- Bất kỳ file nào khác ngoài 3 folders trên

---

## 🔄 Quy Trình Git Đơn Giản

### **MỖI NGÀY:**

```bash
# 1. Bắt đầu code
git checkout dung

# 2. Code xong 1 widget/task nhỏ
git add lib/features/wallet/presentation/widgets/balance_indicator.dart
git commit -m "feat(wallet): add balance indicator widget"

# 3. Push lên branch dung
git push origin dung

# LẶP LẠI 2-3 cho các task khác
```

### **QUAN TRỌNG:**
- ✅ Commit THƯỜNG XUYÊN (mỗi task nhỏ)
- ✅ Push HÀNG NGÀY
- ❌ **KHÔNG** pull từ `frontend`
- ❌ **KHÔNG** merge bất kỳ branch nào
- ❌ **KHÔNG** làm việc trên branch khác ngoài `dung`

### **KHI HOÀN THÀNH TẤT CẢ 3 MÀN HÌNH:**

```bash
# 1. Commit & push hết
git status  # Phải clean
git push origin dung

# 2. Báo Long
# "Anh Long ơi, em đã hoàn thành 3 màn hình rồi.
#  Anh merge giúp em nhé!"

# 3. Chờ Long merge → XONG!
```

---

## 🆘 Khi Gặp Vấn Đề

### **Lỗi Setup/Dependencies:**
→ Đọc phần **"TROUBLESHOOTING"** trong `TASKS_DUNG.md`

### **Lỗi Git:**
→ Ping Long

### **Stuck Technical:**
→ Google, StackOverflow, ChatGPT/Kiro

### **Không Chắc:**
→ Ping Long trước khi làm

---

## 📦 Dependencies Cần Cài

Dũng cần add các packages sau:

```bash
flutter pub add syncfusion_flutter_sliders    # Cho Kế Hoạch Chi Tiêu
flutter pub add table_calendar                 # Cho Nhìn Lại Nhật Ký
flutter pub add sticky_headers                 # Cho Nhìn Lại Nhật Ký
```

**Chi tiết:** Xem trong `TASKS_DUNG.md` → phần "HƯỚNG DẪN CÀI ĐẶT THƯ VIỆN"

---

## ✅ Checklist Bắt Đầu

**Dũng làm theo thứ tự:**

- [ ] Clone repo về
- [ ] Checkout branch `dung`
- [ ] Đọc `TASK_DIVISION.md`
- [ ] Đọc `TASKS_DUNG.md` KỸ
- [ ] Xem tất cả 3 ảnh design
- [ ] Chạy `flutter pub get`
- [ ] Add dependencies (syncfusion, table_calendar, sticky_headers)
- [ ] Test `flutter run` chạy được
- [ ] Bắt đầu với màn **Mua Hay Chờ** (dễ nhất)

---

## 💬 Communication

### **Báo cáo tiến độ (optional nhưng nên có):**
- Sáng: "Em bắt đầu làm màn X"
- Tối: "Em đã push code màn X, làm được Y%"

### **Khi cần hỗ trợ:**
- Ping Long nếu liên quan Git/Merge
- Tự Google/ChatGPT nếu technical

---

## 📊 Timeline Đề Xuất

| Ngày | Công Việc |
|------|-----------|
| Ngày 1-2 | Màn **Mua Hay Chờ** |
| Ngày 3-5 | Màn **Kế Hoạch Chi Tiêu** |
| Ngày 6-7 | Màn **Nhìn Lại Nhật Ký** |

**Tổng:** 1 tuần hoàn thành!

---

## 🎯 Mục Tiêu

**Khi Dũng hoàn thành:**
- ✅ 3 màn hình UI hoàn chỉnh theo design
- ✅ Code chạy được, không lỗi
- ✅ Tất cả code trong 3 feature folders
- ✅ Đã test trên emulator/device

**Long sẽ làm:**
- ✅ Merge code của Dũng vào `frontend`
- ✅ Giải quyết conflict (nếu có)
- ✅ Test tổng thể

---

## 📞 Contact

**Nếu có vấn đề:**
- Git/Merge: Ping Long
- Technical: Google, ChatGPT, Kiro
- Urgent: Call Long

---

**Chúc Dũng code vui vẻ! 🚀**

---

**Bàn giao ngày:** 2026-10-06  
**Người bàn giao:** Long
