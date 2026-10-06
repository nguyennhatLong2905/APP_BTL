# 📋 Phân Chia Công Việc - App Ví An

> **Dự án:** App Quản Lý Chi Tiêu  
> **Team Frontend:** Long + Dũng  
> **Branch Strategy:** `long` + `dung` → `frontend` → `main`

---

## 🎯 Tổng Quan Phân Chia

### **Nguyên Tắc Phân Chia:**
- ✅ Chia theo **features độc lập** để tránh conflict
- ✅ Cân bằng **độ phức tạp** giữa 2 người
- ✅ Mỗi người **sở hữu hoàn toàn** feature của mình
- ✅ Không động vào code của người khác

---

## 👨‍💻 Long - 4 Màn Hình

| # | Màn Hình | Feature Folder | Ưu Tiên |
|---|----------|----------------|---------|
| 1 | **Splash Screen (Logo)** | `lib/features/auth/` | P0 |
| 2 | **Tổng Quan (Dashboard)** | `lib/features/home/` | P0 |
| 3 | **Thêm Giao Dịch** | `lib/features/transaction/` | P1 |
| 4 | **Lịch Sử Giao Dịch** | `lib/features/report/` | P2 |

### **Mô tả công việc:**
- Dashboard hiển thị tổng quan tài chính với các widgets và biểu đồ
- Lịch Sử Giao Dịch có phần báo cáo và thống kê
- Thêm Giao Dịch xử lý form nhập liệu
- Splash Screen làm màn hình khởi động

---

## 👨‍💻 Dũng - 3 Màn Hình

| # | Màn Hình | Feature Folder | Ưu Tiên |
|---|----------|----------------|---------|
| 1 | **Mua Hay Chờ** | `lib/features/wallet/` | P1 |
| 2 | **Kế Hoạch Chi Tiêu** | `lib/features/settings/` | P1 |
| 3 | **Nhìn Lại Nhật Ký** | `lib/features/notifications/` | P2 |

### **Mô tả công việc:**
- Kế Hoạch Chi Tiêu xử lý quản lý ngân sách và budget
- Mua Hay Chờ có logic phân tích và đề xuất
- Nhìn Lại Nhật Ký hiển thị timeline giao dịch

---

## 🔄 Quy Trình Làm Việc

### **QUAN TRỌNG: Quy trình merge đã thay đổi!**

> ⚠️ **CHỈ LONG mới được merge code vào `frontend`**  
> Mục đích: Tránh conflict, Long sẽ là người chịu trách nhiệm tích hợp code

### **Bước 1: Tạo Branch (Đã xong)**
```bash
# Long - Branch đã có
git checkout long

# Dũng - Branch đã có
git checkout dung
```

### **Bước 2: Làm Việc Độc Lập**

**Long & Dũng:**
```bash
# MỖI NGÀY chỉ làm trên branch của mình
git checkout long  # hoặc dung

# Code và commit THƯỜNG XUYÊN
git add lib/features/home/  # Chỉ add feature của mình
git commit -m "feat(home): implement dashboard balance card"
git push origin long  # hoặc dung

# KHÔNG pull từ frontend trong quá trình làm
# KHÔNG merge bất kỳ branch nào khác
```

### **Bước 3: Hoàn Thành & Bàn Giao (Khi xong TẤT CẢ màn hình)**

**Dũng:**
```bash
# Khi hoàn thành 3 màn hình
git add lib/features/wallet/ lib/features/settings/ lib/features/notifications/
git commit -m "feat: complete all 3 screens for dung branch"
git push origin dung

# Báo Long: "Anh ơi, em đã xong hết rồi, anh merge giúp em nhé!"
```

**Long (Người merge):**
```bash
# 1. Đảm bảo branch long đã xong
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

## ⚠️ QUY TẮC VÀNG - TRÁNH CONFLICT

### ✅ **ĐƯỢC PHÉP:**
1. Chỉ code trong **feature folder được giao**
2. Tạo **widgets riêng** trong folder của mình
3. Tạo **models/providers riêng** cho feature
4. Update file `TASKS_LONG.md` hoặc `TASKS_DUNG.md` của mình
5. Commit & push LÊN BRANCH CỦA MÌNH bất cứ lúc nào

### ❌ **TUYỆT ĐỐI KHÔNG:**
1. ❌ Động vào feature folder của người khác
2. ❌ Sửa file shared (main.dart, routes, theme) **TRÁNH HOÀN TOÀN**
3. ❌ Merge bất kỳ branch nào vào branch của mình
4. ❌ Pull từ `frontend` trong quá trình làm
5. ❌ Push trực tiếp lên `frontend` (CHỈ Long được làm)
6. ❌ Force push (`git push -f`)

### 📁 **CẤU TRÚC THƯ MỤC - PHẢI TUÂN THỦ:**

**Long - CHỈ code trong các folder này:**
```
lib/features/auth/
  └── presentation/
      ├── pages/
      │   └── splash_screen.dart
      └── widgets/
          └── logo_widget.dart

lib/features/home/
  ├── domain/models/
  ├── data/mock_data.dart
  └── presentation/
      ├── pages/home_page.dart
      ├── widgets/
      └── providers/

lib/features/transaction/
  ├── domain/models/
  └── presentation/
      ├── pages/add_transaction_page.dart
      ├── widgets/
      └── providers/

lib/features/report/
  ├── domain/models/
  └── presentation/
      ├── pages/report_page.dart
      ├── widgets/
      └── providers/
```

**Dũng - CHỈ code trong các folder này:**
```
lib/features/wallet/
  ├── domain/
  │   ├── models/
  │   └── services/
  └── presentation/
      ├── pages/smart_spending_page.dart
      ├── widgets/
      └── providers/

lib/features/settings/
  ├── domain/models/
  └── presentation/
      ├── pages/budget_planning_page.dart
      ├── widgets/
      └── providers/

lib/features/notifications/
  ├── domain/models/
  └── presentation/
      ├── pages/timeline_page.dart
      ├── widgets/
      └── providers/
```

### 🚨 **NẾU CẦN SHARED CODE:**
- **TRÁNH tối đa!** Mock data thay vì dùng shared
- Nếu thực sự cần: Ping Long để Long tạo sau khi merge
- **ĐỪNG** tự tạo shared code trong quá trình làm

---

## 📊 Tiến Độ Theo Dõi

| Người | Hoàn Thành | Đang Làm | Chưa Làm | % |
|-------|------------|----------|----------|---|
| Long  | 0/4 | - | 4 | 0% |
| Dũng  | 0/3 | - | 3 | 0% |

**Cập nhật:** Mỗi ngày update file này sau khi merge PR

---

## 📞 Liên Hệ & Hỗ Trợ

- **Conflict code?** → Ping nhau trước khi merge
- **Cần shared component?** → Tạo issue/chat group
- **Block bởi dependency?** → Tạm mock data, làm UI trước

---

## 📝 Files Chi Tiết

- 📄 [Chi tiết công việc Long](./TASKS_LONG.md)
- 📄 [Chi tiết công việc Dũng](./TASKS_DUNG.md)
- 📄 [Quy trình Git chi tiết](./GIT_WORKFLOW.md)

---

**Tạo ngày:** 2026-10-06  
**Cập nhật lần cuối:** 2026-10-06
