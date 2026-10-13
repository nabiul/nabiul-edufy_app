import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabiul_edufy_app/src/models/academic.dart';
import 'package:nabiul_edufy_app/src/screens/academic_screen.dart';
import 'package:nabiul_edufy_app/src/screens/academic_setup_screen.dart';
import 'package:nabiul_edufy_app/src/screens/login_screen.dart';
import 'package:nabiul_edufy_app/src/services/api_client.dart';
import 'package:nabiul_edufy_app/src/config/api_config.dart';

void main() {
  tearDown(() => ApiConfig.setBaseUrl(null));

  testWidgets('login screen validates required credentials', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(apiClient: ApiClient(), onLoggedIn: (_) {}),
      ),
    );

    expect(find.text('Welcome to Edufy'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter your username or email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('server URL can be saved without a framework error', (
    tester,
  ) async {
    String? savedUrl;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          apiClient: ApiClient(),
          onLoggedIn: (_) {},
          onApiUrlChanged: (url) async => savedUrl = url,
        ),
      ),
    );

    await tester.ensureVisible(find.byIcon(Icons.dns_outlined));
    await tester.tap(find.byIcon(Icons.dns_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'API base URL'),
      'http://192.168.1.20/nabiul-edufy/api/v1/',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(savedUrl, 'http://192.168.1.20/nabiul-edufy/api/v1');
    expect(find.text('Server address saved.'), findsOneWidget);
  });

  testWidgets('academic session dialog saves without a framework error', (
    tester,
  ) async {
    final apiClient = _AcademicSetupApiClient();
    await tester.pumpWidget(
      MaterialApp(
        home: AcademicSetupScreen(
          apiClient: apiClient,
          token: 'token',
          canManageSessions: true,
          canCreateClass: true,
          canEditClass: true,
          canCreateSection: true,
          canEditSection: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add session'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Session name *'),
      '2027',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(apiClient.savedYear, '2027');
    expect(find.text('Academic session saved.'), findsOneWidget);
  });

  testWidgets('student filter loads sections for the selected class only', (
    tester,
  ) async {
    final apiClient = _StudentFilterApiClient();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AcademicScreen(
            apiClient: apiClient,
            token: 'token',
            canCreateStudent: false,
            canEditStudent: false,
            canManageAttendance: false,
            canManageSessions: false,
            canCreateClass: false,
            canEditClass: false,
            canCreateSection: false,
            canEditSection: false,
            canPromoteStudent: false,
            canTransferStudent: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(apiClient.sectionLevelIds, isEmpty);
    await tester.ensureVisible(find.text('All').first);
    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('One').last);
    await tester.pumpAndSettle();

    expect(apiClient.sectionLevelIds, [1]);
    expect(tester.takeException(), isNull);
  });
}

class _AcademicSetupApiClient extends ApiClient {
  String? savedYear;

  @override
  Future<List<AcademicOption>> academicYears(String token) async => const [
    AcademicOption(id: 1, name: '2026', isCurrent: true),
  ];

  @override
  Future<List<AcademicOption>> academicLevels(String token) async => const [
    AcademicOption(id: 1, name: 'One', code: 'ONE'),
  ];

  @override
  Future<List<AcademicOption>> academicSections(
    String token, {
    int? levelId,
  }) async => const [AcademicOption(id: 1, name: 'A', code: 'A', levelId: 1)];

  @override
  Future<void> saveAcademicYear(
    String token, {
    required String name,
    int? yearId,
    bool isCurrent = false,
  }) async {
    savedYear = name;
  }
}

class _StudentFilterApiClient extends ApiClient {
  final List<int?> sectionLevelIds = [];

  @override
  Future<AcademicSummary> academicSummary(String token) async =>
      const AcademicSummary(
        studentCount: 0,
        levelCount: 1,
        sectionCount: 1,
        currentYear: AcademicOption(id: 1, name: '2026', isCurrent: true),
      );

  @override
  Future<List<AcademicOption>> academicYears(String token) async => const [
    AcademicOption(id: 1, name: '2026', isCurrent: true),
  ];

  @override
  Future<List<AcademicOption>> academicLevels(String token) async => const [
    AcademicOption(id: 1, name: 'One', code: 'ONE'),
  ];

  @override
  Future<List<AcademicOption>> academicSections(
    String token, {
    int? levelId,
  }) async {
    sectionLevelIds.add(levelId);
    return [AcademicOption(id: 1, name: 'A', code: 'A', levelId: levelId)];
  }

  @override
  Future<List<StudentSummary>> academicStudents(
    String token, {
    int? yearId,
    int? levelId,
    int? sectionId,
    String? search,
  }) async => const [];
}
