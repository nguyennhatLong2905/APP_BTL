import '../models/spending_decision.dart';
import '../models/wallet_balance.dart';

class RecommendationService {
  SpendingDecision evaluatePurchase({
    required String itemName,
    required double itemPrice,
    required WalletBalance balance,
  }) {
    if (itemPrice <= 0) {
      return SpendingDecision(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemName: itemName,
        itemPrice: itemPrice,
        decision: DecisionType.wait,
        reason: 'Giá trị món đồ phải lớn hơn 0 ₫.',
        percentageOfBalance: 0,
        createdAt: DateTime.now(),
      );
    }

    final double balancePercentage = balance.currentBalance > 0
        ? (itemPrice / balance.currentBalance) * 100
        : 100;
    final double remainingBudget = balance.remainingBudget;
    final double budgetAfterPurchase = remainingBudget - itemPrice;

    DecisionType decision;
    String reason;
    List<String> alternatives = [];

    if (itemPrice > balance.currentBalance) {
      decision = DecisionType.wait;
      reason =
          'Giá trị món đồ (VND) vượt quá số dư hiện tại trong ví của bạn!';
      alternatives = [
        'Tìm kiếm sản phẩm đã qua sử dụng (2nd hand)',
        'Chờ đợt giảm giá sale lớn sắp tới',
        'Lên kế hoạch tiết kiệm thêm trong 1-2 tháng',
      ];
    } else if (balancePercentage > 30) {
      decision = DecisionType.wait;
      reason =
          'Món đồ này chiếm ${balancePercentage.toStringAsFixed(1)}% tổng số dư hiện có. Mua ngay có thể gây rủi ro tài chính!';
      alternatives = [
        'Áp dụng quy tắc hoãn mua 72 giờ',
        'Xem xét phiên bản/thương hiệu thay thế giá tốt hơn',
        'Sử dụng mã giảm giá hoặc tích điểm thưởng',
      ];
    } else if (budgetAfterPurchase < (balance.monthlyBudget * 0.15)) {
      decision = DecisionType.wait;
      reason =
          'Sau khi mua, bạn chỉ còn lại dưới 15% ngân sách tháng. Cần dự phòng cho các chi phí cố định!';
      alternatives = [
        'Trì hoãn mua sang tháng sau',
        'Chỉ mua khi đây là nhu cầu cấp thiết',
      ];
    } else {
      decision = DecisionType.buy;
      reason =
          'Tình hình tài chính ổn định! Món đồ chỉ chiếm ${balancePercentage.toStringAsFixed(1)}% số dư và nằm trong ngân sách cho phép.';
      alternatives = [
        'Nên so sánh giá tại các cửa hàng khác trước khi thanh toán',
        'Kiểm tra lại xem có mã voucher hoàn tiền không',
      ];
    }

    return SpendingDecision(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemName: itemName,
      itemPrice: itemPrice,
      decision: decision,
      reason: reason,
      percentageOfBalance: balancePercentage,
      alternativeSuggestions: alternatives,
      createdAt: DateTime.now(),
    );
  }
}
