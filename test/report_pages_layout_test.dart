import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabiul_edufy_app/src/models/accounts.dart';
import 'package:nabiul_edufy_app/src/models/academic.dart';
import 'package:nabiul_edufy_app/src/screens/accounts_report_screen.dart';
import 'package:nabiul_edufy_app/src/screens/attendance_report_screen.dart';
import 'package:nabiul_edufy_app/src/screens/fees_report_screen.dart';
import 'package:nabiul_edufy_app/src/services/api_client.dart';
import 'package:nabiul_edufy_app/src/theme/app_theme.dart';

void main() {
  const years = [AcademicOption(id: 1, name: '2026', isCurrent: true)];
  const levels = [AcademicOption(id: 2, name: 'Class One')];

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('accounts report has a responsive analytics layout', (
    tester,
  ) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AccountsReportScreen(
          apiClient: _ReportApiClient(),
          token: 'token',
          accounts: const [
            AccountData(
              id: 1,
              bankName: 'Cash',
              openingBalance: 0,
              currentBalance: 500,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cash flow report'), findsOneWidget);
    expect(find.text('Report filters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fees report has a responsive analytics layout', (tester) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: FeesReportScreen(
          apiClient: _ReportApiClient(),
          token: 'token',
          years: years,
          canCollectFees: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Collection insights'), findsOneWidget);
    expect(find.text('Report filters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attendance report has a responsive analytics layout', (
    tester,
  ) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AttendanceReportScreen(
          apiClient: _ReportApiClient(),
          token: 'token',
          years: years,
          levels: levels,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Monthly attendance'), findsOneWidget);
    expect(find.text('Report filters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _ReportApiClient extends ApiClient {
  @override
  Future<List<AcademicOption>> academicLevels(String token) async => const [
    AcademicOption(id: 2, name: 'Class One'),
  ];

  @override
  Future<List<AcademicOption>> academicSections(
    String token, {
    int? levelId,
  }) async => const [AcademicOption(id: 3, name: 'A', levelId: 2)];
}
