import '../domain/models/receipt.dart';

typedef ParsedReceipt = ({
  String merchant,
  DateTime? date,
  int? total,
  List<ReceiptLine> lines,
});

final _price = RegExp(
  r'(?:^|\s|:)\s*([+-]?(?:\d{1,3}(?:[., ]\d{3})+|\d{1,16})(?:[.,]00)?)\s*(?:vnd|vnđ|đ|₫|dong|d)?\s*$',
  caseSensitive: false,
);
final _date = RegExp(r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4}|\d{2})\b');
final _isoDate = RegExp(r'\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})\b');
final _time = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?\b');
final _letters = RegExp(r'\p{L}', unicode: true);
final _sku = RegExp(r'^[A-Z]{1,8}[-_]?\d{2,}[A-Z0-9_-]*\s*');
final _columns = RegExp(r'\s{2,}');
final _total = RegExp(
  r'^(?:(?:tong(?: so tien)?\s+)?(?:tien\s+)?phai tra|tong thanh toan|tong tien thanh toan|tong cong|grand total|amount due|total due|tong tien|total)\b',
);
final _nonItem = RegExp(
  r'^(?:tam tinh|subtotal|sub total|cong tien hang|tong (?:cong |)tien hang|tong cong truoc thue|tien hang|da thanh toan|con no|tien mat|cash|tien thua|tien tra lai|tra lai|change|khach (?:dua|tra|thanh toan)|tien khach|vat|thue|giam gia|chiet khau|phi |phu phi|discount|tax|dia chi|dt\b|sdt\b|tel\b|mst\b|so\b|ma\b|khach hang|ngay\b|gio\b|cam on|nguoi |hoa don|phieu |receipt|invoice|ten hang|mat hang|san pham\s+sl|\d+\s+(?:duong|ngo|pho)\b)',
);

final _plainLetters = <String, String>{
  for (final (plain, accents) in [
    ('a', 'áàảãạăắằẳẵặâấầẩẫậ'),
    ('e', 'éèẻẽẹêếềểễệ'),
    ('i', 'íìỉĩị'),
    ('o', 'óòỏõọôốồổỗộơớờởỡợ'),
    ('u', 'úùủũụưứừửữự'),
    ('y', 'ýỳỷỹỵ'),
    ('d', 'đ'),
  ])
    for (final letter in accents.split('')) letter: plain,
};

String _fold(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'\p{M}', unicode: true), '')
      .split('')
      .map((letter) => _plainLetters[letter] ?? letter)
      .join()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

int? _amount(RegExpMatch? match) {
  if (match == null) return null;
  final token = match[1]!;
  final whole = token.replaceFirst(RegExp(r'[.,]00$'), '');
  final value = int.tryParse(whole.replaceAll(RegExp(r'[., ]'), ''));
  return value != null && value >= 0 && value <= 999999999999999 ? value : null;
}

String _itemName(String prefix) {
  final cells = prefix.trim().replaceFirst(_sku, '').split(_columns);
  final name = cells.firstWhere(
    (cell) => _letters.hasMatch(cell),
    orElse: () => '',
  );
  return name
      .replaceFirst(RegExp(r'^\d+\s*[.)]\s*'), '')
      .replaceFirst(
        RegExp(r'\s+(?:\d+\s*(?:x|×)\s*)?\d{1,3}(?:[.,]\d{3})+(?:\s+\d+)?$'),
        '',
      )
      .replaceFirst(RegExp(r'\s+\d+\s*(?:x|×)?$'), '')
      .trim();
}

String _short(String value) => String.fromCharCodes(value.runes.take(160));

ParsedReceipt parseReceipt(String text) {
  final rows = text
      .split('\n')
      .map((row) => row.trim())
      .where((row) => row.isNotEmpty)
      .toList();
  var merchant = '';
  int? year, month, day, total;
  var totalPriority = 0;
  RegExpMatch? time;
  final items = <ReceiptLine>[];

  for (var index = 0; index < rows.length; index++) {
    final row = rows[index];
    final label = _fold(row);
    final localDate = _date.firstMatch(row);
    final isoDate = _isoDate.firstMatch(row);
    if (day == null && (localDate != null || isoDate != null)) {
      if (isoDate != null) {
        year = int.parse(isoDate[1]!);
        month = int.parse(isoDate[2]!);
        day = int.parse(isoDate[3]!);
      } else {
        day = int.parse(localDate![1]!);
        month = int.parse(localDate[2]!);
        year = int.parse(localDate[3]!);
        if (year < 100) year += 2000;
      }
    }
    time ??= _time.firstMatch(row);

    final price = _price.firstMatch(row);
    final totalLabel = _total.firstMatch(label);
    if (totalLabel != null && !_nonItem.hasMatch(label)) {
      final next = index + 1 < rows.length ? rows[index + 1] : '';
      final nextPrice = _price.firstMatch(next);
      final amount =
          _amount(price) ?? (nextPrice?.start == 0 ? _amount(nextPrice) : null);
      final priority = switch (totalLabel[0]) {
        'tong tien' || 'total' => 1,
        'tong cong' => 2,
        _ => 3,
      };
      if (amount != null && amount > 0 && priority >= totalPriority) {
        total = amount;
        totalPriority = priority;
      }
      continue;
    }
    if (_nonItem.hasMatch(label) || localDate != null || isoDate != null) {
      continue;
    }
    if (price == null) {
      if (merchant.isEmpty &&
          items.isEmpty &&
          _letters.allMatches(row).length >= 3) {
        merchant = _short(row.split(_columns).first);
      }
      continue;
    }
    final amount = _amount(price);
    // The last cell is the line total, not the unit price or quantity.
    final name = _itemName(row.substring(0, price.start));
    if (amount != null &&
        name.isNotEmpty &&
        items.length < ReceiptLine.maxCount) {
      items.add(ReceiptLine(_short(name), amount));
    }
  }

  DateTime? date;
  if (year != null && month != null && day != null && year >= 1900) {
    final parsed = DateTime(
      year,
      month,
      day,
      int.parse(time?[1] ?? '0'),
      int.parse(time?[2] ?? '0'),
      int.parse(time?[3] ?? '0'),
    );
    if (parsed.day == day && parsed.month == month) date = parsed;
  }
  return (merchant: merchant, date: date, total: total, lines: items);
}
