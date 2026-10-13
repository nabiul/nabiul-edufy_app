class FeesSummary {
  const FeesSummary({
    required this.totalCollected,
    required this.thisMonthCollected,
    required this.paymentCount,
    required this.partialCount,
    required this.unpaidCount,
  });

  final double totalCollected;
  final double thisMonthCollected;
  final int paymentCount;
  final int partialCount;
  final int unpaidCount;

  factory FeesSummary.fromJson(Map<String, dynamic> json) => FeesSummary(
    totalCollected: (json['total_collected'] as num?)?.toDouble() ?? 0,
    thisMonthCollected: (json['this_month_collected'] as num?)?.toDouble() ?? 0,
    paymentCount: (json['payment_count'] as num?)?.toInt() ?? 0,
    partialCount: (json['partial_count'] as num?)?.toInt() ?? 0,
    unpaidCount: (json['unpaid_count'] as num?)?.toInt() ?? 0,
  );
}

class FeePurposeData {
  const FeePurposeData({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryValue,
    required this.isResidential,
  });

  final int id;
  final String name;
  final String category;
  final String categoryValue;
  final bool isResidential;

  factory FeePurposeData.fromJson(Map<String, dynamic> json) => FeePurposeData(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    category: json['fee_category_label'] as String? ?? '',
    categoryValue: json['fee_category'] as String? ?? 'general',
    isResidential: json['is_residential'] == true,
  );
}

class FeeTemplateData {
  const FeeTemplateData({
    required this.id,
    required this.year,
    required this.yearId,
    required this.level,
    required this.levelId,
    required this.month,
    required this.monthValue,
    required this.totalAmount,
    required this.items,
  });

  final int id;
  final String year;
  final int yearId;
  final String level;
  final int levelId;
  final String month;
  final String monthValue;
  final double totalAmount;
  final List<FeeTemplateItemData> items;

  factory FeeTemplateData.fromJson(Map<String, dynamic> json) =>
      FeeTemplateData(
        id: (json['id'] as num).toInt(),
        year: json['year'] as String? ?? '',
        yearId: (json['year_id'] as num?)?.toInt() ?? 0,
        level: json['level'] as String? ?? '',
        levelId: (json['level_id'] as num?)?.toInt() ?? 0,
        month: json['month_label'] as String? ?? '',
        monthValue: json['month'] as String? ?? '',
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        items: (json['items'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  FeeTemplateItemData.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}

class FeeTemplateItemData {
  const FeeTemplateItemData({
    required this.purpose,
    required this.amount,
    this.purposeId,
  });

  final String purpose;
  final double amount;
  final int? purposeId;

  factory FeeTemplateItemData.fromJson(Map<String, dynamic> json) =>
      FeeTemplateItemData(
        purpose: json['purpose'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        purposeId: (json['purpose_id'] as num?)?.toInt(),
      );
}

class FeePaymentData {
  const FeePaymentData({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.registrationNo,
    required this.month,
    required this.amount,
    required this.status,
    this.level,
    this.section,
    this.paymentDate,
  });

  final int id;
  final int? studentId;
  final String studentName;
  final String registrationNo;
  final String month;
  final double amount;
  final String status;
  final String? level;
  final String? section;
  final DateTime? paymentDate;

  factory FeePaymentData.fromJson(Map<String, dynamic> json) => FeePaymentData(
    id: (json['id'] as num).toInt(),
    studentId: (json['student_id'] as num?)?.toInt(),
    studentName: json['student_name'] as String? ?? '',
    registrationNo: json['registration_no'] as String? ?? '',
    month: json['month_label'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    status: json['status_label'] as String? ?? '',
    level: json['level'] as String?,
    section: json['section'] as String?,
    paymentDate: DateTime.tryParse(json['payment_date'] as String? ?? ''),
  );
}

class StudentFeeStatus {
  const StudentFeeStatus({
    required this.studentId,
    required this.studentName,
    required this.registrationNo,
    required this.academicLabel,
    required this.totalExpected,
    required this.totalPaid,
    required this.totalDue,
    required this.months,
  });

  final int studentId;
  final String studentName;
  final String registrationNo;
  final String academicLabel;
  final double totalExpected;
  final double totalPaid;
  final double totalDue;
  final List<MonthlyFeeStatus> months;

  factory StudentFeeStatus.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>? ?? const {};
    final academic = json['academic'] as Map<String, dynamic>? ?? const {};
    return StudentFeeStatus(
      studentId: (student['id'] as num?)?.toInt() ?? 0,
      studentName: student['name'] as String? ?? '',
      registrationNo: student['registration_no'] as String? ?? '',
      academicLabel:
          '${academic['level'] ?? ''} • ${academic['section'] ?? ''} • Roll ${academic['roll_no'] ?? '-'}',
      totalExpected: (json['total_expected'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
      totalDue: (json['total_due'] as num?)?.toDouble() ?? 0,
      months: (json['months'] as List<dynamic>? ?? const [])
          .map(
            (item) => MonthlyFeeStatus.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class MonthlyFeeStatus {
  const MonthlyFeeStatus({
    required this.monthKey,
    required this.month,
    required this.expected,
    required this.paid,
    required this.due,
    required this.status,
  });

  final String monthKey;
  final String month;
  final double expected;
  final double paid;
  final double due;
  final String status;

  factory MonthlyFeeStatus.fromJson(Map<String, dynamic> json) =>
      MonthlyFeeStatus(
        monthKey: json['month'] as String? ?? '',
        month: json['month_label'] as String? ?? '',
        expected: (json['expected'] as num?)?.toDouble() ?? 0,
        paid: (json['paid'] as num?)?.toDouble() ?? 0,
        due: (json['due'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'unpaid',
      );
}

class FeesReport {
  const FeesReport({
    required this.startDate,
    required this.endDate,
    required this.totalCollected,
    required this.paymentCount,
    required this.studentCount,
    required this.daily,
    required this.purposes,
    required this.payments,
  });

  final String startDate;
  final String endDate;
  final double totalCollected;
  final int paymentCount;
  final int studentCount;
  final List<FeeDailyCollection> daily;
  final List<FeePurposeCollection> purposes;
  final List<FeePaymentData> payments;

  factory FeesReport.fromJson(Map<String, dynamic> json) => FeesReport(
    startDate: json['start_date'] as String? ?? '',
    endDate: json['end_date'] as String? ?? '',
    totalCollected: (json['total_collected'] as num?)?.toDouble() ?? 0,
    paymentCount: (json['payment_count'] as num?)?.toInt() ?? 0,
    studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
    daily: (json['daily'] as List<dynamic>? ?? const [])
        .map(
          (item) => FeeDailyCollection.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
    purposes: (json['purposes'] as List<dynamic>? ?? const [])
        .map(
          (item) => FeePurposeCollection.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
    payments: (json['payments'] as List<dynamic>? ?? const [])
        .map((item) => FeePaymentData.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class FeeDailyCollection {
  const FeeDailyCollection({required this.date, required this.amount});

  final String date;
  final double amount;

  factory FeeDailyCollection.fromJson(Map<String, dynamic> json) =>
      FeeDailyCollection(
        date: json['date'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}

class FeePurposeCollection {
  const FeePurposeCollection({required this.purpose, required this.amount});

  final String purpose;
  final double amount;

  factory FeePurposeCollection.fromJson(Map<String, dynamic> json) =>
      FeePurposeCollection(
        purpose: json['purpose'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}

class FeeDueStudent {
  const FeeDueStudent({
    required this.studentId,
    required this.studentName,
    required this.registrationNo,
    required this.level,
    required this.section,
    required this.totalDue,
    required this.months,
    this.rollNo,
  });

  final int studentId;
  final String studentName;
  final String registrationNo;
  final String level;
  final String section;
  final int? rollNo;
  final double totalDue;
  final List<FeeDueMonth> months;

  factory FeeDueStudent.fromJson(Map<String, dynamic> json) => FeeDueStudent(
    studentId: (json['student_id'] as num).toInt(),
    studentName: json['student_name'] as String? ?? '',
    registrationNo: json['registration_no'] as String? ?? '',
    level: json['level'] as String? ?? '',
    section: json['section'] as String? ?? '',
    rollNo: (json['roll_no'] as num?)?.toInt(),
    totalDue: (json['total_due'] as num?)?.toDouble() ?? 0,
    months: (json['months'] as List<dynamic>? ?? const [])
        .map((item) => FeeDueMonth.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class FeeDuePage {
  const FeeDuePage({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.total,
    required this.totalDue,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<FeeDueStudent> items;
  final int page;
  final int lastPage;
  final int total;
  final double totalDue;
  final int nextOffset;
  final bool hasMore;

  factory FeeDuePage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return FeeDuePage(
      items: (json['data'] as List<dynamic>? ?? const [])
          .map((item) => FeeDueStudent.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: _jsonInt(meta['current_page'], fallback: 1),
      lastPage: _jsonInt(meta['last_page'], fallback: 1),
      total: _jsonInt(meta['student_count']),
      totalDue: _jsonDouble(meta['total_due']),
      nextOffset: _jsonInt(meta['next_offset']),
      hasMore: meta['has_more'] == true,
    );
  }
}

int _jsonInt(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _jsonDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

class FeeDueMonth {
  const FeeDueMonth({required this.month, required this.due});

  final String month;
  final double due;

  factory FeeDueMonth.fromJson(Map<String, dynamic> json) => FeeDueMonth(
    month: json['month_label'] as String? ?? '',
    due: (json['due'] as num?)?.toDouble() ?? 0,
  );
}

class FeeReceipt {
  const FeeReceipt({
    required this.payment,
    required this.items,
    required this.discount,
    this.year,
    this.voucherNumber,
    this.account,
    this.accountNumber,
    this.method,
    this.note,
  });

  final FeePaymentData payment;
  final String? year;
  final String? voucherNumber;
  final String? account;
  final String? accountNumber;
  final String? method;
  final String? note;
  final double discount;
  final List<FeeTemplateItemData> items;

  factory FeeReceipt.fromJson(Map<String, dynamic> json) => FeeReceipt(
    payment: FeePaymentData.fromJson(json),
    year: json['year'] as String?,
    voucherNumber: json['voucher_number'] as String?,
    account: json['account'] as String?,
    accountNumber: json['account_number'] as String?,
    method: json['method'] as String?,
    note: json['note'] as String?,
    discount: (json['discount'] as num?)?.toDouble() ?? 0,
    items: (json['items'] as List<dynamic>? ?? const [])
        .map(
          (item) => FeeTemplateItemData.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
  );
}
