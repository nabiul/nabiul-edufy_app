class AttendanceRegister {
  const AttendanceRegister({
    required this.date,
    required this.total,
    required this.present,
    required this.absent,
    required this.students,
  });

  final String date;
  final int total;
  final int present;
  final int absent;
  final List<AttendanceStudent> students;

  factory AttendanceRegister.fromJson(Map<String, dynamic> json) =>
      AttendanceRegister(
        date: json['date'] as String? ?? '',
        total: (json['total'] as num?)?.toInt() ?? 0,
        present: (json['present'] as num?)?.toInt() ?? 0,
        absent: (json['absent'] as num?)?.toInt() ?? 0,
        students: (json['students'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  AttendanceStudent.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}

class AttendanceStudent {
  const AttendanceStudent({
    required this.id,
    required this.registrationNo,
    required this.name,
    required this.present,
    this.rollNo,
    this.remark,
  });

  final int id;
  final String registrationNo;
  final String name;
  final int? rollNo;
  final bool present;
  final String? remark;

  factory AttendanceStudent.fromJson(Map<String, dynamic> json) =>
      AttendanceStudent(
        id: (json['id'] as num).toInt(),
        registrationNo: json['registration_no'] as String? ?? '',
        name: json['name'] as String? ?? '',
        rollNo: (json['roll_no'] as num?)?.toInt(),
        present: json['present'] as bool? ?? false,
        remark: json['remark'] as String?,
      );
}

class AttendanceReport {
  const AttendanceReport({
    required this.month,
    required this.attendanceDays,
    required this.studentCount,
    required this.averagePercentage,
    required this.dates,
    required this.students,
  });

  final String month;
  final int attendanceDays;
  final int studentCount;
  final double averagePercentage;
  final List<String> dates;
  final List<StudentAttendanceReport> students;

  factory AttendanceReport.fromJson(
    Map<String, dynamic> json,
  ) => AttendanceReport(
    month: json['month'] as String? ?? '',
    attendanceDays: (json['attendance_days'] as num?)?.toInt() ?? 0,
    studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
    averagePercentage: (json['average_percentage'] as num?)?.toDouble() ?? 0,
    dates: (json['dates'] as List<dynamic>? ?? const [])
        .map((date) => date.toString())
        .toList(),
    students: (json['students'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              StudentAttendanceReport.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
  );
}

class StudentAttendanceReport {
  const StudentAttendanceReport({
    required this.id,
    required this.registrationNo,
    required this.name,
    required this.present,
    required this.absent,
    required this.percentage,
    required this.presentDates,
    required this.absentDates,
    this.rollNo,
  });

  final int id;
  final String registrationNo;
  final String name;
  final int? rollNo;
  final int present;
  final int absent;
  final double percentage;
  final List<String> presentDates;
  final List<String> absentDates;

  factory StudentAttendanceReport.fromJson(Map<String, dynamic> json) =>
      StudentAttendanceReport(
        id: (json['id'] as num).toInt(),
        registrationNo: json['registration_no'] as String? ?? '',
        name: json['name'] as String? ?? '',
        rollNo: (json['roll_no'] as num?)?.toInt(),
        present: (json['present'] as num?)?.toInt() ?? 0,
        absent: (json['absent'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
        presentDates: (json['present_dates'] as List<dynamic>? ?? const [])
            .map((date) => date.toString())
            .toList(),
        absentDates: (json['absent_dates'] as List<dynamic>? ?? const [])
            .map((date) => date.toString())
            .toList(),
      );
}
