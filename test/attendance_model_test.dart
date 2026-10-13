import 'package:flutter_test/flutter_test.dart';
import 'package:nabiul_edufy_app/src/models/attendance.dart';

void main() {
  test('attendance register and students are parsed', () {
    final register = AttendanceRegister.fromJson({
      'date': '2026-10-12',
      'total': 2,
      'present': 1,
      'absent': 1,
      'students': [
        {
          'id': 7,
          'registration_no': 'REG-7',
          'name': 'Test Student',
          'roll_no': 3,
          'present': true,
          'remark': 'On time',
        },
      ],
    });

    expect(register.present, 1);
    expect(register.absent, 1);
    expect(register.students.single.id, 7);
    expect(register.students.single.present, isTrue);
  });

  test('monthly attendance report is parsed', () {
    final report = AttendanceReport.fromJson({
      'month': '2026-10',
      'attendance_days': 2,
      'student_count': 1,
      'average_percentage': 50,
      'dates': ['2026-10-11', '2026-10-12'],
      'students': [
        {
          'id': 7,
          'registration_no': 'REG-7',
          'name': 'Test Student',
          'roll_no': 3,
          'present': 1,
          'absent': 1,
          'percentage': 50,
          'present_dates': ['2026-10-11'],
          'absent_dates': ['2026-10-12'],
        },
      ],
    });

    expect(report.attendanceDays, 2);
    expect(report.averagePercentage, 50);
    expect(report.students.single.absentDates, ['2026-10-12']);
  });
}
