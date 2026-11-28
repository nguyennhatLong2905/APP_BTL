class ReceiptLine {
  static const maxCount = 100;

  final String name;
  final int amount;

  const ReceiptLine(this.name, this.amount);

  Map<String, String> toJson() => {'name': name, 'amount': amount.toString()};

  static List<ReceiptLine> readList(Object? value) {
    if (value is! List) return const [];
    return [
      for (final row in value.whereType<Map>())
        if ((row['name'], int.tryParse(row['amount'].toString())) case (
          final String name,
          final int amount,
        ))
          ReceiptLine(name, amount),
    ];
  }
}
