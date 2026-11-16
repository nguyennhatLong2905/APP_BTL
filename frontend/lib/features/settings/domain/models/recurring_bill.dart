import 'package:flutter/material.dart';

/// Trạng thái nghiệp vụ của một kỳ hóa đơn.
/// `upcoming`/`due`/`overdue` được backend suy ra từ ngày hiện tại;
/// `paid`/`cancelled` là trạng thái được lưu.
enum BillStatus { upcoming, due, overdue, paid, cancelled }

BillStatus billStatusFrom(String? raw) {
  switch (raw) {
    case 'paid':
      return BillStatus.paid;
    case 'cancelled':
      return BillStatus.cancelled;
    case 'overdue':
      return BillStatus.overdue;
    case 'due':
      return BillStatus.due;
    default:
      return BillStatus.upcoming;
  }
}

extension BillStatusX on BillStatus {
  String get label {
    switch (this) {
      case BillStatus.upcoming:
        return 'Chưa trả';
      case BillStatus.due:
        return 'Đến hạn';
      case BillStatus.overdue:
        return 'Quá hạn';
      case BillStatus.paid:
        return 'Đã trả';
      case BillStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Color get fg {
    switch (this) {
      case BillStatus.upcoming:
        return const Color(0xFF0F5B47);
      case BillStatus.due:
        return const Color(0xFFB45309);
      case BillStatus.overdue:
        return const Color(0xFFB91C1C);
      case BillStatus.paid:
        return const Color(0xFF15803D);
      case BillStatus.cancelled:
        return const Color(0xFF6B7280);
    }
  }

  Color get bg {
    switch (this) {
      case BillStatus.upcoming:
        return const Color(0xFFE2F6F0);
      case BillStatus.due:
        return const Color(0xFFFEF3C7);
      case BillStatus.overdue:
        return const Color(0xFFFEE2E2);
      case BillStatus.paid:
        return const Color(0xFFDCFCE7);
      case BillStatus.cancelled:
        return const Color(0xFFF3F4F6);
    }
  }

  bool get isUnpaid =>
      this == BillStatus.upcoming ||
      this == BillStatus.due ||
      this == BillStatus.overdue;
}

/// Chu kỳ lặp của hóa đơn định kỳ (map 1-1 với enum backend).
enum BillFrequency { once, weekly, monthly, quarterly, yearly }

BillFrequency billFrequencyFrom(String? raw) {
  switch (raw) {
    case 'weekly':
      return BillFrequency.weekly;
    case 'quarterly':
      return BillFrequency.quarterly;
    case 'yearly':
      return BillFrequency.yearly;
    case 'monthly':
      return BillFrequency.monthly;
    default:
      return BillFrequency.once;
  }
}

extension BillFrequencyX on BillFrequency {
  String get apiValue {
    switch (this) {
      case BillFrequency.once:
        return 'once';
      case BillFrequency.weekly:
        return 'weekly';
      case BillFrequency.monthly:
        return 'monthly';
      case BillFrequency.quarterly:
        return 'quarterly';
      case BillFrequency.yearly:
        return 'yearly';
    }
  }

  String get label {
    switch (this) {
      case BillFrequency.once:
        return 'Không lặp';
      case BillFrequency.weekly:
        return 'Hàng tuần';
      case BillFrequency.monthly:
        return 'Hàng tháng';
      case BillFrequency.quarterly:
        return 'Hàng quý';
      case BillFrequency.yearly:
        return 'Hàng năm';
    }
  }

  bool get isRecurring => this != BillFrequency.once;
}

/// Một kỳ hóa đơn, parse từ /screens/bills.
class RecurringBill {
  final String id;
  final String? templateId;
  final String name;
  final double amount;
  final double? paidAmount;
  final String categoryId;
  final DateTime dueAt;
  final BillStatus status;
  final DateTime? paidAt;
  final String? transactionId;
  final String? paymentMethod;
  final String frequency;
  final bool templateActive;
  final DateTime? templateStartAt;
  final DateTime? templateEndAt;
  final int reminderDaysBefore;
  final String? note;
  final int daysUntilDue;

  const RecurringBill({
    required this.id,
    this.templateId,
    required this.name,
    required this.amount,
    this.paidAmount,
    required this.categoryId,
    required this.dueAt,
    required this.status,
    this.paidAt,
    this.transactionId,
    this.paymentMethod,
    this.frequency = 'once',
    this.templateActive = false,
    this.templateStartAt,
    this.templateEndAt,
    this.reminderDaysBefore = 0,
    this.note,
    this.daysUntilDue = 0,
  });

  BillFrequency get frequencyEnum => billFrequencyFrom(frequency);

  static DateTime? _parse(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  factory RecurringBill.fromJson(Map<String, dynamic> j) {
    return RecurringBill(
      id: j['_id']?.toString() ?? '',
      templateId: j['templateId']?.toString(),
      name: j['name']?.toString() ?? 'Hóa đơn',
      amount: _num(j['amount']),
      paidAmount: j['paidAmount'] == null ? null : _num(j['paidAmount']),
      categoryId: j['categoryId']?.toString() ?? '',
      dueAt: _parse(j['dueAt']) ?? DateTime.now(),
      status: billStatusFrom(
        j['derivedStatus']?.toString() ?? j['status']?.toString(),
      ),
      paidAt: _parse(j['paidAt']),
      transactionId: j['transactionId']?.toString(),
      paymentMethod: j['paymentMethod']?.toString(),
      frequency: j['frequency']?.toString() ?? 'once',
      templateActive: j['templateActive'] as bool? ?? false,
      templateStartAt: _parse(j['templateStartAt']),
      templateEndAt: _parse(j['templateEndAt']),
      reminderDaysBefore: (j['reminderDaysBefore'] as num?)?.toInt() ?? 0,
      note: j['note']?.toString(),
      daysUntilDue: (j['daysUntilDue'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Tổng quan tab Hóa đơn.
class BillsSummary {
  final int total;
  final int unpaidCount;
  final int upcomingCount;
  final int dueCount;
  final int overdueCount;
  final int paidCount;
  final double unpaidTotal;
  final double overdueTotal;
  final double dueTotal;
  final double paidTotal;

  const BillsSummary({
    this.total = 0,
    this.unpaidCount = 0,
    this.upcomingCount = 0,
    this.dueCount = 0,
    this.overdueCount = 0,
    this.paidCount = 0,
    this.unpaidTotal = 0,
    this.overdueTotal = 0,
    this.dueTotal = 0,
    this.paidTotal = 0,
  });

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  factory BillsSummary.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const BillsSummary();
    int i(dynamic v) => (v as num?)?.toInt() ?? 0;
    return BillsSummary(
      total: i(j['total']),
      unpaidCount: i(j['unpaidCount']),
      upcomingCount: i(j['upcomingCount']),
      dueCount: i(j['dueCount']),
      overdueCount: i(j['overdueCount']),
      paidCount: i(j['paidCount']),
      unpaidTotal: _num(j['unpaidTotal']),
      overdueTotal: _num(j['overdueTotal']),
      dueTotal: _num(j['dueTotal']),
      paidTotal: _num(j['paidTotal']),
    );
  }
}

/// Kết quả xem trước thanh toán (tác động 3 lớp).
class BillPayPreview {
  final double amount;
  final double reservedAmount;
  final double releasedReservation;
  final double excessOverReserved;
  final double beforeTotal;
  final double beforeProtected;
  final double beforeUnpaidBills;
  final double beforeAvailable;
  final double afterTotal;
  final double afterProtected;
  final double afterUnpaidBills;
  final double afterAvailable;
  final bool requiresConfirmation;
  final List<String> warnings;

  const BillPayPreview({
    required this.amount,
    required this.reservedAmount,
    required this.releasedReservation,
    required this.excessOverReserved,
    required this.beforeTotal,
    required this.beforeProtected,
    required this.beforeUnpaidBills,
    required this.beforeAvailable,
    required this.afterTotal,
    required this.afterProtected,
    required this.afterUnpaidBills,
    required this.afterAvailable,
    required this.requiresConfirmation,
    required this.warnings,
  });

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  factory BillPayPreview.fromJson(Map<String, dynamic> j) {
    final before = (j['before'] as Map<String, dynamic>?) ?? {};
    final after = (j['after'] as Map<String, dynamic>?) ?? {};
    return BillPayPreview(
      amount: _num(j['amount']),
      reservedAmount: _num(j['reservedAmount']),
      releasedReservation: _num(j['releasedReservation']),
      excessOverReserved: _num(j['excessOverReserved']),
      beforeTotal: _num(before['total']),
      beforeProtected: _num(before['protectedMoney']),
      beforeUnpaidBills: _num(before['unpaidBills']),
      beforeAvailable: _num(before['available']),
      afterTotal: _num(after['total']),
      afterProtected: _num(after['protectedMoney']),
      afterUnpaidBills: _num(after['unpaidBills']),
      afterAvailable: _num(after['available']),
      requiresConfirmation: j['requiresConfirmation'] as bool? ?? false,
      warnings: (j['warnings'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

/// Giao dịch chi ứng viên để liên kết hóa đơn.
class BillCandidateTransaction {
  final String id;
  final double amount;
  final DateTime occurredAt;
  final String? note;
  final int version;

  const BillCandidateTransaction({
    required this.id,
    required this.amount,
    required this.occurredAt,
    this.note,
    required this.version,
  });

  factory BillCandidateTransaction.fromJson(Map<String, dynamic> j) {
    return BillCandidateTransaction(
      id: j['_id']?.toString() ?? '',
      amount: BillPayPreview._num(j['amount']),
      occurredAt:
          DateTime.tryParse(j['occurredAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      note: j['note']?.toString(),
      version: (j['version'] as num?)?.toInt() ?? 1,
    );
  }
}
