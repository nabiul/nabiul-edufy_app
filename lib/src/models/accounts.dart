class AccountsSummary {
  const AccountsSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.thisMonthIncome,
    required this.thisMonthExpense,
    required this.accountCount,
  });

  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double thisMonthIncome;
  final double thisMonthExpense;
  final int accountCount;

  factory AccountsSummary.fromJson(Map<String, dynamic> json) =>
      AccountsSummary(
        totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0,
        totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0,
        totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0,
        thisMonthIncome: (json['this_month_income'] as num?)?.toDouble() ?? 0,
        thisMonthExpense: (json['this_month_expense'] as num?)?.toDouble() ?? 0,
        accountCount: (json['account_count'] as num?)?.toInt() ?? 0,
      );
}

class AccountData {
  const AccountData({
    required this.id,
    required this.bankName,
    required this.openingBalance,
    required this.currentBalance,
    this.accountName,
    this.accountNumber,
    this.bankBranch,
  });

  final int id;
  final String bankName;
  final String? accountName;
  final String? accountNumber;
  final String? bankBranch;
  final double openingBalance;
  final double currentBalance;

  factory AccountData.fromJson(Map<String, dynamic> json) => AccountData(
    id: (json['id'] as num).toInt(),
    bankName: json['bank_name'] as String? ?? '',
    accountName: json['account_name'] as String?,
    accountNumber: json['account_number'] as String?,
    bankBranch: json['bank_branch'] as String?,
    openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
    currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
  );
}

class AccountPurposeData {
  const AccountPurposeData({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    this.parentId,
    this.parent,
  });

  final int id;
  final String name;
  final String type;
  final String typeLabel;
  final int? parentId;
  final String? parent;

  factory AccountPurposeData.fromJson(Map<String, dynamic> json) =>
      AccountPurposeData(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        typeLabel: json['type_label'] as String? ?? '',
        parentId: (json['parent_id'] as num?)?.toInt(),
        parent: json['parent'] as String?,
      );
}

class AccountTransactionData {
  const AccountTransactionData({
    required this.id,
    required this.type,
    required this.amount,
    this.date,
    this.account,
    this.purpose,
    this.student,
    this.voucherNumber,
    this.method,
    this.note,
    this.accountNumber,
    this.registrationNo,
    this.studentFeeMonth,
    this.studentFeeMonthLabel,
    this.studentInfo,
  });

  final int id;
  final String type;
  final DateTime? date;
  final double amount;
  final String? account;
  final String? purpose;
  final String? student;
  final String? voucherNumber;
  final String? method;
  final String? note;
  final String? accountNumber;
  final String? registrationNo;
  final String? studentFeeMonth;
  final String? studentFeeMonthLabel;
  final Map<String, dynamic>? studentInfo;

  bool get isIncome => type == 'income';

  factory AccountTransactionData.fromJson(Map<String, dynamic> json) =>
      AccountTransactionData(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        account: json['account'] as String?,
        purpose: json['purpose'] as String?,
        student: json['student'] as String?,
        voucherNumber: json['voucher_number'] as String?,
        method: json['method'] as String?,
        note: json['note'] as String?,
        accountNumber: json['account_number'] as String?,
        registrationNo: json['registration_no'] as String?,
        studentFeeMonth: json['student_fee_month'] as String?,
        studentFeeMonthLabel: json['student_fee_month_label'] as String?,
        studentInfo: (json['student_info'] as Map<dynamic, dynamic>?)?.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
}

class AccountsReport {
  const AccountsReport({
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.transactionCount,
    required this.daily,
    required this.purposes,
    required this.transactions,
  });

  final String startDate;
  final String endDate;
  final double totalIncome;
  final double totalExpense;
  final double net;
  final int transactionCount;
  final List<AccountDailyReport> daily;
  final List<AccountPurposeReport> purposes;
  final List<AccountTransactionData> transactions;

  factory AccountsReport.fromJson(Map<String, dynamic> json) => AccountsReport(
    startDate: json['start_date'] as String? ?? '',
    endDate: json['end_date'] as String? ?? '',
    totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0,
    totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0,
    net: (json['net'] as num?)?.toDouble() ?? 0,
    transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
    daily: (json['daily'] as List<dynamic>? ?? const [])
        .map(
          (item) => AccountDailyReport.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
    purposes: (json['purposes'] as List<dynamic>? ?? const [])
        .map(
          (item) => AccountPurposeReport.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
    transactions: (json['transactions'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              AccountTransactionData.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
  );
}

class AccountDailyReport {
  const AccountDailyReport({
    required this.date,
    required this.income,
    required this.expense,
    required this.net,
  });

  final String date;
  final double income;
  final double expense;
  final double net;

  factory AccountDailyReport.fromJson(Map<String, dynamic> json) =>
      AccountDailyReport(
        date: json['date'] as String? ?? '',
        income: (json['income'] as num?)?.toDouble() ?? 0,
        expense: (json['expense'] as num?)?.toDouble() ?? 0,
        net: (json['net'] as num?)?.toDouble() ?? 0,
      );
}

class AccountPurposeReport {
  const AccountPurposeReport({
    required this.type,
    required this.purpose,
    required this.total,
    required this.count,
  });

  final String type;
  final String purpose;
  final double total;
  final int count;

  factory AccountPurposeReport.fromJson(Map<String, dynamic> json) =>
      AccountPurposeReport(
        type: json['type'] as String? ?? '',
        purpose: json['purpose'] as String? ?? '',
        total: (json['total'] as num?)?.toDouble() ?? 0,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

class AccountTransferData {
  const AccountTransferData({
    required this.voucherNumber,
    required this.amount,
    this.date,
    this.fromAccount,
    this.toAccount,
    this.note,
  });

  final String voucherNumber;
  final DateTime? date;
  final String? fromAccount;
  final String? toAccount;
  final double amount;
  final String? note;

  factory AccountTransferData.fromJson(Map<String, dynamic> json) =>
      AccountTransferData(
        voucherNumber: json['voucher_number'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        fromAccount: json['from_account'] as String?,
        toAccount: json['to_account'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String?,
      );
}
