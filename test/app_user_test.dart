import 'package:flutter_test/flutter_test.dart';
import 'package:nabiul_edufy_app/src/models/app_user.dart';

void main() {
  test('academic setup abilities are parsed', () {
    final user = AppUser.fromJson({
      'id': 1,
      'full_name': 'Academic Admin',
      'username': 'admin',
      'roles': ['super admin'],
      'abilities': {
        'manage_sessions': true,
        'create_class': true,
        'edit_class': true,
        'create_section': true,
        'edit_section': false,
        'promote_student': true,
        'transfer_student': true,
      },
    });

    expect(user.canManageSessions, isTrue);
    expect(user.canCreateClass, isTrue);
    expect(user.canEditClass, isTrue);
    expect(user.canCreateSection, isTrue);
    expect(user.canEditSection, isFalse);
    expect(user.canPromoteStudent, isTrue);
    expect(user.canTransferStudent, isTrue);
    expect(user.canManageAcademicSetup, isTrue);
  });
}
