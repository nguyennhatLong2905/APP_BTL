/// Models cho màn "Nhìn lại" — tất cả parse từ `/screens/review`, không có
/// giá trị mặc định mang tính minh hoạ. Khi backend không đủ dữ liệu, model
/// giữ `hasEnoughData=false` / danh sách rỗng để UI hiển thị trạng thái trống.
library;

double _num(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

/// Một danh mục chi trong tuần (kèm so sánh tuần trước).
class WeekCategory {
  final String? categoryId;
  final String name;
  final double amount;
  final int count;
  final int? percent;
  final double previousAmount;
  final int? changePercent;

  const WeekCategory({
    this.categoryId,
    required this.name,
    required this.amount,
    required this.count,
    this.percent,
    this.previousAmount = 0,
    this.changePercent,
  });

  factory WeekCategory.fromJson(Map<String, dynamic> j) => WeekCategory(
        categoryId: j['categoryId']?.toString(),
        name: j['name']?.toString() ?? 'Khác',
        amount: _num(j['amount']),
        count: _int(j['count']),
        percent: (j['percent'] as num?)?.round(),
        previousAmount: _num(j['previousAmount']),
        changePercent: (j['changePercent'] as num?)?.round(),
      );
}

/// Tổng chi tuần + so sánh tuần trước + cơ cấu danh mục.
class WeekStats {
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? previousStartAt;
  final double income;
  final double expense;
  final double net;
  final double previousExpense;
  final int? expenseChangePercent;
  final String trend; // 'up' | 'down' | 'flat'
  final WeekCategory? topCategory;
  final List<WeekCategory> categories;
  final bool hasData;
  final List<String> narrative;

  const WeekStats({
    this.startAt,
    this.endAt,
    this.previousStartAt,
    this.income = 0,
    this.expense = 0,
    this.net = 0,
    this.previousExpense = 0,
    this.expenseChangePercent,
    this.trend = 'flat',
    this.topCategory,
    this.categories = const [],
    this.hasData = false,
    this.narrative = const [],
  });

  factory WeekStats.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const WeekStats();
    final cats = (j['categories'] as List?) ?? const [];
    final top = j['topCategory'];
    return WeekStats(
      startAt: _date(j['startAt']),
      endAt: _date(j['endAt']),
      previousStartAt: _date(j['previousStartAt']),
      income: _num(j['income']),
      expense: _num(j['expense']),
      net: _num(j['net']),
      previousExpense: _num(j['previousExpense']),
      expenseChangePercent: (j['expenseChangePercent'] as num?)?.round(),
      trend: j['trend']?.toString() ?? 'flat',
      topCategory:
          top is Map<String, dynamic> ? WeekCategory.fromJson(top) : null,
      categories: cats
          .whereType<Map<String, dynamic>>()
          .map(WeekCategory.fromJson)
          .toList(),
      hasData: j['hasData'] as bool? ?? false,
      narrative: (j['narrative'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  /// Nhãn xu hướng ("Giảm 12%", "Tăng 8%", "Không đổi").
  String get changeLabel {
    if (expenseChangePercent == null) return 'Chưa có dữ liệu tuần trước';
    final p = expenseChangePercent!.abs();
    if (trend == 'up') return 'Tăng $p%';
    if (trend == 'down') return 'Giảm $p%';
    return 'Không đổi';
  }
}

/// Một luận điểm "Thấu hiểu bản thân" kèm căn cứ.
class InsightStatement {
  final String kind; // 'positive' | 'negative'
  final String text;
  final String? categoryId;
  final int percent;
  final int sampleCount;
  final int count;
  final String? rating;
  final List<String> evidenceTransactionIds;

  const InsightStatement({
    required this.kind,
    required this.text,
    this.categoryId,
    required this.percent,
    required this.sampleCount,
    required this.count,
    this.rating,
    this.evidenceTransactionIds = const [],
  });

  bool get isPositive => kind == 'positive';

  factory InsightStatement.fromJson(Map<String, dynamic> j) => InsightStatement(
        kind: j['kind']?.toString() ?? 'positive',
        text: j['text']?.toString() ?? '',
        categoryId: j['categoryId']?.toString(),
        percent: _int(j['percent']),
        sampleCount: _int(j['sampleCount']),
        count: _int(j['count']),
        rating: j['rating']?.toString(),
        evidenceTransactionIds: ((j['evidenceTransactionIds'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class InsightGroup {
  final String? categoryId;
  final String name;
  final int sampleCount;
  final int worthIt;
  final int reconsider;
  final int neutral;
  final int worthItPercent;
  final int reconsiderPercent;

  const InsightGroup({
    this.categoryId,
    required this.name,
    required this.sampleCount,
    required this.worthIt,
    required this.reconsider,
    required this.neutral,
    required this.worthItPercent,
    required this.reconsiderPercent,
  });

  factory InsightGroup.fromJson(Map<String, dynamic> j) => InsightGroup(
        categoryId: j['categoryId']?.toString(),
        name: j['name']?.toString() ?? 'Khác',
        sampleCount: _int(j['sampleCount']),
        worthIt: _int(j['worthIt']),
        reconsider: _int(j['reconsider']),
        neutral: _int(j['neutral']),
        worthItPercent: _int(j['worthItPercent']),
        reconsiderPercent: _int(j['reconsiderPercent']),
      );
}

class SelfInsight {
  final int sampleCount;
  final bool hasEnoughData;
  final int minimumSamples;
  final List<InsightStatement> statements;
  final List<InsightGroup> groups;

  const SelfInsight({
    this.sampleCount = 0,
    this.hasEnoughData = false,
    this.minimumSamples = 3,
    this.statements = const [],
    this.groups = const [],
  });

  factory SelfInsight.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SelfInsight();
    return SelfInsight(
      sampleCount: _int(j['sampleCount']),
      hasEnoughData: j['hasEnoughData'] as bool? ?? false,
      minimumSamples: _int(j['minimumSamples']) == 0
          ? 3
          : _int(j['minimumSamples']),
      statements: ((j['statements'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(InsightStatement.fromJson)
          .toList(),
      groups: ((j['groups'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(InsightGroup.fromJson)
          .toList(),
    );
  }
}

/// Gợi ý ngân sách (không tự áp dụng).
class BudgetSuggestion {
  final String kind; // 'increase_limit' | 'decrease_limit'
  final String? categoryId;
  final String categoryName;
  final String? budgetId;
  final double currentLimit;
  final double proposedLimit;
  final int? usedPercent;
  final String reason;
  final List<String> evidenceTransactionIds;
  final double evidenceSpend;

  const BudgetSuggestion({
    required this.kind,
    this.categoryId,
    required this.categoryName,
    this.budgetId,
    required this.currentLimit,
    required this.proposedLimit,
    this.usedPercent,
    required this.reason,
    this.evidenceTransactionIds = const [],
    this.evidenceSpend = 0,
  });

  bool get isIncrease => kind == 'increase_limit';

  factory BudgetSuggestion.fromJson(Map<String, dynamic> j) => BudgetSuggestion(
        kind: j['kind']?.toString() ?? 'increase_limit',
        categoryId: j['categoryId']?.toString(),
        categoryName: j['categoryName']?.toString() ?? 'Khác',
        budgetId: j['budgetId']?.toString(),
        currentLimit: _num(j['currentLimit']),
        proposedLimit: _num(j['proposedLimit']),
        usedPercent: (j['usedPercent'] as num?)?.round(),
        reason: j['reason']?.toString() ?? '',
        evidenceTransactionIds: ((j['evidenceTransactionIds'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        evidenceSpend: _num(j['evidenceSpend']),
      );
}

/// Mức dùng hạn mức của một danh mục — dùng khi chưa có gợi ý để UI vẫn hữu ích.
class BudgetUsage {
  final String? categoryId;
  final String categoryName;
  final double limit;
  final double spent;
  final int? percent;
  final int transactions;

  const BudgetUsage({
    this.categoryId,
    required this.categoryName,
    this.limit = 0,
    this.spent = 0,
    this.percent,
    this.transactions = 0,
  });

  factory BudgetUsage.fromJson(Map<String, dynamic> j) => BudgetUsage(
        categoryId: j['categoryId']?.toString(),
        categoryName: j['categoryName']?.toString() ?? 'Khác',
        limit: _num(j['limit']),
        spent: _num(j['spent']),
        percent: (j['percent'] as num?)?.round(),
        transactions: _int(j['transactions']),
      );
}

/// Lý do chưa có gợi ý (backend xác định từ dữ liệu thật).
class BudgetEmptyReason {
  final String code; // no_budget | no_spending | no_ratings | balanced
  final String reason;
  final String nextStep;

  const BudgetEmptyReason({
    required this.code,
    required this.reason,
    required this.nextStep,
  });

  factory BudgetEmptyReason.fromJson(Map<String, dynamic> j) =>
      BudgetEmptyReason(
        code: j['code']?.toString() ?? 'balanced',
        reason: j['reason']?.toString() ?? '',
        nextStep: j['nextStep']?.toString() ?? '',
      );
}

class BudgetSuggestionSet {
  final String? budgetId;
  final String? budgetName;
  final bool hasBudget;
  final List<BudgetSuggestion> suggestions;
  final List<BudgetUsage> usage;
  final BudgetEmptyReason? emptyReason;

  const BudgetSuggestionSet({
    this.budgetId,
    this.budgetName,
    this.hasBudget = false,
    this.suggestions = const [],
    this.usage = const [],
    this.emptyReason,
  });

  factory BudgetSuggestionSet.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const BudgetSuggestionSet();
    final reason = j['emptyReason'];
    return BudgetSuggestionSet(
      budgetId: j['budgetId']?.toString(),
      budgetName: j['budgetName']?.toString(),
      hasBudget: j['hasBudget'] as bool? ?? false,
      suggestions: ((j['suggestions'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BudgetSuggestion.fromJson)
          .toList(),
      usage: ((j['usage'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BudgetUsage.fromJson)
          .toList(),
      emptyReason: reason is Map<String, dynamic>
          ? BudgetEmptyReason.fromJson(reason)
          : null,
    );
  }
}

/// Giao dịch làm căn cứ hoặc ứng viên theo dõi.
class EvidenceTransaction {
  final String id;
  final double amount;
  final DateTime? occurredAt;
  final String? note;
  final String? categoryName;

  const EvidenceTransaction({
    required this.id,
    required this.amount,
    this.occurredAt,
    this.note,
    this.categoryName,
  });

  factory EvidenceTransaction.fromJson(Map<String, dynamic> j) =>
      EvidenceTransaction(
        id: j['_id']?.toString() ?? '',
        amount: _num(j['amount']),
        occurredAt: _date(j['occurredAt']),
        note: j['note']?.toString(),
        categoryName: j['categoryName']?.toString(),
      );
}

/// Một tuần có thể chọn cho báo cáo.
class ReviewWeek {
  final DateTime startAt;
  final DateTime endAt;
  final String label;

  const ReviewWeek({
    required this.startAt,
    required this.endAt,
    required this.label,
  });

  factory ReviewWeek.fromJson(Map<String, dynamic> j) => ReviewWeek(
        startAt: _date(j['startAt']) ?? DateTime.now(),
        endAt: _date(j['endAt']) ?? DateTime.now(),
        label: j['label']?.toString() ?? '',
      );

  String get isoStart => startAt.toUtc().toIso8601String();
  String get isoEnd => endAt.toUtc().toIso8601String();
}

/// Trạng thái nhật ký suy ra từ backend — không có giá trị tự gán.
enum JournalState {
  /// Giao dịch chi mới, chưa đủ số ngày chờ (mặc định 7).
  tracking,

  /// Đã đủ 7 ngày, đang chờ người dùng đánh giá.
  awaitingReview,

  /// Người dùng đã chọn một mức đánh giá.
  rated,

  /// Người dùng chủ động bỏ qua.
  skipped;

  static JournalState parse(dynamic raw) {
    switch (raw?.toString()) {
      case 'awaiting_review':
        return JournalState.awaitingReview;
      case 'rated':
        return JournalState.rated;
      case 'skipped':
        return JournalState.skipped;
      default:
        return JournalState.tracking;
    }
  }

  String get apiValue => switch (this) {
        JournalState.tracking => 'tracking',
        JournalState.awaitingReview => 'awaiting_review',
        JournalState.rated => 'rated',
        JournalState.skipped => 'skipped',
      };

  String get label => switch (this) {
        JournalState.tracking => 'Đang theo dõi',
        JournalState.awaitingReview => 'Chờ đánh giá',
        JournalState.rated => 'Đã đánh giá',
        JournalState.skipped => 'Đã bỏ qua',
      };
}

/// Tóm tắt số lượng theo trạng thái — dùng cho empty state và tiêu đề nhóm.
class JournalSummary {
  final int total;
  final int tracking;
  final int awaitingReview;
  final int rated;
  final int skipped;

  const JournalSummary({
    this.total = 0,
    this.tracking = 0,
    this.awaitingReview = 0,
    this.rated = 0,
    this.skipped = 0,
  });

  int get reviewed => rated + skipped;

  /// Còn giao dịch chưa được người dùng xử lý (kể cả chưa đủ 7 ngày).
  bool get hasUnresolved => tracking + awaitingReview > 0;

  factory JournalSummary.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const JournalSummary();
    return JournalSummary(
      total: _int(j['total']),
      tracking: _int(j['tracking']),
      awaitingReview: _int(j['awaitingReview']),
      rated: _int(j['rated']),
      skipped: _int(j['skipped']),
    );
  }
}

/// Một mục trong Nhật ký Đáng tiền, dựng từ giao dịch thật.
///
/// Nhật ký được backend tạo tự động cho mọi giao dịch chi, nên UI chỉ hiển thị
/// và cho đánh giá/bỏ qua; không có hành động "thêm vào nhật ký".
class JournalEntry {
  final String id; // reflection id, hoặc transaction id với dữ liệu cũ
  final String transactionId;
  final JournalState state;
  final String? rating; // worth_it | neutral | reconsider
  final String? note; // ghi chú đánh giá
  final String? transactionNote; // ghi chú giao dịch gốc
  final double amount;
  final DateTime? occurredAt;
  final DateTime? dueAt;
  final DateTime? ratedAt;
  final String? categoryId;
  final String? categoryName;
  final int daysRemaining;

  const JournalEntry({
    required this.id,
    required this.transactionId,
    required this.state,
    this.rating,
    this.note,
    this.transactionNote,
    this.amount = 0,
    this.occurredAt,
    this.dueAt,
    this.ratedAt,
    this.categoryId,
    this.categoryName,
    this.daysRemaining = 0,
  });

  bool get isTracking => state == JournalState.tracking;
  bool get isAwaitingReview => state == JournalState.awaitingReview;
  bool get isRated => state == JournalState.rated;
  bool get isSkipped => state == JournalState.skipped;

  /// Tiêu đề hiển thị: ghi chú giao dịch, nếu không có thì tên danh mục.
  String get title =>
      (transactionNote?.trim().isNotEmpty ?? false)
          ? transactionNote!.trim()
          : (categoryName ?? 'Chi tiêu');

  String get categoryLabel => categoryName ?? 'Chi tiêu';

  String get dateText {
    final d = occurredAt;
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Nhãn đếm ngược: "Còn 3 ngày" / "Đến hạn đánh giá".
  String get countdownLabel {
    if (!isTracking) return state.label;
    if (daysRemaining <= 0) return 'Đến hạn đánh giá';
    return 'Còn $daysRemaining ngày trước khi đánh giá';
  }

  String get ratingLabel {
    switch (rating) {
      case 'worth_it':
        return 'Đáng tiền';
      case 'neutral':
        return 'Bình thường';
      case 'reconsider':
        return 'Muốn cân nhắc lại';
      default:
        return isSkipped ? 'Đã bỏ qua' : 'Chưa đánh giá';
    }
  }

  factory JournalEntry.fromJson(Map<String, dynamic> j) {
    final tx = (j['transaction'] as Map<String, dynamic>?) ?? const {};
    return JournalEntry(
      id: j['_id']?.toString() ?? '',
      transactionId: j['transactionId']?.toString() ?? '',
      state: JournalState.parse(j['state'] ?? j['status']),
      rating: j['rating']?.toString(),
      note: j['note']?.toString(),
      transactionNote: tx['note']?.toString(),
      amount: _num(tx['amount']),
      occurredAt: _date(tx['occurredAt']),
      dueAt: _date(j['dueAt']),
      ratedAt: _date(j['ratedAt']),
      categoryId: tx['categoryId']?.toString() ?? j['categoryId']?.toString(),
      categoryName:
          tx['categoryName']?.toString() ?? j['categoryName']?.toString(),
      daysRemaining: _int(j['daysRemaining']),
    );
  }
}

/// Nhật ký đã đánh giá/bỏ qua (lịch sử).
class ReflectionRecord {
  final String id;
  final String status; // pending | rated | skipped
  final String? rating; // worth_it | neutral | reconsider
  final String? note;
  final DateTime? dueAt;
  final DateTime? ratedAt;
  final String transactionId;
  final double amount;
  final DateTime? occurredAt;
  final String? transactionNote;
  final String? categoryName;

  const ReflectionRecord({
    required this.id,
    required this.status,
    this.rating,
    this.note,
    this.dueAt,
    this.ratedAt,
    required this.transactionId,
    this.amount = 0,
    this.occurredAt,
    this.transactionNote,
    this.categoryName,
  });

  bool get isRated => status == 'rated';
  bool get isSkipped => status == 'skipped';
  bool get isPending => status == 'pending';

  String get ratingLabel {
    switch (rating) {
      case 'worth_it':
        return 'Đáng tiền';
      case 'neutral':
        return 'Bình thường';
      case 'reconsider':
        return 'Muốn cân nhắc lại';
      default:
        return isSkipped ? 'Đã bỏ qua' : 'Chưa đánh giá';
    }
  }

  factory ReflectionRecord.fromJson(Map<String, dynamic> j) {
    final tx = (j['transaction'] as Map<String, dynamic>?) ?? const {};
    final state = j['state']?.toString();
    return ReflectionRecord(
      id: j['_id']?.toString() ?? '',
      status: j['status']?.toString() ??
          (state == 'awaiting_review' ? 'pending' : state ?? 'pending'),
      rating: j['rating']?.toString(),
      note: j['note']?.toString(),
      dueAt: _date(j['dueAt']),
      ratedAt: _date(j['ratedAt']),
      transactionId: j['transactionId']?.toString() ?? '',
      amount: _num(tx['amount']),
      occurredAt: _date(tx['occurredAt']),
      transactionNote: tx['note']?.toString(),
      categoryName:
          tx['categoryName']?.toString() ?? j['categoryName']?.toString(),
    );
  }
}
