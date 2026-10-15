import 'academic.dart';

class Enquiry {
  const Enquiry({required this.id, required this.number, required this.studentName, required this.phone, required this.status, this.guardianName, this.alternatePhone, this.email, this.levelId, this.levelName, this.yearId, this.yearName, this.source, this.nextFollowUpAt, this.notes, this.createdAt, this.admissionApplicationId, this.followUps = const []});
  final int id;
  final String number, studentName, phone, status;
  final String? guardianName, alternatePhone, email, levelName, yearName, source, nextFollowUpAt, notes, createdAt;
  final int? levelId, yearId, admissionApplicationId;
  final List<EnquiryFollowUp> followUps;

  factory Enquiry.fromJson(Map<String, dynamic> json) => Enquiry(
    id: (json['id'] as num).toInt(), number: json['enquiry_number'] ?? '', studentName: json['student_name'] ?? '', phone: json['phone'] ?? '', status: json['status'] ?? 'new', guardianName: json['guardian_name'], alternatePhone: json['alternate_phone'], email: json['email'], levelId: (json['level_id'] as num?)?.toInt(), levelName: json['level_name'], yearId: (json['year_id'] as num?)?.toInt(), yearName: json['year_name'], source: json['source'], nextFollowUpAt: json['next_follow_up_at'], notes: json['notes'], createdAt: json['created_at'], admissionApplicationId: (json['admission_application_id'] as num?)?.toInt(), followUps: (json['follow_ups'] as List<dynamic>? ?? const []).map((item) => EnquiryFollowUp.fromJson(item as Map<String, dynamic>)).toList(),
  );
}

class EnquiryFollowUp {
  const EnquiryFollowUp({this.contactedAt, this.contactMethod, this.outcome, this.notes, this.nextFollowUpAt, this.userName});
  final String? contactedAt, contactMethod, outcome, notes, nextFollowUpAt, userName;
  factory EnquiryFollowUp.fromJson(Map<String, dynamic> json) => EnquiryFollowUp(contactedAt: json['contacted_at'], contactMethod: json['contact_method'], outcome: json['outcome'], notes: json['notes'], nextFollowUpAt: json['next_follow_up_at'], userName: json['user_name']);
}

class EnquiryOptions {
  const EnquiryOptions({required this.levels, required this.years, required this.statuses});
  final List<AcademicOption> levels, years;
  final List<String> statuses;

  factory EnquiryOptions.fromJson(Map<String, dynamic> json) => EnquiryOptions(
    levels: (json['levels'] as List<dynamic>? ?? const []).map((item) => AcademicOption.fromJson(item as Map<String, dynamic>)).toList(),
    years: (json['years'] as List<dynamic>? ?? const []).map((item) => AcademicOption.fromJson(item as Map<String, dynamic>)).toList(),
    statuses: (json['statuses'] as List<dynamic>? ?? const []).map((item) => item.toString()).toList(),
  );
}
