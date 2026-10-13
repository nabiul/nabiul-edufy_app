import 'package:flutter_test/flutter_test.dart';
import 'package:nabiul_edufy_app/src/models/accounts.dart';

void main() {
  test('accounts summary and transaction are parsed', () {
    final summary = AccountsSummary.fromJson({
      'total_balance': 250,
      'total_income': 200,
      'total_expense': 50,
      'this_month_income': 200,
      'this_month_expense': 50,
      'account_count': 1,
    });
    final transaction = AccountTransactionData.fromJson({
      'id': 1,
      'type': 'income',
      'amount': 200,
      'account': 'Test Bank',
      'purpose': 'General Income',
    });

    expect(summary.totalBalance, 250);
    expect(summary.totalExpense, 50);
    expect(transaction.isIncome, isTrue);
    expect(transaction.account, 'Test Bank');
  });

  test('accounts report breakdown is parsed', () {
    final report = AccountsReport.fromJson({
      'start_date': '2026-10-01',
      'end_date': '2026-10-12',
      'total_income': 270,
      'total_expense': 70,
      'net': 200,
      'transaction_count': 5,
      'daily': [
        {'date': '2026-10-12', 'income': 270, 'expense': 70, 'net': 200},
      ],
      'purposes': [
        {'type': 'income', 'purpose': 'Fees', 'total': 270, 'count': 3},
      ],
      'transactions': [
        {'id': 4, 'type': 'income', 'amount': 30},
      ],
    });

    expect(report.net, 200);
    expect(report.daily.single.income, 270);
    expect(report.purposes.single.count, 3);
    expect(report.transactions.single.id, 4);
  });
}
