import 'package:flutter/material.dart';

import '../models/accounts.dart';
import '../services/api_client.dart';
import '../widgets/form_design.dart';

class AccountTransfersScreen extends StatefulWidget {
  const AccountTransfersScreen({
    required this.apiClient,
    required this.token,
    required this.canCreateTransfer,
    super.key,
  });

  final ApiClient apiClient;
  final String token;
  final bool canCreateTransfer;

  @override
  State<AccountTransfersScreen> createState() => _AccountTransfersScreenState();
}

class _AccountTransfersScreenState extends State<AccountTransfersScreen> {
  List<AccountData> _accounts = const [];
  List<AccountTransferData> _transfers = const [];
  bool _loading = true;
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
    try {
      final results = await Future.wait<dynamic>([
        widget.apiClient.accounts(widget.token),
        widget.apiClient.accountTransfers(widget.token),
      ]);
      if (!mounted) return;
      setState(() {
        _accounts = results[0] as List<AccountData>;
        _transfers = results[1] as List<AccountTransferData>;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load transfers.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createTransfer() async {
    if (_accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least two accounts are required.')),
      );
      return;
    }
    final input = await showAppFormSheet<_TransferInput>(
      context: context,
      builder: (_) => _TransferDialog(accounts: _accounts),
    );
    if (input == null || !mounted) return;

    final from = _accounts.firstWhere(
      (account) => account.id == input.fromAccountId,
    );
    final to = _accounts.firstWhere(
      (account) => account.id == input.toAccountId,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm transfer'),
        content: Text(
          'Transfer ${_money(input.amount)} from ${from.bankName} to ${to.bankName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await widget.apiClient.createAccountTransfer(
        widget.token,
        fromAccountId: input.fromAccountId,
        toAccountId: input.toAccountId,
        date: input.date,
        amount: input.amount,
        method: input.method,
        note: input.note,
      );
      if (!mounted) return;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer completed successfully.')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Account transfers')),
      floatingActionButton: widget.canCreateTransfer && !_loading
          ? FloatingActionButton.extended(
              key: const Key('new-account-transfer-button'),
              onPressed: _createTransfer,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('New transfer'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _TransferError(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: _TransferHeader(
                        transferCount: _transfers.length,
                        accountCount: _accounts.length,
                      ),
                    ),
                  ),
                  if (_transfers.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyTransfers(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList.separated(
                        itemCount: _transfers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _TransferCard(transfer: _transfers[index]),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _TransferHeader extends StatelessWidget {
  const _TransferHeader({
    required this.transferCount,
    required this.accountCount,
  });

  final int transferCount;
  final int accountCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF12314A), Color(0xFF176B82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACCOUNT TRANSFERS',
                  style: TextStyle(
                    color: Color(0xFFD8ECF2),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$transferCount transfers across $accountCount accounts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.transfer});

  final AccountTransferData transfer;

  @override
  Widget build(BuildContext context) {
    final from = transfer.fromAccount?.trim().isNotEmpty == true
        ? transfer.fromAccount!.trim()
        : 'Unknown account';
    final to = transfer.toAccount?.trim().isNotEmpty == true
        ? transfer.toAccount!.trim()
        : 'Unknown account';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  transfer.voucherNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF526174),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _date(transfer.date),
                style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AccountEnd(label: 'FROM', account: from),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F4F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF16738D),
                  size: 20,
                ),
              ),
              Expanded(
                child: _AccountEnd(label: 'TO', account: to, alignEnd: true),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _money(transfer.amount),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF123F50),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (transfer.note?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              transfer.note!.trim(),
              style: const TextStyle(color: Color(0xFF526174), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountEnd extends StatelessWidget {
  const _AccountEnd({
    required this.label,
    required this.account,
    this.alignEnd = false,
  });

  final String label;
  final String account;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8390A2),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          account,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            color: Color(0xFF172033),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyTransfers extends StatelessWidget {
  const _EmptyTransfers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz_rounded, size: 52, color: Color(0xFF98A2B3)),
            SizedBox(height: 12),
            Text(
              'No transfers recorded yet.',
              style: TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferError extends StatelessWidget {
  const _TransferError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _TransferInput {
  const _TransferInput({
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

class _TransferDialog extends StatefulWidget {
  const _TransferDialog({required this.accounts});

  final List<AccountData> accounts;

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
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

  String _accountLabel(AccountData account) => account.bankName.trim().isEmpty
      ? 'Account #${account.id}'
      : account.bankName.trim();

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const FormDialogHeader(
        title: 'New account transfer',
        subtitle: 'Move funds safely between two different accounts.',
        icon: Icons.swap_horiz_rounded,
        color: Color(0xFF16738D),
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
                  initialValue: _fromAccountId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'From account *',
                  ),
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
                  decoration: const InputDecoration(labelText: 'To account *'),
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
                    labelText: 'Amount *',
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
                  required: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  isExpanded: true,
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
              _TransferInput(
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

String _money(double value) => '৳${value.toStringAsFixed(2)}';

String _isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _date(DateTime? value) => value == null
    ? '-'
    : '${value.day.toString().padLeft(2, '0')}/'
          '${value.month.toString().padLeft(2, '0')}/${value.year}';
