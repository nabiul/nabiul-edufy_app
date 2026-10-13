import 'package:flutter/material.dart';

import '../models/accounts.dart';
import '../services/api_client.dart';
import '../utils/receipt_export.dart';

Future<void> showVoucherDetails(
  BuildContext context, {
  required ApiClient apiClient,
  required String token,
  required AccountTransactionData transaction,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => FutureBuilder<AccountTransactionData>(
      future: apiClient.accountTransaction(
        token,
        type: transaction.type,
        id: transaction.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 280,
            child: Center(child: Text(snapshot.error.toString())),
          );
        }
        final item = snapshot.requireData;
        final color = item.isIncome ? Colors.green : Colors.red;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: .12),
                    child: Icon(
                      item.isIncome
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.isIncome ? 'Income voucher' : 'Expense voucher',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(item.voucherNumber ?? 'No voucher number'),
                      ],
                    ),
                  ),
                  Text(
                    _money(item.amount),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _VoucherActions(
                onPrint: () => printReceiptPdf(
                  title: item.isIncome ? 'Income receipt' : 'Expense receipt',
                  reference: item.voucherNumber ?? 'No voucher number',
                  amount: _money(item.amount),
                  rows: [
                    MapEntry('Date', _date(item.date)),
                    MapEntry('Account', item.account),
                    MapEntry('Purpose', item.purpose),
                    MapEntry('Student', item.student),
                    MapEntry('Registration', item.registrationNo),
                    MapEntry('Method', item.method),
                    MapEntry('Note', item.note),
                  ],
                ),
                onShare: () => shareReceiptPdf(
                  title: item.isIncome ? 'Income receipt' : 'Expense receipt',
                  reference: item.voucherNumber ?? 'No voucher number',
                  amount: _money(item.amount),
                  rows: [
                    MapEntry('Date', _date(item.date)),
                    MapEntry('Account', item.account),
                    MapEntry('Purpose', item.purpose),
                    MapEntry('Student', item.student),
                    MapEntry('Registration', item.registrationNo),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (item.student?.trim().isNotEmpty == true ||
                  item.studentInfo != null) ...[
                _StudentInfoCard(item: item),
                const SizedBox(height: 14),
              ],
              Card(
                child: Column(
                  children: [
                    _VoucherRow(label: 'Date', value: _date(item.date)),
                    _VoucherRow(label: 'Account', value: item.account),
                    _VoucherRow(
                      label: 'Account number',
                      value: item.accountNumber,
                    ),
                    _VoucherRow(label: 'Purpose', value: item.purpose),
                    _VoucherRow(label: 'Method', value: item.method),
                    _VoucherRow(label: 'Note', value: item.note),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _VoucherActions extends StatelessWidget {
  const _VoucherActions({required this.onPrint, required this.onShare});

  final VoidCallback onPrint;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onPrint,
          icon: const Icon(Icons.print_outlined),
          label: const Text('Print'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: FilledButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share'),
        ),
      ),
    ],
  );
}

class _StudentInfoCard extends StatelessWidget {
  const _StudentInfoCard({required this.item});

  final AccountTransactionData item;

  String? _value(String key) {
    final value =
        item.studentInfo?[key] ??
        (key == 'name'
            ? item.student
            : key == 'registration_no'
            ? item.registrationNo
            : null);
    final text = value?.toString().trim();
    return text?.isEmpty == true ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final name = _value('name') ?? 'Student';
    final registration = _value('registration_no');
    final details = <({String label, String value})>[
      if (registration != null) (label: 'Registration', value: registration),
      if (_value('session') != null)
        (label: 'Session', value: _value('session')!),
      if (_value('class') != null) (label: 'Class', value: _value('class')!),
      if (_value('section') != null)
        (label: 'Section', value: _value('section')!),
      if (_value('roll_no') != null) (label: 'Roll', value: _value('roll_no')!),
      if (_value('phone') != null) (label: 'Phone', value: _value('phone')!),
      if (item.studentFeeMonthLabel?.trim().isNotEmpty == true)
        (label: 'Fee month', value: item.studentFeeMonthLabel!.trim()),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF1FF), Color(0xFFF7F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9DFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFDCE2FF),
                child: Icon(Icons.person_rounded, color: Color(0xFF3D5AF1)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: details
                  .map(
                    (detail) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Color(0xFF526174),
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(text: '${detail.label}: '),
                            TextSpan(
                              text: detail.value,
                              style: const TextStyle(
                                color: Color(0xFF172033),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoucherRow extends StatelessWidget {
  const _VoucherRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: SizedBox(
        width: 180,
        child: Text(
          value?.isNotEmpty == true ? value! : '-',
          textAlign: TextAlign.end,
        ),
      ),
    );
  }
}

String _money(double value) => '৳${value.toStringAsFixed(2)}';

String _date(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
