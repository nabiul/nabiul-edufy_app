import 'package:flutter_test/flutter_test.dart';
import 'package:nabiul_edufy_app/src/models/fees.dart';

void main() {
  test('fees summary and monthly status are parsed', () {
    final summary = FeesSummary.fromJson({
      'total_collected': 1500.5,
      'this_month_collected': 500,
      'payment_count': 3,
      'partial_count': 1,
      'unpaid_count': 0,
    });
    final status = StudentFeeStatus.fromJson({
      'student': {'id': 12, 'name': 'Test Student', 'registration_no': 'REG-1'},
      'academic': {'level': 'One', 'section': 'A', 'roll_no': 2},
      'total_expected': 100,
      'total_paid': 60,
      'total_due': 40,
      'months': [
        {
          'month': 'january',
          'month_label': 'January',
          'expected': 100,
          'paid': 60,
          'due': 40,
          'status': 'partial',
        },
      ],
    });

    expect(summary.totalCollected, 1500.5);
    expect(summary.partialCount, 1);
    expect(status.totalDue, 40);
    expect(status.studentId, 12);
    expect(status.months.single.monthKey, 'january');
    expect(status.months.single.status, 'partial');
  });

  test('fees report, due student, and receipt are parsed', () {
    final report = FeesReport.fromJson({
      'start_date': '2026-10-01',
      'end_date': '2026-10-31',
      'total_collected': 1450,
      'payment_count': 2,
      'student_count': 1,
      'daily': [
        {'date': '2026-10-13', 'amount': 1450},
      ],
      'purposes': [
        {'purpose': 'Tuition Fee', 'amount': 1450},
      ],
      'payments': [
        {
          'id': 21,
          'student_id': 12,
          'student_name': 'Test Student',
          'registration_no': 'REG-1',
          'month_label': 'October',
          'amount': 1450,
          'status_label': 'Paid',
          'payment_date': '2026-10-13',
        },
      ],
    });
    final dueStudent = FeeDueStudent.fromJson({
      'student_id': 15,
      'student_name': 'Due Student',
      'registration_no': 'REG-2',
      'level': 'One',
      'section': 'A',
      'roll_no': 3,
      'total_due': 900,
      'months': [
        {'month_label': 'October', 'due': 900},
      ],
    });
    final receipt = FeeReceipt.fromJson({
      'id': 21,
      'student_id': 12,
      'student_name': 'Test Student',
      'registration_no': 'REG-1',
      'month_label': 'October',
      'amount': 1450,
      'status_label': 'Paid',
      'payment_date': '2026-10-13',
      'year': '2026',
      'voucher_number': 'deposit-21',
      'account': 'Cash',
      'account_number': '1001',
      'method': 'Cash',
      'discount': 50,
      'items': [
        {'purpose': 'Tuition Fee', 'amount': 1500},
      ],
    });

    expect(report.totalCollected, 1450);
    expect(report.daily.single.amount, 1450);
    expect(report.purposes.single.purpose, 'Tuition Fee');
    expect(report.payments.single.id, 21);
    expect(dueStudent.totalDue, 900);
    expect(dueStudent.months.single.month, 'October');
    expect(receipt.voucherNumber, 'deposit-21');
    expect(receipt.discount, 50);
    expect(receipt.items.single.amount, 1500);
  });
}
