import 'package:flutter/material.dart';

import '../models/fees.dart';
import '../services/api_client.dart';
import '../utils/receipt_export.dart';

Future<void> showFeeReceipt(
  BuildContext context, {
  required ApiClient apiClient,
  required String token,
  required int paymentId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => FutureBuilder<FeeReceipt>(
      future: apiClient.feeReceipt(token, paymentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 320,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 320,
            child: Center(child: Text(snapshot.error.toString())),
          );
        }
        final receipt = snapshot.requireData;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .72,
          minChildSize: .45,
          maxChildSize: .92,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF063F3B), Color(0xFF078467)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0x3379E7BD),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFFB9F4D9),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FEE RECEIPT',
                            style: TextStyle(
                              color: Color(0xFFB9F4D9),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            receipt.voucherNumber ?? 'No voucher number',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _money(receipt.payment.amount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ReceiptActions(
                onPrint: () => printReceiptPdf(
                  title: 'Fee receipt',
                  reference: receipt.voucherNumber ?? 'No voucher number',
                  amount: _money(receipt.payment.amount),
                  rows: [
                    MapEntry('Student', receipt.payment.studentName),
                    MapEntry('Registration', receipt.payment.registrationNo),
                    MapEntry('Session', receipt.year),
                    MapEntry('Class', receipt.payment.level),
                    MapEntry('Section', receipt.payment.section),
                    MapEntry('Fee month', receipt.payment.month),
                    MapEntry('Account', receipt.account),
                    MapEntry('Method', receipt.method),
                  ],
                ),
                onShare: () => shareReceiptPdf(
                  title: 'Fee receipt',
                  reference: receipt.voucherNumber ?? 'No voucher number',
                  amount: _money(receipt.payment.amount),
                  rows: [
                    MapEntry('Student', receipt.payment.studentName),
                    MapEntry('Registration', receipt.payment.registrationNo),
                    MapEntry('Session', receipt.year),
                    MapEntry('Fee month', receipt.payment.month),
                    MapEntry('Account', receipt.account),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ReceiptSection(
                title: 'Student & payment details',
                icon: Icons.person_outline_rounded,
                child: Column(
                  children: [
                    _ReceiptRow(
                      label: 'Student',
                      value: receipt.payment.studentName,
                    ),
                    _ReceiptRow(
                      label: 'Registration',
                      value: receipt.payment.registrationNo,
                    ),
                    _ReceiptRow(label: 'Session', value: receipt.year),
                    _ReceiptRow(label: 'Class', value: receipt.payment.level),
                    _ReceiptRow(
                      label: 'Section',
                      value: receipt.payment.section,
                    ),
                    _ReceiptRow(
                      label: 'Fee month',
                      value: receipt.payment.month,
                    ),
                    _ReceiptRow(label: 'Status', value: receipt.payment.status),
                    _ReceiptRow(label: 'Account', value: receipt.account),
                    _ReceiptRow(
                      label: 'Account number',
                      value: receipt.accountNumber,
                    ),
                    _ReceiptRow(label: 'Method', value: receipt.method),
                    _ReceiptRow(label: 'Note', value: receipt.note),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ReceiptSection(
                title: 'Payment breakdown',
                icon: Icons.receipt_long_outlined,
                child: Column(
                  children: [
                    ...receipt.items.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.sell_outlined,
                          color: Color(0xFF087A61),
                        ),
                        title: Text(
                          item.purpose,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: Text(
                          _money(item.amount),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (receipt.discount > 0)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Discount'),
                        trailing: Text('-${_money(receipt.discount)}'),
                      ),
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

class _ReceiptActions extends StatelessWidget {
  const _ReceiptActions({required this.onPrint, required this.onShare});

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

class _ReceiptSection extends StatelessWidget {
  const _ReceiptSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(15, 14, 15, 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2EAE7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF087A61)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const Divider(height: 18),
        child,
      ],
    ),
  );
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
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
