# 🎯 Quick Start - Hướng Dẫn Bắt Đầu

> **Đọc file này trước khi bắt đầu làm việc!**

---

## 📚 Tài Liệu Quan Trọng

### **1. File Chính:**

| File | Nội Dung | Ai Cần Đọc |
|------|----------|------------|
| **TASK_DIVISION.md** | Tổng quan phân chia công việc | ✅ Long + Dũng |
| **GIT_WORKFLOW.md** | Quy trình Git chi tiết | ✅ Long + Dũng |
| **TASKS_LONG.md** | Chi tiết công việc của Long | ✅ Long |
| **TASKS_DUNG.md** | Chi tiết công việc của Dũng | ✅ Dũng |
| **docs/design/FIGMA_SCREENS.md** | Tất cả màn hình Figma | ✅ Long + Dũng |

---

## 🚀 Bắt Đầu Ngay

### **Long - Bước 1:**
```bash
# 1. Đảm bảo đang ở branch long
git checkout long
git pull origin long

# 2. Pull code mới từ frontend
git checkout frontend
git pull origin frontend

# 3. Merge vào long
git checkout long
git merge frontend

# 4. Đọc TASKS_LONG.md
# 5. Bắt đầu với Splash Screen!
```

### **Dũng - Bước 1:**
```bash
# 1. Clone repo (nếu chưa có)
git clone https://github.com/nguyennhatLong2905/APP_BTL.git
cd APP/App

# 2. Checkout branch dung
git checkout dung
git pull origin dung

# 3. Đọc TASKS_DUNG.md
# 4. Bắt đầu với Mua Hay Chờ!
```

---

## 📋 Checklist Đầu Tiên

### **Cả 2 người:**

- [ ] Đọc `TASK_DIVISION.md` để hiểu tổng quan
- [ ] Đọc `GIT_WORKFLOW.md` để hiểu quy trình Git
- [ ] Đọc file task riêng của mình (`TASKS_LONG.md` hoặc `TASKS_DUNG.md`)
- [ ] Xem tất cả design trong `docs/design/FIGMA_SCREENS.md`
- [ ] Setup git config:
  ```bash
  git config user.name "Tên Của Bạn"
  git config user.email "email@example.com"
  ```
- [ ] Test app chạy được: `flutter run`
- [ ] Add dependencies cần thiết (xem trong file task)

---

## 💡 Tips Quan Trọng

### **✅ NÊN:**
1. Commit nhỏ, thường xuyên (mỗi task nhỏ)
2. Push code mỗi ngày lên branch của mình
3. Pull code từ `frontend` MỖI SÁNG
4. Đặt tên commit rõ ràng: `feat(home): add balance card`
5. Test trước khi commit
6. Ping nhau khi cần sửa shared code

### **❌ KHÔNG NÊN:**
1. ❌ Sửa code trong feature folder của người khác
2. ❌ Push trực tiếp lên `frontend` hoặc `main`
3. ❌ Force push: `git push -f`
4. ❌ Commit code chưa test
5. ❌ Merge PR mà không review

---

## 🎨 Phân Chia Tóm Tắt

### **Long - 4 Màn Hình:**
1. ⭐ Splash Screen (Logo) - Dễ, 2-3 giờ
2. ⭐⭐⭐⭐ Dashboard (Tổng Quan) - Khó, 2-3 ngày
3. ⭐⭐⭐ Thêm Giao Dịch - Trung bình, 1.5 ngày
4. ⭐⭐⭐⭐ Lịch Sử Giao Dịch (Reports) - Khó, 2 ngày

**Feature folders:** `auth/`, `home/`, `transaction/`, `report/`

### **Dũng - 3 Màn Hình:**
1. ⭐⭐⭐ Mua Hay Chờ - Trung bình, 1.5-2 ngày
2. ⭐⭐⭐⭐ Kế Hoạch Chi Tiêu - Khó, 2-2.5 ngày
3. ⭐⭐⭐ Nhìn Lại Nhật Ký - Trung bình, 1.5-2 ngày

**Feature folders:** `wallet/`, `settings/`, `notifications/`

---

## 🔄 Quy Trình Merge

### **Khi xong 1 màn hình:**

1. **Tạo PR:**
   - GitHub → Pull Requests → New PR
   - Base: `frontend` ← Compare: `long` hoặc `dung`
   - Assign người còn lại để review

2. **Review:**
   - Người được assign pull code về test
   - Comment nếu có issue
   - Approve nếu OK

3. **Merge:**
   - Click **Merge** trên GitHub
   - Cả 2 người pull `frontend` về

---

## 🆘 Khi Gặp Vấn Đề

### **Conflict Code:**
→ Đọc phần "Giải Quyết Conflict" trong `GIT_WORKFLOW.md`  
→ Ping nhau để discuss

### **Stuck Technical:**
→ Google/StackOverflow  
→ Hỏi ChatGPT/Kiro  
→ Ping nhau nếu liên quan shared code

### **Không Chắc:**
→ **HỎI TRƯỚC KHI LÀM**  
→ Tốt hơn hỏi 1 phút hơn là fix conflict 1 giờ

---

## 📞 Communication

### **Daily:**
- Sáng: "Hôm nay mình làm màn X"
- Tối: "Đã push code màn X lên branch Y"

### **Khi Merge PR:**
- "Vừa tạo PR cho Dashboard, review giúp mình nhé!"

### **Khi Có Shared Code:**
- "Mình cần tạo TransactionModel trong core/, OK không?"

---

## 📊 Theo Dõi Tiến Độ

### **Update hàng ngày:**

**Long:** Update checklist trong `TASKS_LONG.md`  
**Dũng:** Update checklist trong `TASKS_DUNG.md`

**Format:**
```markdown
| Màn Hình | Status | Start Date | End Date | Notes |
|----------|--------|------------|----------|-------|
| Dashboard | 🚧 In Progress | 2026-10-06 | - | Đang làm chart |
```

---

## 🎯 Mục Tiêu

### **Tuần 1:**
- Long: Splash + Dashboard (50%)
- Dũng: Mua Hay Chờ (hoàn thành)

### **Tuần 2:**
- Long: Dashboard (100%) + Thêm Giao Dịch
- Dũng: Kế Hoạch Chi Tiêu

### **Tuần 3:**
- Long: Lịch Sử Giao Dịch
- Dũng: Nhìn Lại Nhật Ký

**→ Tổng: 3 tuần hoàn thành tất cả màn hình!**

---

## ✅ Đã Sẵn Sàng?

### **Checklist cuối:**

- [ ] Đã đọc hết 4 files chính
- [ ] Đã xem tất cả design trong Figma
- [ ] Đã setup git config
- [ ] Đã chạy được `flutter run`
- [ ] Đã hiểu rõ quy trình Git workflow
- [ ] Đã biết màn nào mình làm trước

### **→ BẮT ĐẦU CODE THÔI! 🚀**

---

**Chúc 2 bạn code vui vẻ!**

---

**Cập nhật lần cuối:** 2026-10-06
