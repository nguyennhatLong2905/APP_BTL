enum DecisionType {
  buy,
  wait,
}

class SpendingDecision {
  final String id;
  final String itemName;
  final double itemPrice;
  final DecisionType decision;
  final String reason;
  final double percentageOfBalance;
  final List<String> alternativeSuggestions;
  final DateTime createdAt;

  const SpendingDecision({
    required this.id,
    required this.itemName,
    required this.itemPrice,
    required this.decision,
    required this.reason,
    required this.percentageOfBalance,
    this.alternativeSuggestions = const [],
    required this.createdAt,
  });

  bool get isBuy => decision == DecisionType.buy;
}
