# 👨‍💻 Công Việc Của Long

> **Branch:** `long`  
> **Tổng màn hình:** 4  
> **Độ ưu tiên:** Làm theo thứ tự P0 → P1 → P2

---

## 📱 Danh Sách Màn Hình

### ✅ 1. Splash Screen (Logo) - `P0` ⭐

**Feature:** `lib/features/auth/presentation/pages/splash_screen.dart`

**Design:** 
- Xem: `docs/design/FIGMA_SCREENS.md` → Logo
- Ảnh: `docs/design/logo.png`

**Yêu cầu:**
- [ ] Hiển thị logo Ví An ở giữa màn hình
- [ ] Background gradient (xem Figma)
- [ ] Animation fade-in logo (300ms)
- [ ] Auto navigate sau 2 giây → Dashboard
- [ ] Responsive cho mọi kích thước màn hình

**Cấu trúc folder:**
```
lib/features/auth/
├── presentation/
│   ├── pages/
│   │   └── splash_screen.dart          ← Tạo file này
│   └── widgets/
│       └── logo_widget.dart            ← Tạo widget riêng
```

**Dependencies:**
```yaml
# Không cần thêm, dùng built-in Flutter
```

**Ước lượng:** 2-3 giờ

---

### ✅ 2. Dashboard (Tổng Quan) - `P0` ⭐⭐⭐⭐

**Feature:** `lib/features/home/presentation/pages/home_page.dart`

**Design:** 
- Xem: `docs/design/FIGMA_SCREENS.md` → Tổng Quan
- Ảnh: `docs/design/tong-quan.png`

**Yêu cầu:**
- [ ] **Header:** Avatar, tên user, notification icon
- [ ] **Balance Card:** Hiển thị tổng số dư (số lớn, highlight)
- [ ] **Quick Actions:** 4 nút (Thu/Chi/Chuyển/Mục tiêu)
- [ ] **Transaction List:** List 5 giao dịch gần nhất
- [ ] **Chart:** Biểu đồ chi tiêu tuần (line chart hoặc bar chart)
- [ ] **Bottom Navigation Bar:** 5 tabs (Home/Transaction/Report/Wallet/Settings)
- [ ] Pull-to-refresh
- [ ] Skeleton loading khi fetch data

**Cấu trúc folder:**
```
lib/features/home/
├── domain/
│   └── models/
│       └── dashboard_data.dart         ← Model cho data
├── presentation/
│   ├── pages/
│   │   └── home_page.dart              ← Main page
│   ├── widgets/
│   │   ├── balance_card.dart           ← Card số dư
│   │   ├── quick_action_buttons.dart   ← 4 nút nhanh
│   │   ├── recent_transactions.dart    ← List giao dịch
│   │   ├── spending_chart.dart         ← Chart
│   │   └── bottom_nav_bar.dart         ← Bottom nav
│   └── providers/
│       └── home_provider.dart          ← State management
```

**Dependencies:**
```yaml
fl_chart: ^0.68.0  # Cho chart
```

**Mock Data:**
```dart
// Tạo file: lib/features/home/data/mock_data.dart
final mockBalance = 5000000; // 5 triệu
final mockTransactions = [
  Transaction(id: '1', title: 'Cà phê', amount: -45000, date: DateTime.now()),
  // ... thêm 4 cái nữa
];
```

**Ước lượng:** 2-3 ngày

---

### ✅ 3. Thêm Giao Dịch - `P1` ⭐⭐⭐

**Feature:** `lib/features/transaction/presentation/pages/add_transaction_page.dart`

**Design:** 
- Xem: `docs/design/FIGMA_SCREENS.md` → Thêm Giao Dịch
- Ảnh: `docs/design/them-giao-dich.png`

**Yêu cầu:**
- [ ] **Tab Selector:** Thu / Chi
- [ ] **Amount Input:** TextField số tiền (format tiền VND)
- [ ] **Category Picker:** Grid các category (Ăn uống, Di chuyển, Mua sắm...)
- [ ] **Date Picker:** Chọn ngày giao dịch
- [ ] **Note Input:** TextField ghi chú (optional)
- [ ] **Photo Attachment:** Button chụp/chọn ảnh hóa đơn (optional)
- [ ] **Save Button:** Lưu giao dịch
- [ ] Form validation (số tiền > 0, category required)
- [ ] Success message sau khi save

**Cấu trúc folder:**
```
lib/features/transaction/
├── domain/
│   └── models/
│       ├── transaction.dart
│       └── transaction_category.dart
├── presentation/
│   ├── pages/
│   │   └── add_transaction_page.dart
│   ├── widgets/
│   │   ├── amount_input.dart
│   │   ├── category_grid.dart
│   │   ├── date_picker_field.dart
│   │   └── photo_picker.dart
│   └── providers/
│       └── transaction_provider.dart
```

**Dependencies:**
```yaml
intl: ^0.19.0  # Format tiền VND
image_picker: ^1.0.0  # Chọn ảnh
```

**Ước lượng:** 1.5 ngày

---

### ✅ 4. Lịch Sử Giao Dịch (Reports) - `P2` ⭐⭐⭐⭐

**Feature:** `lib/features/report/presentation/pages/report_page.dart`

**Design:** 
- Xem: `docs/design/FIGMA_SCREENS.md` → Lịch Sử Giao Dịch
- Ảnh: `docs/design/lich-su-giao-dich.png`

**Yêu cầu:**
- [ ] **Time Period Selector:** Tuần / Tháng / Năm
- [ ] **Summary Cards:** Tổng thu, tổng chi, còn lại
- [ ] **Pie Chart:** Phân bổ chi tiêu theo category
- [ ] **Bar Chart:** So sánh thu chi theo thời gian
- [ ] **Transaction List:** Grouped by date
- [ ] **Filter:** By category, date range
- [ ] **Export Button:** Export PDF/Excel (optional - làm sau)
- [ ] Animation khi switch chart

**Cấu trúc folder:**
```
lib/features/report/
├── domain/
│   └── models/
│       └── report_data.dart
├── presentation/
│   ├── pages/
│   │   └── report_page.dart
│   ├── widgets/
│   │   ├── period_selector.dart
│   │   ├── summary_cards.dart
│   │   ├── pie_chart_widget.dart
│   │   ├── bar_chart_widget.dart
│   │   └── grouped_transaction_list.dart
│   └── providers/
│       └── report_provider.dart
```

**Dependencies:**
```yaml
fl_chart: ^0.68.0  # Đã có ở Dashboard
syncfusion_flutter_charts: ^24.0.0  # Optional, nếu cần chart đẹp hơn
```

**Ước lượng:** 2 ngày

---

## 📋 Checklist Trước Khi Bắt Đầu

### **Setup Environment:**
- [ ] Clone repo về máy
- [ ] Checkout branch `long`: `git checkout -b long`
- [ ] Push branch lên: `git push -u origin long`
- [ ] Chạy `flutter pub get`
- [ ] Test app trên emulator/device

### **Review Design:**
- [ ] Đọc kỹ file `docs/design/FIGMA_SCREENS.md`
- [ ] Xem tất cả ảnh design của mình
- [ ] Note lại các màu sắc, font size, spacing
- [ ] Identify các components có thể reuse

---

## 🔄 Quy Trình Hàng Ngày

### **Sáng (Trước khi code):**
```bash
# 1. Pull code mới từ frontend
git checkout frontend
git pull origin frontend

# 2. Merge vào branch long
git checkout long
git merge frontend

# 3. Giải quyết conflict (nếu có)
# 4. Bắt đầu code
```

### **Tối (Sau khi code xong):**
```bash
# 1. Commit code
git add lib/features/home/  # Chỉ add feature của mình
git commit -m "feat(home): implement dashboard balance card"

# 2. Push lên branch long
git push origin long

# 3. Update checklist trong file này
# 4. Tạo PR nếu đã xong 1 màn hình hoàn chỉnh
```

---

## ✅ Tiến Độ

| Màn Hình | Status | Start Date | End Date | Notes |
|----------|--------|------------|----------|-------|
| Splash Screen | ⏳ Todo | - | - | - |
| Dashboard | ⏳ Todo | - | - | - |
| Thêm Giao Dịch | ⏳ Todo | - | - | - |
| Lịch Sử Giao Dịch | ⏳ Todo | - | - | - |

**Legend:**
- ⏳ Todo
- 🚧 In Progress
- ✅ Done
- 🔄 In Review

---

## 🆘 Hỗ Trợ & Tips

### **Stuck? Làm thế nào:**
1. Google/StackOverflow
2. Check Flutter docs
3. Hỏi ChatGPT/Kiro
4. Ping Dũng nếu liên quan shared code

### **Best Practices:**
- ✅ Commit nhỏ, thường xuyên
- ✅ Viết tên commit rõ ràng: `feat(home): add balance card`
- ✅ Test trên nhiều màn hình (phone/tablet)
- ✅ Comment code phức tạp
- ✅ Extract widgets nhỏ, reusable

### **Performance Tips:**
- Dùng `const` constructor khi có thể
- Avoid nested `setState()`
- Use `ListView.builder` cho list dài
- Cache images với `CachedNetworkImage`

---

## 📦 Dependencies Cần Thêm

Thêm vào `pubspec.yaml`:

```yaml
dependencies:
  # State Management (đã có)
  flutter_riverpod: ^2.0.0
  
  # UI & Charts
  fl_chart: ^0.68.0
  
  # Utils
  intl: ^0.19.0  # Format số tiền VND
  image_picker: ^1.0.0  # Chọn ảnh
  
  # Optional
  cached_network_image: ^3.3.0  # Cache ảnh
  shimmer: ^3.0.0  # Skeleton loading
```

Run:
```bash
flutter pub add fl_chart intl image_picker
```

---

**Good luck, Long! 🚀**

---

**Cập nhật lần cuối:** 2026-10-06
