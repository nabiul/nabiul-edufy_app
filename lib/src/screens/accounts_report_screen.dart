import 'package:flutter/material.dart';

import '../models/accounts.dart';
import '../services/api_client.dart';
import '../widgets/report_design.dart';
import 'voucher_detail_sheet.dart';

class AccountsReportScreen extends StatefulWidget {
  const AccountsReportScreen({
    required this.apiClient,
    required this.token,
    required this.accounts,
    super.key,
  });

  final ApiClient apiClient;
  final String token;
  final List<AccountData> accounts;

  @override
  State<AccountsReportScreen> createState() => _AccountsReportScreenState();
}

class _AccountsReportScreenState extends State<AccountsReportScreen> {
  AccountsReport? _report;
  int? _accountId;
  late String _startDate;
  late String _endDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _startDate = _isoDate(DateTime(today.year, today.month));
    _endDate = _isoDate(today);
  }

  Future<void> _pickDate({required bool start}) async {
    final initial =
        DateTime.tryParse(start ? _startDate : _endDate) ?? DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = _isoDate(value);
        if (_endDate.compareTo(_startDate) < 0) _endDate = _startDate;
      } else {
        _endDate = _isoDate(value);
      }
      _report = null;
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final report = await widget.apiClient.accountsReport(
        widget.token,
        startDate: _startDate,
        endDate: _endDate,
        accountId: _accountId,
      );
      if (mounted) setState(() => _report = report);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts report')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const ReportPageIntro(
            eyebrow: 'FINANCIAL ANALYTICS',
            title: 'Cash flow report',
            subtitle:
                'Review income, expenses, purpose totals and vouchers for any period.',
            icon: Icons.query_stats_rounded,
            colors: [Color(0xFF17233C), Color(0xFF3D5AF1)],
          ),
          const SizedBox(height: 24),
          const ReportSectionHeader(
            title: 'Report filters',
            subtitle: 'Choose an account and reporting period.',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _accountId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Account'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All accounts'),
              ),
              ...widget.accounts.map(
                (account) => DropdownMenuItem<int?>(
                  value: account.id,
                  child: Text(
                    account.bankName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(() {
              _accountId = value;
              _report = null;
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ReportDateTile(
                  label: 'From',
                  date: _startDate,
                  onTap: () => _pickDate(start: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ReportDateTile(
                  label: 'To',
                  date: _endDate,
                  onTap: () => _pickDate(start: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _load,
            icon: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.analytics_outlined),
            label: const Text('Generate report'),
          ),
          if (report != null) ...[
            const SizedBox(height: 20),
            _ReportSummary(report: report),
            const SizedBox(height: 24),
            ReportSectionHeader(
              title: 'Daily totals',
              count: report.daily.length,
              icon: Icons.calendar_view_week_rounded,
            ),
            const SizedBox(height: 8),
            if (report.daily.isEmpty)
              const ReportEmptyState(
                message: 'No transactions found in this date range.',
              )
            else
              ...report.daily.map(
                (day) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(day.date),
                    subtitle: Text(
                      'Income ${_money(day.income)} • Expense ${_money(day.expense)}',
                    ),
                    trailing: Text(
                      _money(day.net),
                      style: TextStyle(
                        color: day.net >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            ReportSectionHeader(
              title: 'Purpose breakdown',
              count: report.purposes.length,
              icon: Icons.donut_large_rounded,
            ),
            const SizedBox(height: 8),
            ...report.purposes.map(
              (purpose) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    purpose.type == 'income'
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: purpose.type == 'income' ? Colors.green : Colors.red,
                  ),
                  title: Text(purpose.purpose),
                  subtitle: Text('${purpose.count} transaction(s)'),
                  trailing: Text(
                    _money(purpose.total),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ReportSectionHeader(
              title: 'Vouchers',
              count: report.transactions.length,
              icon: Icons.receipt_long_rounded,
            ),
            const SizedBox(height: 8),
            ...report.transactions.map(
              (transaction) => _ReportTransaction(
                transaction: transaction,
                onTap: () => showVoucherDetails(
                  context,
                  apiClient: widget.apiClient,
                  token: widget.token,
                  transaction: transaction,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.report});

  final AccountsReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF121C32), Color(0xFF293957)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NET CASH FLOW',
            style: TextStyle(
              color: Color(0xFFC7D1E5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(report.net),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '${report.transactionCount} transactions',
            style: const TextStyle(color: Color(0xFFC7D1E5), fontSize: 12),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Income',
                  value: report.totalIncome,
                  color: const Color(0xFF68D6A6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Expense',
                  value: report.totalExpense,
                  color: const Color(0xFFFF8B82),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFC7D1E5))),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(value),
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTransaction extends StatelessWidget {
  const _ReportTransaction({required this.transaction, required this.onTap});

  final AccountTransactionData transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = transaction.isIncome ? Colors.green : Colors.red;
    final student = transaction.student?.trim();
    final registration = transaction.registrationNo?.trim();
    final feeMonth = transaction.studentFeeMonthLabel?.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          transaction.isIncome
              ? Icons.south_west_rounded
              : Icons.north_east_rounded,
          color: color,
        ),
        title: Text(transaction.purpose ?? transaction.type),
        subtitle: Text(
          [
            if (student?.isNotEmpty == true)
              registration?.isNotEmpty == true
                  ? '$student • $registration'
                  : student!,
            if (feeMonth?.isNotEmpty == true) 'Fee month: $feeMonth',
            if (transaction.voucherNumber?.trim().isNotEmpty == true)
              transaction.voucherNumber!.trim(),
          ].join(' • '),
        ),
        trailing: Text(
          _money(transaction.amount),
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

String _money(double value) => '৳${value.toStringAsFixed(2)}';

String _isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
