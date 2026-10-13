class AcademicSummary {
  const AcademicSummary({
    required this.studentCount,
    required this.levelCount,
    required this.sectionCount,
    this.currentYear,
  });

  final int studentCount;
  final int levelCount;
  final int sectionCount;
  final AcademicOption? currentYear;

  factory AcademicSummary.fromJson(Map<String, dynamic> json) =>
      AcademicSummary(
        studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
        levelCount: (json['level_count'] as num?)?.toInt() ?? 0,
        sectionCount: (json['section_count'] as num?)?.toInt() ?? 0,
        currentYear: json['current_year'] is Map<String, dynamic>
            ? AcademicOption.fromJson(
                json['current_year'] as Map<String, dynamic>,
              )
            : null,
      );
}

class AcademicOption {
  const AcademicOption({
    required this.id,
    required this.name,
    this.code,
    this.levelId,
    this.isCurrent = false,
  });

  final int id;
  final String name;
  final String? code;
  final int? levelId;
  final bool isCurrent;

  factory AcademicOption.fromJson(Map<String, dynamic> json) => AcademicOption(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    code: json['code'] as String?,
    levelId: (json['level_id'] as num?)?.toInt(),
    isCurrent: json['is_current'] as bool? ?? false,
  );
}

class StudentSummary {
  const StudentSummary({
    required this.id,
    required this.registrationNo,
    required this.name,
    required this.yearName,
    required this.levelName,
    required this.sectionName,
    this.rollNo,
    this.group,
    this.phone,
  });

  final int id;
  final String registrationNo;
  final String name;
  final String yearName;
  final String levelName;
  final String sectionName;
  final int? rollNo;
  final String? group;
  final String? phone;

  factory StudentSummary.fromJson(Map<String, dynamic> json) => StudentSummary(
    id: (json['id'] as num).toInt(),
    registrationNo: json['registration_no'] as String? ?? '',
    name: json['name_english'] as String? ?? '',
    yearName: json['year_name'] as String? ?? '',
    levelName: json['level_name'] as String? ?? '',
    sectionName: json['section_name'] as String? ?? '',
    rollNo: (json['roll_no'] as num?)?.toInt(),
    group: json['group'] as String?,
    phone: (json['phone'] ?? json['sms_phone']) as String?,
  );
}

class StudentDetails {
  const StudentDetails({
    required this.id,
    required this.registrationNo,
    required this.name,
    required this.cycles,
    required this.transferHistory,
    this.banglaName,
    this.dob,
    this.gender,
    this.bloodGroup,
    this.phone,
    this.email,
    this.address,
    this.permanentAddress,
    this.religion,
    this.smsPhone,
    this.fatherName,
    this.fatherPhone,
    this.motherName,
    this.motherPhone,
  });

  final int id;
  final String registrationNo;
  final String name;
  final String? banglaName;
  final String? dob;
  final String? gender;
  final String? bloodGroup;
  final String? phone;
  final String? email;
  final String? address;
  final String? permanentAddress;
  final String? religion;
  final String? smsPhone;
  final String? fatherName;
  final String? fatherPhone;
  final String? motherName;
  final String? motherPhone;
  final List<StudentCycle> cycles;
  final List<StudentTransferLog> transferHistory;

  factory StudentDetails.fromJson(Map<String, dynamic> json) => StudentDetails(
    id: (json['id'] as num).toInt(),
    registrationNo: json['registration_no'] as String? ?? '',
    name: json['name_english'] as String? ?? '',
    banglaName: json['name_bangla'] as String?,
    dob: json['dob'] as String?,
    gender: json['gender'] as String?,
    bloodGroup: json['blood_group'] as String?,
    phone: (json['phone'] ?? json['sms_phone']) as String?,
    email: json['email'] as String?,
    address: json['present_address'] as String?,
    permanentAddress: json['permanent_address'] as String?,
    religion: json['religion'] as String?,
    smsPhone: json['sms_phone'] as String?,
    fatherName: json['father_name'] as String?,
    fatherPhone: json['father_phone'] as String?,
    motherName: json['mother_name'] as String?,
    motherPhone: json['mother_phone'] as String?,
    cycles: (json['academic_cycles'] as List<dynamic>? ?? const [])
        .map((item) => StudentCycle.fromJson(item as Map<String, dynamic>))
        .toList(),
    transferHistory: (json['transfer_history'] as List<dynamic>? ?? const [])
        .map(
          (item) => StudentTransferLog.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
  );
}

class StudentTransferLog {
  const StudentTransferLog({
    required this.id,
    required this.year,
    required this.fromLevel,
    required this.fromSection,
    required this.fromRollNo,
    required this.toLevel,
    required this.toSection,
    required this.toRollNo,
    this.remarks,
    this.transferredBy,
    this.transferredAt,
  });

  final int id;
  final String year;
  final String fromLevel;
  final String fromSection;
  final int? fromRollNo;
  final String toLevel;
  final String toSection;
  final int? toRollNo;
  final String? remarks;
  final String? transferredBy;
  final DateTime? transferredAt;

  factory StudentTransferLog.fromJson(Map<String, dynamic> json) =>
      StudentTransferLog(
        id: (json['id'] as num).toInt(),
        year: json['year'] as String? ?? '',
        fromLevel: json['from_level'] as String? ?? '',
        fromSection: json['from_section'] as String? ?? '',
        fromRollNo: (json['from_roll_no'] as num?)?.toInt(),
        toLevel: json['to_level'] as String? ?? '',
        toSection: json['to_section'] as String? ?? '',
        toRollNo: (json['to_roll_no'] as num?)?.toInt(),
        remarks: json['remarks'] as String?,
        transferredBy: json['transferred_by'] as String?,
        transferredAt: DateTime.tryParse(
          json['transferred_at'] as String? ?? '',
        ),
      );
}

class StudentCycle {
  const StudentCycle({
    required this.id,
    required this.yearId,
    required this.levelId,
    required this.sectionId,
    required this.year,
    required this.level,
    required this.section,
    this.rollNo,
    this.group,
    this.feeCategory = 'general',
    this.discount = 0,
  });

  final int id;
  final int yearId;
  final int levelId;
  final int sectionId;
  final String year;
  final String level;
  final String section;
  final int? rollNo;
  final String? group;
  final String feeCategory;
  final double discount;

  factory StudentCycle.fromJson(Map<String, dynamic> json) {
    final year = json['year'] as Map<String, dynamic>? ?? const {};
    final level = json['level'] as Map<String, dynamic>? ?? const {};
    final section = json['section'] as Map<String, dynamic>? ?? const {};
    return StudentCycle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      yearId:
          (json['year_id'] as num?)?.toInt() ??
          (year['id'] as num?)?.toInt() ??
          0,
      levelId:
          (json['level_id'] as num?)?.toInt() ??
          (level['id'] as num?)?.toInt() ??
          0,
      sectionId:
          (json['section_id'] as num?)?.toInt() ??
          (section['id'] as num?)?.toInt() ??
          0,
      year: year['name'] as String? ?? '',
      level: level['name'] as String? ?? '',
      section: section['name'] as String? ?? '',
      rollNo: (json['roll_no'] as num?)?.toInt(),
      group: json['group'] as String?,
      feeCategory: json['fee_category'] as String? ?? 'general',
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
    );
  }
}
