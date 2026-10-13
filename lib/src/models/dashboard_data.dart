import 'notice.dart';

class DashboardData {
  const DashboardData({
    required this.greeting,
    required this.siteName,
    required this.noticeCount,
    required this.latestNotices,
    this.studentCount = 0,
    this.accountCount = 0,
    this.feesCollectedThisMonth = 0,
    this.studentsByClass = const [],
  });

  final String greeting;
  final String siteName;
  final int noticeCount;
  final List<NoticeItem> latestNotices;
  final int studentCount;
  final int accountCount;
  final double feesCollectedThisMonth;
  final List<ClassStudentCount> studentsByClass;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final site = json['site'] as Map<String, dynamic>? ?? const {};
    return DashboardData(
      greeting: json['greeting'] as String? ?? 'Welcome back',
      siteName: site['site_name'] as String? ?? 'EDUSOL',
      noticeCount: json['notice_count'] as int? ?? 0,
      latestNotices: (json['latest_notices'] as List<dynamic>? ?? const [])
          .map((item) => NoticeItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
      accountCount: (json['account_count'] as num?)?.toInt() ?? 0,
      feesCollectedThisMonth:
          (json['fees_collected_this_month'] as num?)?.toDouble() ?? 0,
      studentsByClass: (json['students_by_class'] as List<dynamic>? ?? const [])
          .map(
            (item) => ClassStudentCount.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class ClassStudentCount {
  const ClassStudentCount({
    required this.className,
    required this.studentCount,
  });

  final String className;
  final int studentCount;

  factory ClassStudentCount.fromJson(Map<String, dynamic> json) =>
      ClassStudentCount(
        className: json['class_name'] as String? ?? 'Unknown',
        studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
      );
}
