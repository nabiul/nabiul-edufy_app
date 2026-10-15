import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/academic.dart';
import '../models/accounts.dart';
import '../models/app_user.dart';
import '../models/attendance.dart';
import '../models/dashboard_data.dart';
import '../models/fees.dart';
import '../models/enquiry.dart';
import '../models/notice.dart';

class ApiClient {
  ApiClient({http.Client? client, this.onUnauthorized})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Future<void> Function()? onUnauthorized;

  Future<String> login(String login, String password) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/login'),
      headers: _headers(),
      body: jsonEncode({
        'login': login,
        'password': password,
        'device_name': 'nabiul-edufy-flutter',
      }),
    );
    final body = _decode(response, notifyUnauthorized: false);
    return (body['data'] as Map<String, dynamic>)['token'] as String;
  }

  Future<AppUser> me(String token) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/me'),
      headers: _headers(token),
    );
    final body = _decode(response);
    return AppUser.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<DashboardData> dashboard(String token) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/dashboard'),
      headers: _headers(token),
    );
    final body = _decode(response);
    return DashboardData.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<NoticeItem>> notices(String token) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/notices?per_page=50'),
      headers: _headers(token),
    );
    final body = _decode(response);
    return (body['data'] as List<dynamic>)
        .map((item) => NoticeItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Enquiry>> enquiries(String token, {String? search, String? status, bool due = false}) async {
    final body = await _get('/enquiries', token, query: {'per_page': '50', if (search?.isNotEmpty == true) 'search': search!, if (status?.isNotEmpty == true) 'status': status!, if (due) 'due': '1'});
    return (body['data'] as List<dynamic>).map((item) => Enquiry.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<EnquiryOptions> enquiryOptions(String token) async {
    final body = await _get('/enquiries/options', token);
    return EnquiryOptions.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Enquiry> enquiry(String token, int id) async {
    final body = await _get('/enquiries/$id', token);
    return Enquiry.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> saveEnquiry(String token, Map<String, dynamic> data, {int? id}) async {
    if (id == null) {
      await _post('/enquiries', token, data);
    } else {
      await _put('/enquiries/$id', token, data);
    }
  }

  Future<void> saveEnquiryFollowUp(String token, int id, Map<String, dynamic> data) async => _post('/enquiries/$id/follow-up', token, data);

  Future<AcademicSummary> academicSummary(String token) async {
    final body = await _get('/academic/summary', token);
    return AcademicSummary.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<AcademicOption>> academicYears(String token) =>
      _academicOptions('/academic/years', token);

  Future<List<AcademicOption>> academicLevels(String token) =>
      _academicOptions('/academic/levels', token);

  Future<List<AcademicOption>> academicSections(String token, {int? levelId}) =>
      _academicOptions(
        '/academic/sections',
        token,
        query: {if (levelId != null) 'level_id': levelId.toString()},
      );

  Future<void> saveAcademicYear(
    String token, {
    required String name,
    int? yearId,
    bool isCurrent = false,
  }) async {
    final data = {'name': name, if (yearId != null) 'is_current': isCurrent};
    if (yearId == null) {
      await _post('/academic/years', token, data);
    } else {
      await _put('/academic/years/$yearId', token, data);
    }
  }

  Future<void> saveAcademicLevel(
    String token, {
    required String name,
    required String code,
    int? levelId,
  }) async {
    final data = {'name': name, 'code': code};
    if (levelId == null) {
      await _post('/academic/levels', token, data);
    } else {
      await _put('/academic/levels/$levelId', token, data);
    }
  }

  Future<void> saveAcademicSection(
    String token, {
    required int levelId,
    required String name,
    required String code,
    int? sectionId,
  }) async {
    final data = {'level_id': levelId, 'name': name, 'code': code};
    if (sectionId == null) {
      await _post('/academic/sections', token, data);
    } else {
      await _put('/academic/sections/$sectionId', token, data);
    }
  }

  Future<List<StudentSummary>> academicStudents(
    String token, {
    int? yearId,
    int? levelId,
    int? sectionId,
    String? search,
  }) async {
    final query = <String, String>{
      'per_page': '20',
      if (yearId != null) 'year_id': yearId.toString(),
      if (levelId != null) 'level_id': levelId.toString(),
      if (sectionId != null) 'section_id': sectionId.toString(),
      if (search?.isNotEmpty == true) 'search': search!,
    };
    final students = <StudentSummary>[];
    var page = 1;
    var lastPage = 1;
    do {
      final body = await _get(
        '/academic/students',
        token,
        query: {...query, 'page': page.toString()},
      );
      students.addAll(
        (body['data'] as List<dynamic>).map(
          (item) => StudentSummary.fromJson(item as Map<String, dynamic>),
        ),
      );
      final meta = body['meta'] as Map<String, dynamic>?;
      lastPage = (meta?['last_page'] as num?)?.toInt() ?? page;
      page++;
    } while (page <= lastPage);
    return students;
  }

  Future<AcademicStudentsPage> academicStudentsPage(
    String token, {
    int? yearId,
    int? levelId,
    int? sectionId,
    String? search,
    int page = 1,
  }) async {
    final body = await _get(
      '/academic/students',
      token,
      query: {
        'per_page': '20',
        'page': page.toString(),
        if (yearId != null) 'year_id': yearId.toString(),
        if (levelId != null) 'level_id': levelId.toString(),
        if (sectionId != null) 'section_id': sectionId.toString(),
        if (search?.isNotEmpty == true) 'search': search!,
      },
    );
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};
    return AcademicStudentsPage(
      students: (body['data'] as List<dynamic>)
          .map((item) => StudentSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: (meta['current_page'] as num?)?.toInt() ?? page,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? page,
    );
  }

  Future<StudentDetails> academicStudent(String token, int studentId) async {
    final body = await _get('/academic/students/$studentId', token);
    return StudentDetails.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> saveStudent(
    String token,
    Map<String, dynamic> data, {
    int? studentId,
  }) async {
    if (studentId == null) {
      await _post('/academic/students', token, data);
    } else {
      await _put('/academic/students/$studentId', token, data);
    }
  }

  Future<void> promoteStudent(
    String token, {
    required int studentId,
    required int studentCycleId,
    required int yearId,
    required int levelId,
    required int sectionId,
    required int rollNo,
    String? remarks,
  }) async {
    await _post('/academic/students/$studentId/promote', token, {
      'student_cycle_id': studentCycleId,
      'year_id': yearId,
      'level_id': levelId,
      'section_id': sectionId,
      'roll_no': rollNo,
      if (remarks?.isNotEmpty == true) 'remarks': remarks,
    });
  }

  Future<void> transferStudent(
    String token, {
    required int studentId,
    required int studentCycleId,
    required int levelId,
    required int sectionId,
    required int rollNo,
    String? remarks,
  }) async {
    await _put('/academic/students/$studentId/transfer', token, {
      'student_cycle_id': studentCycleId,
      'level_id': levelId,
      'section_id': sectionId,
      'roll_no': rollNo,
      if (remarks?.isNotEmpty == true) 'remarks': remarks,
    });
  }

  Future<AttendanceRegister> attendance(
    String token, {
    required int yearId,
    required int levelId,
    required int sectionId,
    required String date,
  }) async {
    final body = await _get(
      '/academic/attendance',
      token,
      query: {
        'year_id': yearId.toString(),
        'level_id': levelId.toString(),
        'section_id': sectionId.toString(),
        'date': date,
      },
    );
    return AttendanceRegister.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<AttendanceRegister> saveAttendance(
    String token, {
    required int yearId,
    required int levelId,
    required int sectionId,
    required String date,
    required Set<int> presentStudentIds,
    required Map<int, String> remarks,
  }) async {
    final body = await _put('/academic/attendance', token, {
      'year_id': yearId,
      'level_id': levelId,
      'section_id': sectionId,
      'date': date,
      'present_student_ids': presentStudentIds.toList(),
      'remarks': remarks.map((key, value) => MapEntry(key.toString(), value)),
    });
    return AttendanceRegister.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<AttendanceReport> attendanceReport(
    String token, {
    required int yearId,
    required int levelId,
    required int sectionId,
    required String month,
  }) async {
    final body = await _get(
      '/academic/attendance/report',
      token,
      query: {
        'year_id': yearId.toString(),
        'level_id': levelId.toString(),
        'section_id': sectionId.toString(),
        'month': month,
      },
    );
    return AttendanceReport.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<FeesSummary> feesSummary(String token, {int? yearId}) async {
    final body = await _get(
      '/fees/summary',
      token,
      query: {if (yearId != null) 'year_id': yearId.toString()},
    );
    return FeesSummary.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<FeePurposeData>> feePurposes(String token) async {
    final body = await _get('/fees/purposes', token);
    return (body['data'] as List<dynamic>)
        .map((item) => FeePurposeData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFeePurpose(
    String token, {
    int? id,
    required String name,
    required String category,
    required bool isResidential,
  }) async {
    final data = {
      'name': name,
      'fee_category': category,
      'is_residential': isResidential,
    };
    id == null
        ? await _post('/fees/purposes', token, data)
        : await _put('/fees/purposes/$id', token, data);
  }

  Future<void> deleteFeePurpose(String token, int id) =>
      _delete('/fees/purposes/$id', token);

  Future<List<FeeTemplateData>> feeTemplates(
    String token, {
    int? yearId,
  }) async {
    final body = await _get(
      '/fees/templates',
      token,
      query: {if (yearId != null) 'year_id': yearId.toString()},
    );
    return (body['data'] as List<dynamic>)
        .map((item) => FeeTemplateData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFeeTemplate(
    String token, {
    int? id,
    required int yearId,
    required int levelId,
    required String month,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = {
      'year_id': yearId,
      'level_id': levelId,
      'month': month,
      'items': items,
    };
    id == null
        ? await _post('/fees/templates', token, data)
        : await _put('/fees/templates/$id', token, data);
  }

  Future<void> deleteFeeTemplate(String token, int id) =>
      _delete('/fees/templates/$id', token);

  Future<List<FeePaymentData>> feePayments(
    String token, {
    int? yearId,
    String? search,
  }) async {
    final body = await _get(
      '/fees/payments',
      token,
      query: {
        'per_page': '50',
        if (yearId != null) 'year_id': yearId.toString(),
        if (search?.isNotEmpty == true) 'search': search!,
      },
    );
    return (body['data'] as List<dynamic>)
        .map((item) => FeePaymentData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StudentFeeStatus> studentFeeStatus(
    String token,
    int studentId, {
    int? yearId,
  }) async {
    final body = await _get(
      '/fees/students/$studentId',
      token,
      query: {if (yearId != null) 'year_id': yearId.toString()},
    );
    return StudentFeeStatus.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> collectFee(
    String token, {
    required int studentId,
    required int yearId,
    required String month,
    required int accountId,
    required double amount,
    required String paymentMethod,
    String? note,
  }) async {
    await _post('/fees/students/$studentId/payments', token, {
      'year_id': yearId,
      'month': month,
      'account_id': accountId,
      'amount': amount,
      'payment_method': paymentMethod,
      if (note?.isNotEmpty == true) 'note': note,
    });
  }

  Future<FeesReport> feesReport(
    String token, {
    required int yearId,
    required String startDate,
    required String endDate,
    int? levelId,
  }) async {
    final body = await _get(
      '/fees/report',
      token,
      query: {
        'year_id': yearId.toString(),
        'start_date': startDate,
        'end_date': endDate,
        if (levelId != null) 'level_id': levelId.toString(),
      },
    );
    return FeesReport.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<FeeDueStudent>> feeDues(
    String token, {
    required int yearId,
    int? levelId,
    int? sectionId,
    String? search,
  }) async {
    final page = await feeDuesPage(
      token,
      yearId: yearId,
      levelId: levelId,
      sectionId: sectionId,
      search: search,
    );
    return page.items;
  }

  Future<FeeDuePage> feeDuesPage(
    String token, {
    required int yearId,
    int? levelId,
    int? sectionId,
    String? search,
    int page = 1,
    int perPage = 20,
    int offset = 0,
  }) async {
    final body = await _get(
      '/fees/dues',
      token,
      query: {
        'year_id': yearId.toString(),
        'page': page.toString(),
        'per_page': perPage.toString(),
        'offset': offset.toString(),
        if (levelId != null) 'level_id': levelId.toString(),
        if (sectionId != null) 'section_id': sectionId.toString(),
        if (search?.isNotEmpty == true) 'search': search!,
      },
    );
    return FeeDuePage.fromJson(body);
  }

  Future<FeeReceipt> feeReceipt(String token, int paymentId) async {
    final body = await _get('/fees/payments/$paymentId', token);
    return FeeReceipt.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<AccountsSummary> accountsSummary(String token) async {
    final body = await _get('/accounts/summary', token);
    return AccountsSummary.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<AccountData>> accounts(String token) async {
    final body = await _get('/accounts/list', token);
    return (body['data'] as List<dynamic>)
        .map((item) => AccountData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAccount(
    String token, {
    int? id,
    required String bankName,
    String? accountName,
    String? accountNumber,
    String? bankBranch,
    required double openingBalance,
  }) async {
    final data = {
      'bank_name': bankName,
      'account_name': accountName,
      'account_number': accountNumber,
      'bank_branch': bankBranch,
      'opening_balance': openingBalance,
    };
    id == null
        ? await _post('/accounts/list', token, data)
        : await _put('/accounts/list/$id', token, data);
  }

  Future<void> deleteAccount(String token, int id) =>
      _delete('/accounts/list/$id', token);

  Future<List<AccountPurposeData>> accountPurposes(String token) async {
    final body = await _get('/accounts/purposes', token);
    return (body['data'] as List<dynamic>)
        .map(
          (item) => AccountPurposeData.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveAccountPurpose(
    String token, {
    int? id,
    required String name,
    required String type,
    int? parentId,
  }) async {
    final data = {'name': name, 'type': type, 'parent_id': parentId};
    id == null
        ? await _post('/accounts/purposes', token, data)
        : await _put('/accounts/purposes/$id', token, data);
  }

  Future<void> deleteAccountPurpose(String token, int id) =>
      _delete('/accounts/purposes/$id', token);

  Future<List<AccountTransactionData>> accountTransactions(
    String token, {
    int? accountId,
    String? type,
    String? search,
  }) async {
    final body = await _get(
      '/accounts/transactions',
      token,
      query: {
        'per_page': '50',
        if (accountId != null) 'account_id': accountId.toString(),
        if (type?.isNotEmpty == true) 'type': type!,
        if (search?.isNotEmpty == true) 'search': search!,
      },
    );
    return (body['data'] as List<dynamic>)
        .map(
          (item) =>
              AccountTransactionData.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<AccountTransferData>> accountTransfers(String token) async {
    final body = await _get('/accounts/transfers', token);
    return (body['data'] as List<dynamic>)
        .map(
          (item) => AccountTransferData.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> createAccountTransfer(
    String token, {
    required int fromAccountId,
    required int toAccountId,
    required String date,
    required double amount,
    required String method,
    String? note,
  }) async {
    await _post('/accounts/transfers', token, {
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'date': date,
      'amount': amount,
      'method': method,
      if (note?.isNotEmpty == true) 'note': note,
    });
  }

  Future<AccountsReport> accountsReport(
    String token, {
    required String startDate,
    required String endDate,
    int? accountId,
  }) async {
    final body = await _get(
      '/accounts/report',
      token,
      query: {
        'start_date': startDate,
        'end_date': endDate,
        if (accountId != null) 'account_id': accountId.toString(),
      },
    );
    return AccountsReport.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<AccountTransactionData> accountTransaction(
    String token, {
    required String type,
    required int id,
  }) async {
    final body = await _get('/accounts/transactions/$type/$id', token);
    return AccountTransactionData.fromJson(
      body['data'] as Map<String, dynamic>,
    );
  }

  Future<void> createDeposit(
    String token, {
    required int accountId,
    required int purposeId,
    required String date,
    required double amount,
    required String method,
    int? studentId,
    String? note,
  }) async {
    await _post('/accounts/deposits', token, {
      'account_id': accountId,
      'purpose_id': purposeId,
      'date': date,
      'amount': amount,
      'method': method,
      // ignore: use_null_aware_elements
      if (studentId != null) 'student_id': studentId,
      if (note?.isNotEmpty == true) 'note': note,
    });
  }

  Future<void> createWithdrawal(
    String token, {
    required int accountId,
    required int purposeId,
    required String date,
    required double amount,
    required String method,
    String? note,
  }) async {
    await _post('/accounts/withdrawals', token, {
      'account_id': accountId,
      'purpose_id': purposeId,
      'date': date,
      'amount': amount,
      'method': method,
      if (note?.isNotEmpty == true) 'note': note,
    });
  }

  Future<void> logout(String token) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/logout'),
      headers: _headers(token),
    );
    _decode(response, notifyUnauthorized: false);
  }

  Future<List<AcademicOption>> _academicOptions(
    String path,
    String token, {
    Map<String, String>? query,
  }) async {
    final body = await _get(path, token, query: query);
    return (body['data'] as List<dynamic>)
        .map((item) => AcademicOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _get(
    String path,
    String token, {
    Map<String, String>? query,
  }) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final response = await _client.get(uri, headers: _headers(token));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _put(
    String path,
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    return _decode(response);
  }

  Future<void> _delete(String path, String token) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers(token),
    );
    _decode(response);
  }

  Map<String, String> _headers([String? token]) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decode(
    http.Response response, {
    bool notifyUnauthorized = true,
  }) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('The server returned an invalid response.');
    }
    final body = decoded;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 && notifyUnauthorized) {
        onUnauthorized?.call();
      }
      final errors = body['errors'];
      String? validationMessage;
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final first = errors.values.first;
        validationMessage = first is List && first.isNotEmpty
            ? first.first.toString()
            : first.toString();
      }
      throw ApiException(
        validationMessage ?? body['message']?.toString() ?? 'Request failed.',
        statusCode: response.statusCode,
      );
    }
    return body;
  }
}

class AcademicStudentsPage {
  const AcademicStudentsPage({
    required this.students,
    required this.page,
    required this.lastPage,
  });

  final List<StudentSummary> students;
  final int page;
  final int lastPage;
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
