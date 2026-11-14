// ════════════════════════════════════════════════════════════════════
// Domain Models – Mục tiêu tiết kiệm & Quỹ bảo vệ
// ════════════════════════════════════════════════════════════════════

/// Một khoản tiền trong ví được gán cho mục tiêu
class GoalAllocation {
  final String walletId;
  final String walletName;
  final double amount;

  const GoalAllocation({
    required this.walletId,
    required this.walletName,
    required this.amount,
  });
}

/// Mục tiêu tiết kiệm (quỹ bảo vệ)
class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final DateTime? targetAt;
  final bool protect;
  final String status;
  final List<GoalAllocation> allocations;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.targetAt,
    this.protect = true,
    this.status = 'active',
    this.allocations = const [],
  });

  /// Tổng tiền đã phân bổ cho mục tiêu này (cộng mọi ví)
  double get allocated =>
      allocations.fold<double>(0, (s, a) => s + a.amount);

  double get percent =>
      targetAmount > 0 ? (allocated / targetAmount).clamp(0.0, 1.0) : 0;

  int get percentInt => (percent * 100).toInt();

  double get remaining => (targetAmount - allocated).clamp(0, double.infinity);

  bool get isCompleted => targetAmount > 0 && allocated >= targetAmount;

  bool get isActive => status == 'active';

  /// Tiền mục tiêu này đóng góp vào "quỹ bảo vệ".
  /// Chỉ tính khi protect = true — một khoản chỉ được bảo vệ một lần.
  double get protectedAmount => protect ? allocated : 0;

  /// Số ngày còn lại tới hạn (null nếu không đặt hạn)
  int? get daysLeft {
    if (targetAt == null) return null;
    final d = targetAt!.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  /// Số tiền cần để dành mỗi ngày/tháng để kịp hạn
  double? get requiredPerDay {
    final d = daysLeft;
    if (d == null || d <= 0 || remaining <= 0) return null;
    return remaining / d;
  }

  double? allocationIn(String walletId) {
    for (final a in allocations) {
      if (a.walletId == walletId) return a.amount;
    }
    return 0;
  }

  SavingsGoal copyWith({
    String? name,
    double? targetAmount,
    DateTime? targetAt,
    bool? protect,
    String? status,
    List<GoalAllocation>? allocations,
  }) {
    return SavingsGoal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      targetAt: targetAt ?? this.targetAt,
      protect: protect ?? this.protect,
      status: status ?? this.status,
      allocations: allocations ?? this.allocations,
    );
  }
}

/// Ví dùng để chọn khi phân bổ tiền cho mục tiêu
class GoalWalletOption {
  final String id;
  final String name;
  final String type;
  final double balance;

  /// Tiền trong ví đã bị các mục tiêu khác giữ (không được phân bổ lại)
  final double reservedByOthers;

  const GoalWalletOption({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.reservedByOthers = 0,
  });

  /// Còn có thể phân bổ cho mục tiêu đang sửa
  double get allocatable =>
      (balance - reservedByOthers).clamp(0, double.infinity);
}
