import 'package:flutter/material.dart';
import 'package:flutter_riverpod_clean_architecture/features/settings/domain/models/recurring_bill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillStatus mapping', () {
    test('derivedStatus ưu tiên hơn status gốc', () {
      final bill = RecurringBill.fromJson({
        '_id': 'abc',
        'name': 'Tiền nhà',
        'amount': '3000000',
        'dueAt': '2026-10-05T00:00:00+07:00',
        'status': 'unpaid',
        'derivedStatus': 'overdue',
        'daysUntilDue': -5,
        'frequency': 'monthly',
      });
      expect(bill.status, BillStatus.overdue);
      expect(bill.status.label, 'Quá hạn');
      expect(bill.status.isUnpaid, isTrue);
      expect(bill.daysUntilDue, -5);
      expect(bill.frequencyEnum, BillFrequency.monthly);
    });

    test('paid không bị coi là chưa trả', () {
      final bill = RecurringBill.fromJson({
        '_id': 'x',
        'name': 'X',
        'amount': '100',
        'dueAt': '2026-10-05T00:00:00+07:00',
        'status': 'paid',
        'derivedStatus': 'paid',
        'paidAmount': '100',
      });
      expect(bill.status, BillStatus.paid);
      expect(bill.status.isUnpaid, isFalse);
    });

    test('cancelled giữ nguyên trạng thái', () {
      final bill = RecurringBill.fromJson({
        '_id': 'c',
        'name': 'C',
        'amount': '1',
        'dueAt': '2026-10-05T00:00:00+07:00',
        'status': 'cancelled',
        'derivedStatus': 'cancelled',
      });
      expect(bill.status, BillStatus.cancelled);
      expect(bill.status.isUnpaid, isFalse);
    });
  });

  group('BillFrequency', () {
    test('chu kỳ map đúng sang API value', () {
      expect(BillFrequency.once.apiValue, 'once');
      expect(BillFrequency.weekly.apiValue, 'weekly');
      expect(BillFrequency.monthly.apiValue, 'monthly');
      expect(BillFrequency.quarterly.apiValue, 'quarterly');
      expect(BillFrequency.yearly.apiValue, 'yearly');
      expect(BillFrequency.once.isRecurring, isFalse);
      expect(BillFrequency.quarterly.isRecurring, isTrue);
    });

    test('label tiếng Việt', () {
      expect(BillFrequency.weekly.label, 'Hàng tuần');
      expect(BillFrequency.quarterly.label, 'Hàng quý');
    });
  });

  group('BillsSummary', () {
    test('parse tổng quan từ backend', () {
      final s = BillsSummary.fromJson({
        'total': 5,
        'unpaidCount': 3,
        'upcomingCount': 1,
        'dueCount': 1,
        'overdueCount': 1,
        'paidCount': 2,
        'unpaidTotal': '3500000',
        'overdueTotal': '3000000',
      });
      expect(s.total, 5);
      expect(s.unpaidCount, 3);
      expect(s.overdueCount, 1);
      expect(s.unpaidTotal, 3500000);
    });
  });

  group('BillPayPreview (ví dụ 8.000.000đ)', () {
    test('thanh toán khoản đã giữ riêng giữ nguyên Còn để chi', () {
      final p = BillPayPreview.fromJson({
        'amount': '3000000',
        'reservedAmount': '3000000',
        'releasedReservation': '3000000',
        'excessOverReserved': '0',
        'before': {
          'total': '8000000',
          'protectedMoney': '2400000',
          'unpaidBills': '3500000',
          'available': '2100000',
        },
        'after': {
          'total': '5000000',
          'protectedMoney': '2400000',
          'unpaidBills': '500000',
          'available': '2100000',
        },
        'requiresConfirmation': false,
        'warnings': <String>[],
      });
      expect(p.afterAvailable, p.beforeAvailable);
      expect(p.afterTotal, 5000000);
      expect(p.afterUnpaidBills, 500000);
      expect(p.afterProtected, 2400000);
      expect(p.requiresConfirmation, isFalse);
    });

    test('thanh toán thấp hơn dự kiến giải phóng chênh lệch', () {
      final p = BillPayPreview.fromJson({
        'amount': '2900000',
        'reservedAmount': '3000000',
        'releasedReservation': '3000000',
        'excessOverReserved': '0',
        'before': {'available': '2100000'},
        'after': {'available': '2200000'},
        'requiresConfirmation': false,
        'warnings': <String>[],
      });
      expect(p.afterAvailable - p.beforeAvailable, 100000);
    });

    test('vượt dự kiến bị cảnh báo và cần xác nhận khi âm', () {
      final p = BillPayPreview.fromJson({
        'amount': '3100000',
        'reservedAmount': '3000000',
        'releasedReservation': '3000000',
        'excessOverReserved': '100000',
        'before': {'available': '50000'},
        'after': {'available': '-50000'},
        'requiresConfirmation': true,
        'warnings': ['Phần vượt sẽ trừ vào tiền chi tiêu tự do.'],
      });
      expect(p.excessOverReserved, 100000);
      expect(p.requiresConfirmation, isTrue);
      expect(p.warnings, isNotEmpty);
    });
  });

  group('BillCandidateTransaction', () {
    test('parse giao dịch ứng viên', () {
      final c = BillCandidateTransaction.fromJson({
        '_id': 'tx1',
        'amount': '300000',
        'occurredAt': '2026-10-02T10:00:00+07:00',
        'note': 'Học phí đã trả',
        'version': 2,
      });
      expect(c.id, 'tx1');
      expect(c.amount, 300000);
      expect(c.note, 'Học phí đã trả');
      expect(c.version, 2);
    });
  });
}
