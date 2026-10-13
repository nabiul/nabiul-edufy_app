import 'package:flutter/material.dart';

import '../models/accounts.dart';
import '../models/academic.dart';
import '../services/api_client.dart';
import '../widgets/form_design.dart';
import 'accounts_report_screen.dart';
import 'accounts_management_screen.dart';
import 'account_transfers_screen.dart';
import 'voucher_detail_sheet.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({
    required this.apiClient,
    required this.token,
    required this.canCreateDeposit,
    required this.canCreateWithdrawal,
    required this.canCreateTransfer,
    required this.canCreateAccount,
    required this.canEditAccount,
    required this.canDeleteAccount,
    required this.canCreatePurpose,
    required this.canEditPurpose,
    required this.canDeletePurpose,
    super.key,
  });

  final ApiClient apiClient;
  final String token;
  final bool canCreateDeposit;
  final bool canCreateWithdrawal;
  final bool canCreateTransfer;
  final bool canCreateAccount, canEditAccount, canDeleteAccount;
  final bool canCreatePurpose, canEditPurpose, canDeletePurpose;
  bool get canManage =>
      canCreateAccount ||
      canEditAccount ||
      canDeleteAccount ||
      canCreatePurpose ||
      canEditPurpose ||
      canDeletePurpose;

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _searchController = TextEditingController();
  AccountsSummary? _summary;
  List<AccountData> _accounts = const [];
  List<AccountPurposeData> _purposes = const [];
  List<AccountTransactionData> _transactions = const [];
  int? _accountId;
  String? _type;
  bool _loading = true;
  bool _filtering = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        widget.apiClient.accountsSummary(widget.token),
        widget.apiClient.accounts(widget.token),
        widget.apiClient.accountPurposes(widget.token),
        widget.apiClient.accountTransactions(widget.token),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as AccountsSummary;
        _accounts = results[1] as List<AccountData>;
        _purposes = results[2] as List<AccountPurposeData>;
        _transactions = results[3] as List<AccountTransactionData>;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load accounts data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _filterTransactions() async {
    setState(() => _filtering = true);
    try {
      final transactions = await widget.apiClient.accountTransactions(
        widget.token,
        accountId: _accountId,
        type: _type,
        search: _searchController.text.trim(),
      );
      if (mounted) setState(() => _transactions = transactions);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _filtering = false);
    }
  }

  Future<void> _createEntry({required bool isIncome}) async {
    final allowedPurposes = _purposes
        .where(
          (purpose) =>
              purpose.type == 'both' ||
              purpose.type == (isIncome ? 'income' : 'expanse'),
        )
        .toList();
    if (_accounts.isEmpty || allowedPurposes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _accounts.isEmpty
                ? 'No account is configured.'
                : 'No matching purpose is configured.',
          ),
        ),
      );
      return;
    }
    final input = await showAppFormSheet<_AccountEntryInput>(
      context: context,
      builder: (context) => _AccountEntryDialog(
        isIncome: isIncome,
        accounts: _accounts,
        purposes: allowedPurposes,
        apiClient: widget.apiClient,
        token: widget.token,
      ),
    );
    if (input == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isIncome ? 'Confirm income' : 'Confirm expense'),
        content: Text(
          '${isIncome ? 'Add' : 'Withdraw'} ${_money(input.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      if (isIncome) {
        await widget.apiClient.createDeposit(
          widget.token,
          accountId: input.accountId,
          purposeId: input.purposeId,
          date: input.date,
          amount: input.amount,
          method: input.method,
          studentId: input.studentId,
          note: input.note,
        );
      } else {
        await widget.apiClient.createWithdrawal(
          widget.token,
          accountId: input.accountId,
          purposeId: input.purposeId,
          date: input.date,
          amount: input.amount,
          method: input.method,
          note: input.note,
        );
      }
      if (!mounted) return;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIncome
                  ? 'Income added successfully.'
                  : 'Expense added successfully.',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _summary == null) {
      return _AccountsError(message: _error!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _AccountsSummaryView(summary: _summary!),
          const SizedBox(height: 14),
          _AccountsActionDock(
            onIncome: widget.canCreateDeposit
                ? () => _createEntry(isIncome: true)
                : null,
            onExpense: widget.canCreateWithdrawal
                ? () => _createEntry(isIncome: false)
                : null,
            onTransfer: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => AccountTransfersScreen(
                    apiClient: widget.apiClient,
                    token: widget.token,
                    canCreateTransfer: widget.canCreateTransfer,
                  ),
                ),
              );
              if (mounted) await _load();
            },
            onReport: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) => AccountsReportScreen(
                  apiClient: widget.apiClient,
                  token: widget.token,
                  accounts: _accounts,
                ),
              ),
            ),
            onManage: widget.canManage
                ? () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => AccountsManagementScreen(
                          apiClient: widget.apiClient,
                          token: widget.token,
                          canCreateAccount: widget.canCreateAccount,
                          canEditAccount: widget.canEditAccount,
                          canDeleteAccount: widget.canDeleteAccount,
                          canCreatePurpose: widget.canCreatePurpose,
                          canEditPurpose: widget.canEditPurpose,
                          canDeletePurpose: widget.canDeletePurpose,
                        ),
                      ),
                    );
                    if (changed == true && mounted) await _load();
                  }
                : null,
          ),
          const SizedBox(height: 24),
          _TitleRow(title: 'Accounts', count: _accounts.length),
          const SizedBox(height: 10),
          if (_accounts.isEmpty)
            const Text('No accounts configured.')
          else
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _accounts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) =>
                    _AccountCard(account: _accounts[index]),
              ),
            ),
          const SizedBox(height: 24),
          _TitleRow(title: 'Transaction history', count: _transactions.length),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _filterTransactions(),
            decoration: InputDecoration(
              hintText: 'Voucher, purpose, student or note',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _filtering
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: _filterTransactions,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _accountId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ..._accounts.map(
                      (account) => DropdownMenuItem<int?>(
                        value: account.id,
                        child: Text(
                          account.bankName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _accountId = value);
                    _filterTransactions();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('All')),
                    DropdownMenuItem<String?>(
                      value: 'income',
                      child: Text('Income'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'expense',
                      child: Text('Expense'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _type = value);
                    _filterTransactions();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_transactions.isEmpty)
            const Text('No matching transactions found.')
          else
            ..._transactions.map(
              (transaction) => _TransactionCard(
                transaction: transaction,
                onTap: () => showVoucherDetails(
                  context,
                  apiClient: widget.apiClient,
                  token: widget.token,
                  transaction: transaction,
                ),
              ),
            ),
          const SizedBox(height: 24),
          _TitleRow(title: 'Purposes', count: _purposes.length),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _purposes
                .map(
                  (purpose) => Chip(
                    backgroundColor: const Color(0xFFF0F2F8),
                    side: const BorderSide(color: Color(0xFFDCE2ED)),
                    avatar: Icon(
                      purpose.type == 'income'
                          ? Icons.south_west_rounded
                          : purpose.type == 'expanse'
                          ? Icons.north_east_rounded
                          : Icons.swap_vert_rounded,
                      size: 18,
                      color: purpose.type == 'income'
                          ? const Color(0xFF087A61)
                          : purpose.type == 'expanse'
                          ? const Color(0xFFC04444)
                          : const Color(0xFF465A86),
                    ),
                    label: Text(
                      purpose.name.trim().isEmpty
                          ? 'Unnamed purpose'
                          : purpose.name.trim(),
                    ),
                    labelStyle: const TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AccountEntryInput {
  const _AccountEntryInput({
    required this.accountId,
    required this.purposeId,
    required this.date,
    required this.amount,
    required this.method,
    required this.note,
    this.studentId,
  });

  final int accountId;
  final int purposeId;
  final String date;
  final double amount;
  final String method;
  final String note;
  final int? studentId;
}

class _AccountEntryDialog extends StatefulWidget {
  const _AccountEntryDialog({
    required this.isIncome,
    required this.accounts,
    required this.purposes,
    required this.apiClient,
    required this.token,
  });

  final bool isIncome;
  final List<AccountData> accounts;
  final List<AccountPurposeData> purposes;
  final ApiClient apiClient;
  final String token;

  @override
  State<_AccountEntryDialog> createState() => _AccountEntryDialogState();
}

class _AccountEntryDialogState extends State<_AccountEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late int _accountId;
  late int _purposeId;
  late String _date;
  String _method = 'cash';
  int? _studentId;
  final _studentSearchController = TextEditingController();
  List<StudentSummary> _students = const [];
  bool _studentSearching = false;

  @override
  void initState() {
    super.initState();
    _accountId = widget.accounts.first.id;
    _purposeId = widget.purposes.first.id;
    _date = _isoDate(DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date) ?? DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (value != null && mounted) setState(() => _date = _isoDate(value));
  }

  Future<void> _searchStudents(String value) async {
    final query = value.trim();
    if (!widget.isIncome || query.isEmpty) {
      if (mounted) setState(() => _students = const []);
      return;
    }
    setState(() => _studentSearching = true);
    try {
      final page = await widget.apiClient.academicStudentsPage(
        widget.token,
        search: query,
      );
      if (mounted) setState(() => _students = page.students);
    } on ApiException {
      if (mounted) setState(() => _students = const []);
    } finally {
      if (mounted) setState(() => _studentSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: FormDialogHeader(
        title: widget.isIncome ? 'Add income' : 'Add expense',
        subtitle: widget.isIncome
            ? 'Record money received into an account.'
            : 'Record money paid from an account.',
        icon: widget.isIncome
            ? Icons.south_west_rounded
            : Icons.north_east_rounded,
        color: widget.isIncome
            ? const Color(0xFF168A65)
            : const Color(0xFFD94C4C),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _accountId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Account *'),
                  items: widget.accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Text(account.bankName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _accountId = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _purposeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Purpose *'),
                  items: widget.purposes
                      .map(
                        (purpose) => DropdownMenuItem(
                          value: purpose.id,
                          child: Text(purpose.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _purposeId = value!),
                ),
                if (widget.isIncome) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _studentSearchController,
                    onChanged: _searchStudents,
                    decoration: const InputDecoration(
                      labelText: 'Search student (optional)',
                      hintText: 'Name, registration, class, section or roll',
                      prefixIcon: Icon(Icons.person_search_rounded),
                    ),
                  ),
                  if (_studentSearching)
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  ..._students.map(
                    (student) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.school_outlined, size: 17),
                      ),
                      title: Text(student.name),
                      subtitle: Text(
                        '${student.registrationNo} • ${student.levelName} ${student.sectionName} • Roll ${student.rollNo ?? '-'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: _studentId == student.id
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF087A61),
                            )
                          : null,
                      onTap: () => setState(() {
                        _studentId = student.id;
                        _studentSearchController.text = student.name;
                        _students = [student];
                      }),
                    ),
                  ),
                  if (_studentId != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _studentId = null;
                          _studentSearchController.clear();
                          _students = const [];
                        }),
                        child: const Text('Clear student'),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount *'),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    return amount == null || amount <= 0
                        ? 'Enter a valid amount.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                AppDateField(
                  label: 'Date',
                  value: _date,
                  required: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: const InputDecoration(labelText: 'Method *'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'check', child: Text('Cheque')),
                    DropdownMenuItem(
                      value: 'online_banking',
                      child: Text('Online banking'),
                    ),
                    DropdownMenuItem(
                      value: 'mobile_banking',
                      child: Text('Mobile banking'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _method = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _AccountEntryInput(
                accountId: _accountId,
                purposeId: _purposeId,
                date: _date,
                amount: double.parse(_amountController.text),
                method: _method,
                note: _noteController.text.trim(),
                studentId: _studentId,
              ),
            );
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _AccountTransferInput {
  const _AccountTransferInput({
    required this.fromAccountId,
    required this.toAccountId,
    required this.date,
    required this.amount,
    required this.method,
    required this.note,
  });

  final int fromAccountId;
  final int toAccountId;
  final String date;
  final double amount;
  final String method;
  final String note;
}

class _AccountTransferDialog extends StatefulWidget {
  const _AccountTransferDialog({required this.accounts});

  final List<AccountData> accounts;

  @override
  State<_AccountTransferDialog> createState() => _AccountTransferDialogState();
}

class _AccountTransferDialogState extends State<_AccountTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late int _fromAccountId;
  late int _toAccountId;
  late String _date;
  String _method = 'cash';

  AccountData get _fromAccount =>
      widget.accounts.firstWhere((account) => account.id == _fromAccountId);

  @override
  void initState() {
    super.initState();
    _fromAccountId = widget.accounts.first.id;
    _toAccountId = widget.accounts[1].id;
    _date = _isoDate(DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (value != null && mounted) setState(() => _date = _isoDate(value));
  }

  String _accountLabel(AccountData account) {
    return account.bankName.trim().isEmpty
        ? 'Account #${account.id}'
        : account.bankName.trim();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('New account transfer'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _fromAccountId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'From account'),
                  items: widget.accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Text(
                            _accountLabel(account),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _fromAccountId = value;
                      if (_toAccountId == value) {
                        _toAccountId = widget.accounts
                            .firstWhere((account) => account.id != value)
                            .id;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey(_toAccountId),
                  initialValue: _toAccountId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'To account'),
                  items: widget.accounts
                      .where((account) => account.id != _fromAccountId)
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Text(
                            _accountLabel(account),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _toAccountId = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    helperText:
                        'Available: ${_money(_fromAccount.currentBalance)}',
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount.';
                    }
                    if (amount > _fromAccount.currentBalance) {
                      return 'Amount exceeds the available balance.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppDateField(
                  label: 'Transfer date',
                  value: _date,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: const InputDecoration(labelText: 'Method'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'check', child: Text('Cheque')),
                    DropdownMenuItem(
                      value: 'online_banking',
                      child: Text('Online banking'),
                    ),
                    DropdownMenuItem(
                      value: 'mobile_banking',
                      child: Text('Mobile banking'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _method = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _AccountTransferInput(
                fromAccountId: _fromAccountId,
                toAccountId: _toAccountId,
                date: _date,
                amount: double.parse(_amountController.text),
                method: _method,
                note: _noteController.text.trim(),
              ),
            );
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _AccountsSummaryView extends StatelessWidget {
  const _AccountsSummaryView({required this.summary});

  final AccountsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF121C32), Color(0xFF293957)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28121C32),
            blurRadius: 26,
            offset: Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 132,
              color: Colors.white.withValues(alpha: .045),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.wallet_rounded,
                      color: Color(0xFFFFC86B),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'MASTER LEDGER',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFE4EAF6),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${summary.accountCount} accounts',
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFFC7D1E5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Combined balance',
                style: TextStyle(color: Color(0xFFE4EAF6), fontSize: 13),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _money(summary.totalBalance),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _FlowCard(
                      label: 'Total income',
                      value: summary.totalIncome,
                      color: const Color(0xFF68D6A6),
                      icon: Icons.south_west_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FlowCard(
                      label: 'Total expense',
                      value: summary.totalExpense,
                      color: const Color(0xFFFF8B82),
                      icon: Icons.north_east_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFE4EAF6),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(value),
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountsActionDock extends StatelessWidget {
  const _AccountsActionDock({
    this.onIncome,
    this.onExpense,
    required this.onTransfer,
    required this.onReport,
    this.onManage,
  });
  final VoidCallback? onIncome;
  final VoidCallback? onExpense;
  final VoidCallback onTransfer;
  final VoidCallback onReport;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final actions =
        <({String label, IconData icon, Color color, VoidCallback callback})>[
          if (onIncome != null)
            (
              label: 'Income',
              icon: Icons.add_rounded,
              color: const Color(0xFF168A65),
              callback: onIncome!,
            ),
          if (onExpense != null)
            (
              label: 'Expense',
              icon: Icons.remove_rounded,
              color: const Color(0xFFD94C4C),
              callback: onExpense!,
            ),
          (
            label: 'Transfer',
            icon: Icons.swap_horiz_rounded,
            color: const Color(0xFF1677A6),
            callback: onTransfer,
          ),
          (
            label: 'Report',
            icon: Icons.query_stats_rounded,
            color: const Color(0xFF465A86),
            callback: onReport,
          ),
          if (onManage != null)
            (
              label: 'Manage',
              icon: Icons.tune_rounded,
              color: const Color(0xFF7B5DB5),
              callback: onManage!,
            ),
        ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E5EE)),
      ),
      child: Row(
        children: actions
            .map(
              (action) => Expanded(
                child: InkWell(
                  key: Key('accounts-action-${action.label.toLowerCase()}'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: action.callback,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: action.color.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            action.icon,
                            color: action.color,
                            size: 21,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          action.label,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final AccountData account;

  @override
  Widget build(BuildContext context) {
    final tones = <List<Color>>[
      const [Color(0xFF273B68), Color(0xFF49679B)],
      const [Color(0xFF57406C), Color(0xFF8C689E)],
      const [Color(0xFF164E4A), Color(0xFF2A7C70)],
    ];
    final tone = tones[account.id.abs() % tones.length];
    final displayName = account.bankName.trim().isNotEmpty
        ? account.bankName.trim()
        : account.accountName?.trim().isNotEmpty == true
        ? account.accountName!.trim()
        : 'Unnamed account';
    return SizedBox(
      width: 230,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: tone,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.white70,
                  ),
                  const Spacer(),
                  Container(
                    width: 28,
                    height: 19,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD781).withValues(alpha: .8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              Text(
                account.accountNumber ?? 'No account number',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFE2E9F5), fontSize: 12),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _money(account.currentBalance),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, required this.onTap});

  final AccountTransactionData transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = transaction.isIncome
        ? const Color(0xFF087A61)
        : const Color(0xFFC04444);
    final purpose = transaction.purpose?.trim().isNotEmpty == true
        ? transaction.purpose!.trim()
        : transaction.isIncome
        ? 'Income'
        : 'Expense';
    final account = transaction.account?.trim().isNotEmpty == true
        ? transaction.account!.trim()
        : 'No account';
    final voucher = transaction.voucherNumber?.trim();
    final student = transaction.student?.trim();
    final registration = transaction.registrationNo?.trim();
    final feeMonth = transaction.studentFeeMonthLabel?.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EBF1)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 12,
            bottom: 12,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .11),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          transaction.isIncome
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color: color,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              purpose,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF050B18),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 6,
                              runSpacing: 3,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  account,
                                  style: const TextStyle(
                                    color: Color(0xFF24324A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Text(
                                  '•',
                                  style: TextStyle(color: Color(0xFF526079)),
                                ),
                                Text(
                                  _date(transaction.date),
                                  style: const TextStyle(
                                    color: Color(0xFF24324A),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (student?.isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    size: 15,
                                    color: Color(0xFF526079),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      registration?.isNotEmpty == true
                                          ? '$student • $registration'
                                          : student!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF344054),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (feeMonth?.isNotEmpty == true) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'Fee month: $feeMonth',
                                  style: const TextStyle(
                                    color: Color(0xFF526079),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF98A2B3),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          voucher?.isNotEmpty == true ? voucher! : 'No voucher',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF344054),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '${transaction.isIncome ? '+' : '-'}${_money(transaction.amount)}',
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(count.toString()),
      ],
    );
  }
}

class _AccountsError extends StatelessWidget {
  const _AccountsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

String _money(double value) => '৳${value.toStringAsFixed(2)}';

String _isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _date(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
