# 👨‍💻 Công Việc Của Dũng

> **Branch:** `dung`  
> **Tổng màn hình:** 3  
> **Độ ưu tiên:** Làm theo thứ tự P1 → P2

---

## 📱 Danh Sách Màn Hình

### ✅ 1. Mua Hay Chờ (Smart Spending) - `P1`

**Feature:** `lib/features/wallet/presentation/pages/smart_spending_page.dart`

**Design:** 
- Xem: `docs/design/FIGMA_SCREENS.md` → Mua Hay Chờ
- Ảnh: `docs/design/mua-hay-cho.png`

**Yêu cầu:**
- [ ] **Item Input:** TextField nhập tên món muốn mua
- [ ] **Price Input:** TextField nhập giá
- [ ] **Current Balance Display:** Hiển thị số dư hiện tại
- [ ] **Recommendation Engine:** 
  - Phân tích có nên mua không (dựa trên % số dư, chi tiêu tháng)
  - Hiển thị kết quả: "NÊN MUA" (xanh) hoặc "NÊN CHỜ" (đỏ)
  - Lý do cụ thể (VD: "Bạn còn 60% ngân sách tháng này")
- [ ] **Alternative Suggestions:** Gợi ý thay thế rẻ hơn
- [ ] **Save Decision:** Lưu lịch sử quyết định
- [ ] Animation khi hiển thị kết quả

**Cấu trúc folder:**
```
lib/features/wallet/
├── domain/
│   ├── models/
│   │   ├── spending_decision.dart
│   │   └── wallet_balance.dart
│   └── services/
│       └── recommendation_service.dart  ← Logic đề xuất
├── presentation/
│   ├── pages/
│   │   └── smart_spending_page.dart
│   ├── widgets/
│   │   ├── balance_indicator.dart
│   │   ├── item_input_form.dart
│   │   ├── recommendation_card.dart    ← Card kết quả
│   │   └── alternative_suggestions.dart
│   └── providers/
│       └── wallet_provider.dart
```

**Logic Đề Xuất (Mẫu):**
```dart
// lib/features/wallet/domain/services/recommendation_service.dart
class RecommendationService {
  Decision shouldBuy(double itemPrice, double balance, double monthlySpending) {
    final percentage = (itemPrice / balance) * 100;
    
    if (percentage > 30) {
      return Decision.wait(reason: "Món này chiếm ${percentage.toInt()}% số dư");
    } else if (balance - itemPrice < monthlySpending * 0.2) {
      return Decision.wait(reason: "Sau khi mua bạn chỉ còn dưới 20% ngân sách tháng");
    } else {
      return Decision.buy(reason: "Bạn có đủ khả năng chi trả");
    }
  }
}
```

**Dependencies:**
```yaml
# Không cần thêm dependencies đặc biệt
```

**Ước lượng:** 1.5-2 ngày

---

### ✅ 2. Kế Hoạch Chi Tiêu (Budget Planning) - `P1`

**Feature:** `lib/features/settings/presentation/pages/budget_planning_page.dart`

**Design:** 
- Xem: `docs/design/FIGMA_SCREENS.md` → Kế Hoạch Chi Tiêu
- Ảnh: `docs/design/ke-hoach-chi-tieu.png`

**Yêu cầu:**
- [ ] **Monthly Budget Input:** Set ngân sách tổng tháng
- [ ] **Category Budgets:** Set ngân sách cho từng category
  - Ăn uống: X VND
  - Di chuyển: Y VND
  - Giải trí: Z VND
  - ...
- [ ] **Progress Bars:** Hiển thị % đã chi / budget của mỗi category
- [ ] **Alerts:** Warning khi gần hết budget (>80%)
- [ ] **History:** Xem budget các tháng trước
- [ ] **Quick Templates:** Templates budget có sẵn (Tiết kiệm, Trung bình, Thoải mái)
- [ ] **Drag to Adjust:** Có thể kéo thanh để adjust %
- [ ] Validation: Tổng budget categories <= monthly budget

**Cấu trúc folder:**
```
lib/features/settings/
├── domain/
│   └── models/
│       ├── budget.dart
│       ├── category_budget.dart
│       └── budget_template.dart
├── presentation/
│   ├── pages/
│   │   └── budget_planning_page.dart
│   ├── widgets/
│   │   ├── monthly_budget_input.dart
│   │   ├── category_budget_item.dart    ← 1 item có progress bar
│   │   ├── budget_progress_chart.dart
│   │   ├── template_selector.dart
│   │   └── budget_alert_card.dart
│   └── providers/
│       └── budget_provider.dart
```

**Budget Templates (Mẫu):**
```dart
final templates = [
  BudgetTemplate(
    name: "Tiết kiệm",
    categories: {
      'food': 0.30,        // 30% cho ăn uống
      'transport': 0.15,   // 15% di chuyển
      'entertainment': 0.10,
      'shopping': 0.15,
      'savings': 0.30,     // 30% tiết kiệm
    },
  ),
  // ... thêm templates khác
];
```

**Dependencies:**
```yaml
syncfusion_flutter_sliders: ^24.0.0  # Cho drag slider
```

**Ước lượng:** 2-2.5 ngày

---

### ✅ 3. Nhìn Lại Nhật Ký (Transaction Timeline) - `P2`

**Feature:** `lib/features/notifications/presentation/pages/timeline_page.dart`

**Design:** 
- Xem: `docs/design/FIGMA_SCREENS.md` → Nhìn Lại Nhật Ký
- Ảnh: `docs/design/nhin-lai-nhat-ky.png`

**Yêu cầu:**
- [ ] **Timeline View:** Hiển thị giao dịch theo dòng thời gian
- [ ] **Date Headers:** Sticky headers cho mỗi ngày
- [ ] **Transaction Cards:** Mỗi card có:
  - Icon category
  - Tên giao dịch
  - Số tiền (màu đỏ cho chi, xanh cho thu)
  - Thời gian
  - Ảnh hóa đơn (nếu có)
- [ ] **Calendar View Toggle:** Switch giữa list view và calendar view
- [ ] **Search & Filter:**
  - Search by name
  - Filter by category
  - Filter by date range
- [ ] **Statistics Card:** Tóm tắt chi tiêu trong khoảng thời gian đang xem
- [ ] **Infinite Scroll:** Load more khi scroll xuống cuối
- [ ] Pull-to-refresh

**Cấu trúc folder:**
```
lib/features/notifications/
├── domain/
│   └── models/
│       ├── timeline_item.dart
│       └── transaction_group.dart
├── presentation/
│   ├── pages/
│   │   └── timeline_page.dart
│   ├── widgets/
│   │   ├── timeline_item_card.dart
│   │   ├── date_header.dart
│   │   ├── calendar_view.dart
│   │   ├── search_filter_bar.dart
│   │   └── statistics_summary_card.dart
│   └── providers/
│       └── timeline_provider.dart
```

**Group Transactions by Date:**
```dart
Map<String, List<Transaction>> groupByDate(List<Transaction> transactions) {
  final grouped = <String, List<Transaction>>{};
  for (var txn in transactions) {
    final dateKey = DateFormat('yyyy-MM-dd').format(txn.date);
    grouped.putIfAbsent(dateKey, () => []).add(txn);
  }
  return grouped;
}
```

**Dependencies:**
```yaml
table_calendar: ^3.0.9  # Cho calendar view
sticky_headers: ^0.3.0  # Cho sticky date headers
```

**Ước lượng:** 1.5-2 ngày

---

## � HƯỚNG DẪN CÀI ĐẶT THƯ VIỆN CHI TIẾT

> **QUAN TRỌNG:** Đọc kỹ phần này trước khi bắt đầu code để tránh lỗi!

### **Bước 1: Kiểm tra Flutter SDK**

```bash
# Kiểm tra phiên bản Flutter
flutter --version

# Nên dùng Flutter 3.x trở lên
# Nếu cũ, update: flutter upgrade
```

### **Bước 2: Cài đặt dependencies**

**Mở file `pubspec.yaml` và thêm:**

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management (ĐÃ CÓ SẴN)
  flutter_riverpod: ^2.0.0
  
  # UI Components - CẦN THÊM
  syncfusion_flutter_sliders: ^24.0.0    # Cho Kế Hoạch Chi Tiêu
  table_calendar: ^3.0.9                  # Cho Nhìn Lại Nhật Ký
  sticky_headers: ^0.3.0                  # Cho Nhìn Lại Nhật Ký
  
  # Utils (ĐÃ CÓ TỪ LONG)
  intl: ^0.19.0                           # Format tiền VND
```

**Sau đó chạy:**

```bash
flutter pub get
```

### **Bước 3: Cài từng package riêng (Nếu Bước 2 lỗi)**

**Nếu gặp lỗi khi `flutter pub get`, cài từng cái một:**

```bash
# 1. Cài Syncfusion Sliders
flutter pub add syncfusion_flutter_sliders

# 2. Cài Table Calendar
flutter pub add table_calendar

# 3. Cài Sticky Headers
flutter pub add sticky_headers

# 4. Kiểm tra lại
flutter pub get
```

### **Bước 4: Import vào code**

**Khi dùng trong code, import như sau:**

```dart
// Cho Kế Hoạch Chi Tiêu
import 'package:syncfusion_flutter_sliders/sliders.dart';

// Cho Nhìn Lại Nhật Ký
import 'package:table_calendar/table_calendar.dart';
import 'package:sticky_headers/sticky_headers.dart';

// Utils
import 'package:intl/intl.dart';
```

---

## ⚠️ TROUBLESHOOTING - Xử Lý Lỗi Thường Gặp

### **Lỗi 1: `Package not found`**

**Triệu chứng:**
```
Error: Could not resolve package 'syncfusion_flutter_sliders'
```

**Giải pháp:**
```bash
# Xóa cache
flutter clean

# Cài lại
flutter pub get

# Nếu vẫn lỗi, check internet và retry
```

---

### **Lỗi 2: `Version conflict`**

**Triệu chứng:**
```
Because app depends on both package_a 1.0.0 and package_b which depends on package_a 2.0.0...
```

**Giải pháp:**
```yaml
# Trong pubspec.yaml, chỉ định version cụ thể
dependency_overrides:
  package_a: 1.0.0
```

Hoặc:
```bash
flutter pub upgrade
```

---

### **Lỗi 3: `Build failed` sau khi add package**

**Triệu chứng:**
```
BUILD FAILED in 5s
```

**Giải pháp:**
```bash
# Android
cd android
./gradlew clean
cd ..

# iOS (nếu dùng Mac)
cd ios
pod install
cd ..

# Sau đó
flutter clean
flutter pub get
flutter run
```

---

### **Lỗi 4: `Undefined class` khi import**

**Triệu chứng:**
```dart
import 'package:table_calendar/table_calendar.dart';
// Lỗi: Undefined class 'TableCalendar'
```

**Giải pháp:**
```bash
# Restart IDE (VS Code/Android Studio)
# Hoặc restart Dart Analysis Server trong VS Code:
# Ctrl+Shift+P → "Dart: Restart Analysis Server"
```

---

### **Lỗi 5: Syncfusion License Warning**

**Triệu chứng:**
```
Warning: Syncfusion license key is missing
```

**Giải pháp:**

Syncfusion có cảnh báo license nhưng **KHÔNG ẢNH HƯỞNG** đến dev. Có thể:

1. **Bỏ qua** (recommend cho học tập)
2. Hoặc đăng ký free license tại: https://www.syncfusion.com/sales/communitylicense

Thêm vào `main.dart`:
```dart
import 'package:syncfusion_flutter_core/core.dart';

void main() {
  SyncfusionLicense.registerLicense('YOUR_LICENSE_KEY');
  runApp(MyApp());
}
```

---

### **Lỗi 6: `intl` format lỗi**

**Triệu chứng:**
```dart
NumberFormat.currency(locale: 'vi_VN').format(1000000);
// Lỗi: Locale data missing
```

**Giải pháp:**

```dart
// Dùng custom format thay vì locale
final currencyFormat = NumberFormat('#,###', 'vi_VN');
String formatted = '${currencyFormat.format(1000000)} ₫';
// Output: "1.000.000 ₫"
```

---

## 🧪 TESTING PACKAGES

**Test từng package sau khi cài:**

### **Test 1: Syncfusion Slider**

```dart
import 'package:syncfusion_flutter_sliders/sliders.dart';

SfSlider(
  min: 0.0,
  max: 100.0,
  value: 50.0,
  onChanged: (value) {},
);
```

Nếu không lỗi → ✅ OK

---

### **Test 2: Table Calendar**

```dart
import 'package:table_calendar/table_calendar.dart';

TableCalendar(
  firstDay: DateTime.utc(2020, 1, 1),
  lastDay: DateTime.utc(2030, 12, 31),
  focusedDay: DateTime.now(),
);
```

Nếu hiện calendar → ✅ OK

---

### **Test 3: Sticky Headers**

```dart
import 'package:sticky_headers/sticky_headers.dart';

StickyHeader(
  header: Text('Header'),
  content: Text('Content'),
);
```

Nếu không lỗi → ✅ OK

---

## 📚 TÀI LIỆU THAM KHẢO

### **1. Syncfusion Sliders:**
- Docs: https://help.syncfusion.com/flutter/slider/overview
- Examples: https://flutter.syncfusion.com/#/sliders/default-slider

### **2. Table Calendar:**
- GitHub: https://github.com/aleksanderwozniak/table_calendar
- Examples: https://pub.dev/packages/table_calendar/example

### **3. Sticky Headers:**
- GitHub: https://github.com/slightfoot/flutter_sticky_headers
- Pub.dev: https://pub.dev/packages/sticky_headers

### **4. Intl (Format tiền VND):**
- Docs: https://pub.dev/packages/intl
- Number format: https://api.flutter.dev/flutter/intl/NumberFormat-class.html

---

## ✅ CHECKLIST TRƯỚC KHI CODE

- [ ] Đã chạy `flutter pub get` thành công
- [ ] Không có lỗi warning màu đỏ trong Terminal
- [ ] Đã test `flutter run` và app khởi động được
- [ ] Đã import thử các packages vào file test
- [ ] Đã đọc docs của ít nhất 1 package sẽ dùng
- [ ] Đã biết cách format tiền VND với `intl`

---

**Nếu vẫn gặp lỗi không giải quyết được:**
1. Google: "flutter [tên lỗi]"
2. Check GitHub Issues của package
3. Ping Long hoặc hỏi Kiro
4. Worst case: Dùng package thay thế

---

## 📋 Checklist Trước Khi Bắt Đầu

### **Setup Environment:**
- [ ] Clone repo về máy
- [ ] Checkout branch `dung`: `git checkout dung`
- [ ] Pull latest: `git pull origin dung`
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

# 2. Merge vào branch dung
git checkout dung
git merge frontend

# 3. Giải quyết conflict (nếu có)
# 4. Bắt đầu code
```

### **Tối (Sau khi code xong):**
```bash
# 1. Commit code
git add lib/features/wallet/  # Chỉ add feature của mình
git commit -m "feat(wallet): implement smart spending recommendation"

# 2. Push lên branch dung
git push origin dung

# 3. Update checklist trong file này
# 4. Tạo PR nếu đã xong 1 màn hình hoàn chỉnh
```

---

## ✅ Tiến Độ

| Màn Hình | Status | Start Date | End Date | Notes |
|----------|--------|------------|----------|-------|
| Mua Hay Chờ | ⏳ Todo | - | - | - |
| Kế Hoạch Chi Tiêu | ⏳ Todo | - | - | - |
| Nhìn Lại Nhật Ký | ⏳ Todo | - | - | - |

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
4. Ping Long nếu liên quan shared code

### **Best Practices:**
- ✅ Commit nhỏ, thường xuyên
- ✅ Viết tên commit rõ ràng: `feat(wallet): add recommendation logic`
- ✅ Test trên nhiều màn hình (phone/tablet)
- ✅ Comment code phức tạp
- ✅ Extract widgets nhỏ, reusable

### **Performance Tips:**
- Dùng `const` constructor khi có thể
- Avoid nested `setState()`
- Use `ListView.builder` cho list dài
- Debounce search input (delay 300ms)

---

**Good luck, Dũng! 🚀**

---

**Cập nhật lần cuối:** 2026-10-06
