# 🔄 Git Workflow - Tránh Xung Đột Code

> **Quy trình làm việc với Git cho team Frontend (Long + Dũng)**

---

## 📊 Branch Strategy

```
main (production)
 ↑
 └── frontend (integration branch)
      ↑        ↑
      │        │
   long      dung
  (Long)    (Dũng)
```

### **Mục đích từng branch:**
- **`main`**: Code production, chỉ merge sau khi test kỹ
- **`frontend`**: Integration branch, merge code của Long + Dũng
- **`long`**: Branch cá nhân của Long
- **`dung`**: Branch cá nhân của Dũng

---

## 🚀 Setup Ban Đầu (Chỉ làm 1 lần)

### **Long thực hiện:**
```bash
# 1. Clone repo (nếu chưa có)
git clone <repo-url>
cd App

# 2. Tạo branch long từ frontend
git checkout -b frontend  # Nếu chưa có
git checkout -b long

# 3. Push lên remote
git push -u origin long
```

### **Dũng thực hiện:**
```bash
# 1. Clone repo (nếu chưa có)
git clone <repo-url>
cd App

# 2. Tạo branch dung từ frontend
git checkout -b frontend  # Nếu chưa có
git checkout -b dung

# 3. Push lên remote
git push -u origin dung
```

---

## 📅 Quy Trình Hàng Ngày

### **SÁNG (Trước khi bắt đầu code):**

```bash
# Bước 1: Đảm bảo đang ở branch của mình
git checkout long  # hoặc dung

# Bước 2: Pull code mới nhất từ frontend
git fetch origin
git checkout frontend
git pull origin frontend

# Bước 3: Merge frontend vào branch của mình
git checkout long  # hoặc dung
git merge frontend

# Bước 4: Giải quyết conflict (nếu có - xem phần dưới)
# Bước 5: Bắt đầu code!
```

### **TRONG NGÀY (Commit thường xuyên):**

```bash
# Sau mỗi task nhỏ (VD: làm xong 1 widget)

# 1. Xem files đã thay đổi
git status

# 2. Add files (CHỈ add feature của mình)
git add lib/features/home/  # Long
# hoặc
git add lib/features/wallet/  # Dũng

# 3. Commit với message rõ ràng
git commit -m "feat(home): add balance card widget"

# 4. Push lên branch của mình
git push origin long  # hoặc dung
```

### **TỐI (Kết thúc ngày làm việc):**

```bash
# 1. Commit code còn đang làm dở (nếu có)
git add .
git commit -m "wip: working on dashboard chart"
git push origin long  # hoặc dung

# 2. Update tiến độ trong TASKS_LONG.md hoặc TASKS_DUNG.md
```

---

## ✅ Merge Code Vào Frontend (Khi hoàn thành 1 màn hình)

### **Bước 1: Đảm bảo code của mình chạy OK**
```bash
# Test trên emulator/device
flutter run

# Check không có error
flutter analyze
```

### **Bước 2: Tạo Pull Request**

**Trên GitHub:**
1. Vào repo → **Pull Requests** → **New Pull Request**
2. Base: `frontend` ← Compare: `long` (hoặc `dung`)
3. Title: `feat: implement Dashboard screen`
4. Description: 
   ```
   ## Màn hình: Dashboard (Tổng Quan)
   
   ### ✅ Đã hoàn thành:
   - Balance card
   - Quick actions
   - Recent transactions
   - Chart
   
   ### 📸 Screenshots:
   [Attach ảnh màn hình]
   
   ### ⚠️ Notes:
   - Đã test trên Android
   - Mock data, chưa connect API
   ```
5. Assign: Người còn lại (để review)
6. **Create Pull Request**

### **Bước 3: Review & Merge**

**Người review (Dũng hoặc Long):**
1. Xem code changes
2. Pull về test thử:
   ```bash
   git fetch origin
   git checkout long  # hoặc dung
   git pull origin long
   flutter run
   ```
3. Nếu OK → **Approve** và **Merge** trên GitHub
4. Nếu có issue → Comment để sửa

**Sau khi merge:**
```bash
# Pull code mới về frontend
git checkout frontend
git pull origin frontend
```

---

## ⚠️ Giải Quyết Conflict

### **Khi nào xảy ra conflict?**
- Khi 2 người sửa cùng 1 file
- Khi merge frontend vào branch của mình

### **Cách giải quyết:**

**Bước 1: Xác định files conflict**
```bash
git merge frontend
# Git sẽ báo: CONFLICT in lib/core/theme.dart
git status
# Hiển thị files conflict màu đỏ
```

**Bước 2: Mở file conflict trong VS Code**
```
<<<<<<< HEAD (long hoặc dung - code của bạn)
final primaryColor = Colors.blue;
=======
final primaryColor = Colors.green;
>>>>>>> frontend (code từ frontend)
```

**Bước 3: Chọn version nào giữ lại**
- Giữ code của mình: Xóa phần `=======` đến `>>>>>>>` và dòng `<<<<<<<`
- Giữ code frontend: Xóa phần `<<<<<<<` đến `=======`
- Giữ cả 2: Merge thủ công

**Bước 4: Commit sau khi resolve**
```bash
git add lib/core/theme.dart
git commit -m "chore: resolve merge conflict in theme.dart"
git push origin long  # hoặc dung
```

### **NGUYÊN TẮC VÀNG:**
- ❌ Nếu không chắc → **ĐỪNG** tự ý xóa code người khác
- ✅ Ping người đó trước: "Em conflict file X, anh/chị check giúp"
- ✅ Discuss và quyết định cùng nhau

---

## 🚨 Các Lỗi Thường Gặp & Cách Fix

### **1. Lỗi: `error: Your local changes would be overwritten by merge`**

**Nguyên nhân:** Có code chưa commit

**Fix:**
```bash
# Option 1: Commit code
git add .
git commit -m "wip: save current work"

# Option 2: Stash (tạm cất code)
git stash
git merge frontend
git stash pop  # Lấy code ra lại
```

---

### **2. Lỗi: `fatal: refusing to merge unrelated histories`**

**Nguyên nhân:** Branch không có chung history

**Fix:**
```bash
git merge frontend --allow-unrelated-histories
```

---

### **3. Lỗi: Push bị reject**

**Nguyên nhân:** Remote có code mới hơn local

**Fix:**
```bash
git pull origin long  # hoặc dung
# Giải quyết conflict (nếu có)
git push origin long
```

---

### **4. Lỗi: Commit nhầm lên branch khác**

**VD:** Đang ở branch `frontend` nhưng commit (nên commit ở `long`)

**Fix:**
```bash
# Chưa push
git reset --soft HEAD~1  # Undo commit nhưng giữ code
git checkout long
git commit -m "feat(home): correct commit"

# Đã push (NGUY HIỂM - hỏi trước khi làm)
# Ping người khác trước!
```

---

## ❌ CÁC LỆNH CẤM DÙNG

### **TUYỆT ĐỐI KHÔNG:**

```bash
# 1. Force push
git push -f origin long
git push --force origin frontend

# 2. Reset hard trên branch chung
git reset --hard HEAD~5

# 3. Xóa branch chung
git branch -D frontend
git push origin --delete frontend

# 4. Rebase trên branch đã push
git rebase frontend  # Nếu đã push long lên remote

# 5. Commit trực tiếp lên frontend/main
git checkout frontend
git commit -m "..."  # KHÔNG!
```

### **Tại sao?**
→ Sẽ làm mất code của người khác hoặc gây conflict nghiêm trọng

---

## 📋 Commit Message Convention

### **Format:**
```
<type>(<scope>): <subject>

<body> (optional)
```

### **Types:**
- `feat`: Thêm feature mới
- `fix`: Sửa bug
- `refactor`: Refactor code
- `style`: Format code, thêm dấu ;
- `docs`: Update documentation
- `test`: Thêm tests
- `chore`: Update dependencies, config
- `wip`: Work in progress (code chưa xong)

### **Examples:**
```bash
git commit -m "feat(home): add dashboard balance card"
git commit -m "fix(wallet): fix recommendation logic calculation"
git commit -m "refactor(transaction): extract category picker widget"
git commit -m "docs: update TASKS_LONG.md progress"
git commit -m "wip: working on chart animation"
```

---

## 🎯 Checklist Trước Khi Push

- [ ] Code chạy được: `flutter run`
- [ ] Không có lỗi: `flutter analyze`
- [ ] Format code: `flutter format lib/`
- [ ] CHỈ add files của feature mình làm
- [ ] Commit message rõ ràng
- [ ] Đã test trên emulator/device

---

## 🆘 Khi Nào Cần Hỏi Người Khác

### **PHẢI hỏi khi:**
- ❗ Conflict không biết giải quyết
- ❗ Cần sửa file shared (theme, routes, main.dart)
- ❗ Cần tạo model/provider mà người khác có thể dùng
- ❗ Muốn force push hoặc delete branch

### **Cách hỏi:**
```
"Long/Dũng ơi, em đang conflict file lib/core/theme.dart.
Em thấy anh/em sửa primaryColor = Colors.green.
Mình discuss trước nhé, em cần dùng Colors.blue cho feature của em."
```

---

## 📞 Communication Protocol

### **Daily Standup (Buổi sáng):**
- "Hôm nay em sẽ làm feature X"
- "Hôm qua em đã merge PR Y vào frontend"
- "Em đang block vì issue Z"

### **Trước khi merge PR:**
- "Anh/em ơi, em vừa tạo PR cho Dashboard, review giúp em nhé!"

### **Khi có shared code:**
- "Em cần tạo TransactionModel trong lib/core/models/. OK không?"

---

## ✅ Summary - TL;DR

### **Mỗi ngày:**
```bash
# Sáng
git checkout long  # hoặc dung
git checkout frontend && git pull origin frontend
git checkout long && git merge frontend

# Code...

# Commit thường xuyên
git add lib/features/home/
git commit -m "feat(home): add widget X"
git push origin long

# Tối: Update TASKS_LONG.md
```

### **Khi xong 1 màn hình:**
1. Tạo PR: `long` → `frontend`
2. Người khác review
3. Merge vào `frontend`
4. Cả 2 pull `frontend` về

### **Tránh conflict:**
- ✅ Chỉ code trong feature folder của mình
- ✅ Pull `frontend` mỗi sáng
- ✅ Communicate trước khi sửa shared code
- ✅ Commit nhỏ, push thường xuyên

---

**Happy Coding! 🚀**

---

**Tạo ngày:** 2026-10-06  
**Cập nhật lần cuối:** 2026-10-06
