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

## 👨‍💻 Long - 4 Màn Hình (Độ phức tạp: Cao)

| # | Màn Hình | Feature Folder | Độ Phức Tạp | Ưu Tiên |
|---|----------|----------------|-------------|---------|
| 1 | **Splash Screen (Logo)** | `lib/features/auth/` | ⭐ Dễ | P0 |
| 2 | **Tổng Quan (Dashboard)** | `lib/features/home/` | ⭐⭐⭐⭐ Rất khó | P0 |
| 3 | **Thêm Giao Dịch** | `lib/features/transaction/` | ⭐⭐⭐ Khó | P1 |
| 4 | **Lịch Sử Giao Dịch** | `lib/features/report/` | ⭐⭐⭐⭐ Rất khó | P2 |

**Tổng điểm độ khó:** 13 ⭐

### **Lý do phân chia:**
- Dashboard là màn hình phức tạp nhất → Long đảm nhận
- Lịch Sử Giao Dịch có chart/analytics phức tạp
- Thêm Giao Dịch có form validation
- Splash Screen đơn giản để warm-up

---

## 👨‍💻 Dũng - 3 Màn Hình (Độ phức tạp: Trung bình)

| # | Màn Hình | Feature Folder | Độ Phức Tạp | Ưu Tiên |
|---|----------|----------------|-------------|---------|
| 1 | **Mua Hay Chờ** | `lib/features/wallet/` | ⭐⭐⭐ Khó | P1 |
| 2 | **Kế Hoạch Chi Tiêu** | `lib/features/settings/` | ⭐⭐⭐⭐ Rất khó | P1 |
| 3 | **Nhìn Lại Nhật Ký** | `lib/features/notifications/` | ⭐⭐⭐ Khó | P2 |

**Tổng điểm độ khó:** 10 ⭐

### **Lý do phân chia:**
- Kế Hoạch Chi Tiêu có budget planning phức tạp
- Mua Hay Chờ có logic so sánh/recommendation
- Nhìn Lại Nhật Ký là timeline view
- 3 màn nhưng cân bằng về độ khó

---

## 🔄 Quy Trình Làm Việc

### **Bước 1: Tạo Branch**
```bash
# Long
git checkout -b long
git push -u origin long

# Dũng
git checkout -b dung
git push -u origin dung
```

### **Bước 2: Làm Việc Hàng Ngày**
```bash
# Pull code mới nhất từ frontend
git checkout frontend
git pull origin frontend

# Merge vào branch của mình
git checkout long  # hoặc dung
git merge frontend

# Code và commit
git add .
git commit -m "feat(home): implement dashboard UI"
git push origin long  # hoặc dung
```

### **Bước 3: Merge vào Frontend**
```bash
# Tạo Pull Request: long → frontend
# Hoặc dung → frontend
# Review code → Merge
```

---

## ⚠️ QUY TẮC VÀNG - TRÁNH CONFLICT

### ✅ **ĐƯỢC PHÉP:**
1. Chỉ code trong **feature folder được giao**
2. Tạo **widgets riêng** trong folder của mình
3. Tạo **models/providers riêng** cho feature
4. Update file `TASKS_LONG.md` hoặc `TASKS_DUNG.md` của mình

### ❌ **KHÔNG ĐƯỢC PHÉP:**
1. ❌ Động vào feature folder của người khác
2. ❌ Sửa file shared (main.dart, routes, theme) mà không báo
3. ❌ Push trực tiếp lên `frontend` hoặc `main`
4. ❌ Force push (`git push -f`)

### 🚨 **NẾU CẦN SHARED CODE:**
- Tạo trong `lib/core/shared/`
- Báo nhau trên chat
- Merge vào `frontend` trước
- Người còn lại pull về

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
