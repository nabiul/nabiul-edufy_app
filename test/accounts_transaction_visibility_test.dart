import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabiul_edufy_app/src/models/accounts.dart';
import 'package:nabiul_edufy_app/src/screens/accounts_screen.dart';
import 'package:nabiul_edufy_app/src/services/api_client.dart';
import 'package:nabiul_edufy_app/src/theme/app_theme.dart';

void main() {
  testWidgets('transaction text is visible on a narrow phone screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AccountsScreen(
            apiClient: _AccountsVisibilityApiClient(),
            token: 'token',
            canCreateDeposit: false,
            canCreateWithdrawal: false,
            canCreateTransfer: false,
            canCreateAccount: false,
            canEditAccount: false,
            canDeleteAccount: false,
            canCreatePurpose: false,
            canEditPurpose: false,
            canDeletePurpose: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'initial accounts screen');

    final purposeFinder = find.text('Student Fee');
    await tester.ensureVisible(purposeFinder);
    await tester.pumpAndSettle();

    expect(purposeFinder, findsOneWidget);
    expect(find.text('Bkash'), findsWidgets);
    expect(find.text('deposit-5913'), findsOneWidget);
    expect(find.text('+৳700.00'), findsOneWidget);

    final purpose = tester.widget<Text>(purposeFinder);
    expect(purpose.style?.color, const Color(0xFF050B18));

    final rect = tester.getRect(purposeFinder);
    expect(rect.width, greaterThan(0));
    expect(rect.height, greaterThan(0));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('transfer menu opens its page and submits a transfer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final apiClient = _TransferApiClient();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AccountsScreen(
            apiClient: apiClient,
            token: 'token',
            canCreateDeposit: true,
            canCreateWithdrawal: true,
            canCreateTransfer: true,
            canCreateAccount: true,
            canEditAccount: false,
            canDeleteAccount: false,
            canCreatePurpose: false,
            canEditPurpose: false,
            canDeletePurpose: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'initial transfer screen');

    await tester.tap(find.byKey(const Key('accounts-action-transfer')));
    await tester.pumpAndSettle();
    expect(find.text('Account transfers'), findsOneWidget);

    final newTransferButton = find.byKey(
      const Key('new-account-transfer-button'),
    );
    expect(newTransferButton, findsOneWidget);
    await tester.tap(newTransferButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'transfer entry dialog');
    expect(find.text('New account transfer'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount *'),
      '250',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'transfer confirmation');
    expect(find.text('Confirm transfer'), findsOneWidget);

    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();
    expect(apiClient.transferCreated, isTrue);
    expect(find.text('Transfer completed successfully.'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'completed transfer');
  });
}

class _AccountsVisibilityApiClient extends ApiClient {
  @override
  Future<AccountsSummary> accountsSummary(String token) async =>
      const AccountsSummary(
        totalBalance: 4500,
        totalIncome: 700,
        totalExpense: 0,
        thisMonthIncome: 700,
        thisMonthExpense: 0,
        accountCount: 1,
      );

  @override
  Future<List<AccountData>> accounts(String token) async => const [
    AccountData(
      id: 1,
      bankName: 'Bkash',
      openingBalance: 3800,
      currentBalance: 4500,
    ),
  ];

  @override
  Future<List<AccountPurposeData>> accountPurposes(String token) async =>
      const [];

  @override
  Future<List<AccountTransactionData>> accountTransactions(
    String token, {
    int? accountId,
    String? type,
    String? search,
  }) async => [
    AccountTransactionData(
      id: 5913,
      type: 'income',
      date: DateTime(2026, 10, 13),
      amount: 700,
      account: 'Bkash',
      purpose: 'Student Fee',
      voucherNumber: 'deposit-5913',
    ),
  ];

  @override
  Future<List<AccountTransferData>> accountTransfers(String token) async =>
      const [];
}

class _TransferApiClient extends _AccountsVisibilityApiClient {
  bool transferCreated = false;

  @override
  Future<List<AccountData>> accounts(String token) async => const [
    AccountData(
      id: 1,
      bankName: 'Cash',
      openingBalance: 1000,
      currentBalance: 1000,
    ),
    AccountData(
      id: 2,
      bankName: 'Bank',
      openingBalance: 500,
      currentBalance: 500,
    ),
  ];

  @override
  Future<void> createAccountTransfer(
    String token, {
    required int fromAccountId,
    required int toAccountId,
    required String date,
    required double amount,
    required String method,
    String? note,
  }) async {
    transferCreated =
        fromAccountId == 1 &&
        toAccountId == 2 &&
        amount == 250 &&
        method == 'cash';
  }
}
