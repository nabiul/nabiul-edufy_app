import 'package:flutter_test/flutter_test.dart';
import 'package:nabiul_edufy_app/src/models/academic.dart';

void main() {
  test('academic summary and student data are parsed', () {
    final summary = AcademicSummary.fromJson({
      'current_year': {'id': 1, 'name': '2026', 'is_current': true},
      'student_count': 120,
      'level_count': 8,
      'section_count': 16,
    });
    final student = StudentSummary.fromJson({
      'id': 9,
      'registration_no': 'REG-009',
      'name_english': 'Test Student',
      'year_name': '2026',
      'level_name': 'Class One',
      'section_name': 'A',
      'roll_no': 7,
    });
    final details = StudentDetails.fromJson({
      'id': 9,
      'registration_no': 'REG-009',
      'name_english': 'Test Student',
      'academic_cycles': [
        {
          'id': 33,
          'year_id': 1,
          'level_id': 2,
          'section_id': 3,
          'roll_no': 7,
          'year': {'id': 1, 'name': '2026'},
          'level': {'id': 2, 'name': 'Class One'},
          'section': {'id': 3, 'name': 'A'},
        },
      ],
      'transfer_history': [
        {
          'id': 5,
          'year': '2026',
          'from_level': 'Class One',
          'from_section': 'A',
          'from_roll_no': 7,
          'to_level': 'Class One',
          'to_section': 'B',
          'to_roll_no': 8,
          'transferred_by': 'Admin User',
          'transferred_at': '2026-10-13T10:30:00+06:00',
        },
      ],
    });

    expect(summary.currentYear?.name, '2026');
    expect(summary.studentCount, 120);
    expect(student.registrationNo, 'REG-009');
    expect(student.rollNo, 7);
    expect(details.cycles.single.id, 33);
    expect(details.cycles.single.level, 'Class One');
    expect(details.transferHistory.single.toSection, 'B');
    expect(details.transferHistory.single.transferredBy, 'Admin User');
  });
}
