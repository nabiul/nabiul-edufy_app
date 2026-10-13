import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/accounts.dart';
import '../services/api_client.dart';
import '../widgets/form_design.dart';

class AccountsManagementScreen extends StatefulWidget {
  const AccountsManagementScreen({
    required this.apiClient,
    required this.token,
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
  final bool canCreateAccount;
  final bool canEditAccount;
  final bool canDeleteAccount;
  final bool canCreatePurpose;
  final bool canEditPurpose;
  final bool canDeletePurpose;

  @override
  State<AccountsManagementScreen> createState() =>
      _AccountsManagementScreenState();
}

class _AccountsManagementScreenState extends State<AccountsManagementScreen> {
  List<AccountData> _accounts = const [];
  List<AccountPurposeData> _purposes = const [];
  bool _loading = true;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    List<AccountData>? accounts;
    List<AccountPurposeData>? purposes;
    final errors = <String>[];
    await Future.wait<void>([
      () async {
        try {
          accounts = await widget.apiClient.accounts(widget.token);
        } catch (error) {
          errors.add(_errorMessage(error));
        }
      }(),
      () async {
        try {
          purposes = await widget.apiClient.accountPurposes(widget.token);
        } catch (error) {
          errors.add(_errorMessage(error));
        }
      }(),
    ]);
    if (!mounted) return;
    setState(() {
      if (accounts != null) _accounts = accounts!;
      if (purposes != null) _purposes = purposes!;
      _error = errors.isEmpty ? null : errors.toSet().join('\n');
      _loading = false;
    });
  }

  String _errorMessage(Object error) => error is ApiException
      ? error.message
      : 'Could not read data from ${ApiConfig.baseUrl}.';

  Future<void> _editAccount([AccountData? account]) async {
    final input = await showAppFormSheet<_AccountInput>(
      context: context,
      builder: (_) => _AccountDialog(account: account),
    );
    if (input == null || !mounted) return;
    try {
      await widget.apiClient.saveAccount(
        widget.token,
        id: account?.id,
        bankName: input.bankName,
        accountName: input.accountName,
        accountNumber: input.accountNumber,
        bankBranch: input.bankBranch,
        openingBalance: input.openingBalance,
      );
      await _saved(account == null ? 'Account created.' : 'Account updated.');
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _editPurpose([AccountPurposeData? purpose]) async {
    final input = await showAppFormSheet<_PurposeInput>(
      context: context,
      builder: (_) => _PurposeDialog(
        purpose: purpose,
        purposes: _purposes.where((item) => item.id != purpose?.id).toList(),
      ),
    );
    if (input == null || !mounted) return;
    try {
      await widget.apiClient.saveAccountPurpose(
        widget.token,
        id: purpose?.id,
        name: input.name,
        type: input.type,
        parentId: input.parentId,
      );
      await _saved(purpose == null ? 'Purpose created.' : 'Purpose updated.');
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _delete({
    required String label,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $label?'),
        content: const Text(
          'This action is only allowed when the record is not in use.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await action();
      await _saved('$label deleted.');
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _saved(String message) async {
    _changed = true;
    await _load();
    if (mounted) _message(message);
  }

  void _message(String value) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage accounts'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Accounts'),
              Tab(text: 'Purposes'),
            ],
          ),
        ),
        body: _loading && _accounts.isEmpty && _purposes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _accounts.isEmpty && _purposes.isEmpty
            ? _AccountsManagementLoadError(
                message: _error!,
                server: ApiConfig.baseUrl,
                onRetry: _load,
              )
            : TabBarView(children: [_accountList(), _purposeList()]),
      ),
    ),
  );

  Widget _accountList() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _listStatus('Existing accounts', _accounts.length),
      if (_error != null) _warning(_error!),
      if (widget.canCreateAccount)
        FilledButton.icon(
          onPressed: () => _editAccount(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add account'),
        ),
      const SizedBox(height: 12),
      if (_accounts.isEmpty) const _AccountsEmptyList('No accounts found.'),
      ..._accounts.map(
        (item) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.account_balance_rounded),
            ),
            title: Text(
              item.bankName.trim().isNotEmpty
                  ? item.bankName.trim()
                  : item.accountName?.trim().isNotEmpty == true
                  ? item.accountName!.trim()
                  : 'Unnamed account',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '${item.accountNumber ?? 'No account number'}\nBalance ${item.currentBalance.toStringAsFixed(2)}',
              style: const TextStyle(color: Color(0xFF4E5B73), height: 1.35),
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) => value == 'edit'
                  ? _editAccount(item)
                  : _delete(
                      label: 'account',
                      action: () =>
                          widget.apiClient.deleteAccount(widget.token, item.id),
                    ),
              itemBuilder: (_) => [
                if (widget.canEditAccount)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (widget.canDeleteAccount)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _purposeList() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _listStatus('Existing purposes', _purposes.length),
      if (_error != null) _warning(_error!),
      if (widget.canCreatePurpose)
        FilledButton.icon(
          onPressed: () => _editPurpose(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add purpose'),
        ),
      const SizedBox(height: 12),
      if (_purposes.isEmpty)
        const _AccountsEmptyList('No account purposes found.'),
      ..._purposes.map(
        (item) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.category_outlined)),
            title: Text(
              item.name.trim().isEmpty ? 'Unnamed purpose' : item.name.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '${item.typeLabel}${item.parent == null ? '' : ' • Parent: ${item.parent}'}',
              style: const TextStyle(color: Color(0xFF4E5B73)),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => value == 'edit'
                  ? _editPurpose(item)
                  : _delete(
                      label: 'purpose',
                      action: () => widget.apiClient.deleteAccountPurpose(
                        widget.token,
                        item.id,
                      ),
                    ),
              itemBuilder: (_) => [
                if (widget.canEditPurpose)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (widget.canDeletePurpose)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _listStatus(String label, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        Chip(label: Text('$count')),
      ],
    ),
  );

  Widget _warning(String message) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: const Icon(Icons.warning_amber_rounded),
      title: Text(message),
      trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
    ),
  );
}

class _AccountsEmptyList extends StatelessWidget {
  const _AccountsEmptyList(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Center(child: Text(message)),
  );
}

class _AccountsManagementLoadError extends StatelessWidget {
  const _AccountsManagementLoadError({
    required this.message,
    required this.server,
    required this.onRetry,
  });
  final String message;
  final String server;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            server,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _AccountInput {
  const _AccountInput(
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.bankBranch,
    this.openingBalance,
  );
  final String bankName;
  final String? accountName;
  final String? accountNumber;
  final String? bankBranch;
  final double openingBalance;
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({this.account});
  final AccountData? account;
  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final _key = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _fields = [
      a?.bankName,
      a?.accountName,
      a?.accountNumber,
      a?.bankBranch,
      a?.openingBalance.toStringAsFixed(2),
    ].map((value) => TextEditingController(text: value)).toList();
  }

  @override
  void dispose() {
    for (final item in _fields) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormSheet(
    title: FormDialogHeader(
      title: widget.account == null ? 'Add account' : 'Edit account',
      subtitle: 'Keep bank identity and opening balance accurate.',
      icon: Icons.account_balance_rounded,
      color: const Color(0xFF16738D),
    ),
    content: Form(
      key: _key,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(0, 'Bank / account title', required: true),
            const SizedBox(height: 10),
            _field(1, 'Account holder'),
            const SizedBox(height: 10),
            _field(2, 'Account number'),
            const SizedBox(height: 10),
            _field(3, 'Branch'),
            const SizedBox(height: 10),
            _field(4, 'Opening balance', number: true, required: true),
          ],
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
          if (!_key.currentState!.validate()) return;
          String? optional(int i) =>
              _fields[i].text.trim().isEmpty ? null : _fields[i].text.trim();
          Navigator.pop(
            context,
            _AccountInput(
              _fields[0].text.trim(),
              optional(1),
              optional(2),
              optional(3),
              double.parse(_fields[4].text),
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
  Widget _field(
    int index,
    String label, {
    bool number = false,
    bool required = false,
  }) => TextFormField(
    controller: _fields[index],
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : null,
    decoration: InputDecoration(
      labelText: required ? '$label *' : '$label (optional)',
    ),
    validator: (value) {
      if (required && (value == null || value.trim().isEmpty)) {
        return 'Required.';
      }
      if (number && double.tryParse(value ?? '') == null) {
        return 'Enter a valid amount.';
      }
      return null;
    },
  );
}

class _PurposeInput {
  const _PurposeInput(this.name, this.type, this.parentId);
  final String name;
  final String type;
  final int? parentId;
}

class _PurposeDialog extends StatefulWidget {
  const _PurposeDialog({required this.purposes, this.purpose});
  final List<AccountPurposeData> purposes;
  final AccountPurposeData? purpose;
  @override
  State<_PurposeDialog> createState() => _PurposeDialogState();
}

class _PurposeDialogState extends State<_PurposeDialog> {
  late final TextEditingController _name;
  late String _type;
  int? _parentId;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.purpose?.name);
    _type = widget.purpose?.type ?? 'income';
    _parentId = widget.purpose?.parentId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormSheet(
    title: FormDialogHeader(
      title: widget.purpose == null ? 'Add purpose' : 'Edit purpose',
      subtitle: 'Organize income and expense entries for clear reporting.',
      icon: Icons.category_rounded,
      color: const Color(0xFF7B5DB5),
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Purpose name *'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type *'),
            items: const [
              DropdownMenuItem(value: 'income', child: Text('Income')),
              DropdownMenuItem(value: 'expanse', child: Text('Expense')),
              DropdownMenuItem(value: 'both', child: Text('Both')),
            ],
            onChanged: (value) => setState(() => _type = value!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            initialValue: _parentId,
            decoration: const InputDecoration(
              labelText: 'Parent purpose (optional)',
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('None')),
              ...widget.purposes.map(
                (p) => DropdownMenuItem<int?>(value: p.id, child: Text(p.name)),
              ),
            ],
            onChanged: (value) => setState(() => _parentId = value),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final name = _name.text.trim();
          if (name.isNotEmpty) {
            Navigator.pop(context, _PurposeInput(name, _type, _parentId));
          }
        },
        child: const Text('Save'),
      ),
    ],
  );
}
