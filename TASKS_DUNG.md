# 👨‍💻 Công Việc Của Dũng

> **Branch:** `dung`  
> **Tổng màn hình:** 3  
> **Độ ưu tiên:** Làm theo thứ tự P1 → P2

---

## 📱 Danh Sách Màn Hình

### ✅ 1. Mua Hay Chờ (Smart Spending) - `P1` ⭐⭐⭐

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

### ✅ 2. Kế Hoạch Chi Tiêu (Budget Planning) - `P1` ⭐⭐⭐⭐

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

### ✅ 3. Nhìn Lại Nhật Ký (Transaction Timeline) - `P2` ⭐⭐⭐

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

## 📋 Checklist Trước Khi Bắt Đầu

### **Setup Environment:**
- [ ] Clone repo về máy
- [ ] Checkout branch `dung`: `git checkout -b dung`
- [ ] Push branch lên: `git push -u origin dung`
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

## 📦 Dependencies Cần Thêm

Thêm vào `pubspec.yaml`:

```yaml
dependencies:
  # State Management (đã có)
  flutter_riverpod: ^2.0.0
  
  # UI Components
  syncfusion_flutter_sliders: ^24.0.0  # Drag slider cho budget
  table_calendar: ^3.0.9  # Calendar view
  sticky_headers: ^0.3.0  # Sticky headers
  
  # Utils
  intl: ^0.19.0  # Format tiền VND (đã có ở Long)
```

Run:
```bash
flutter pub add syncfusion_flutter_sliders table_calendar sticky_headers
```

---

**Good luck, Dũng! 🚀**

---

**Cập nhật lần cuối:** 2026-10-06
