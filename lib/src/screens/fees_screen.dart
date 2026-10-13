import 'package:flutter/material.dart';

import '../models/accounts.dart';
import '../models/academic.dart';
import '../models/fees.dart';
import '../services/api_client.dart';
import '../widgets/form_design.dart';
import 'fee_receipt_sheet.dart';
import 'fees_report_screen.dart';
import 'fees_management_screen.dart';

Future<void> showStudentFeeCollection({
  required BuildContext context,
  required ApiClient apiClient,
  required String token,
  required int studentId,
  required int yearId,
  required bool canCollectFees,
  VoidCallback? onCollected,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final accounts = await apiClient.accounts(token);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .82,
      minChildSize: .55,
      maxChildSize: .94,
      builder: (context, controller) => _StudentFeeCollectionBody(
        apiClient: apiClient,
        token: token,
        studentId: studentId,
        yearId: yearId,
        accounts: accounts,
        controller: controller,
        canCollectFees: canCollectFees,
        onCollected: onCollected,
        messenger: messenger,
      ),
    ),
  );
}

class _StudentFeeCollectionBody extends StatefulWidget {
  const _StudentFeeCollectionBody({
    required this.apiClient,
    required this.token,
    required this.studentId,
    required this.yearId,
    required this.accounts,
    required this.controller,
    required this.canCollectFees,
    this.onCollected,
    required this.messenger,
  });

  final ApiClient apiClient;
  final String token;
  final int studentId;
  final int yearId;
  final List<AccountData> accounts;
  final ScrollController controller;
  final bool canCollectFees;
  final VoidCallback? onCollected;
  final ScaffoldMessengerState messenger;

  @override
  State<_StudentFeeCollectionBody> createState() =>
      _StudentFeeCollectionBodyState();
}

class _StudentFeeCollectionBodyState extends State<_StudentFeeCollectionBody> {
  late Future<StudentFeeStatus> _future;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<StudentFeeStatus> _load() => widget.apiClient.studentFeeStatus(
    widget.token,
    widget.studentId,
    yearId: widget.yearId,
  );

  Future<void> _collect(
    StudentFeeStatus student,
    MonthlyFeeStatus month,
  ) async {
    final input = await showAppFormSheet<_FeeCollectionInput>(
      context: context,
      builder: (context) => _FeeCollectionDialog(
        student: student,
        month: month,
        accounts: widget.accounts,
      ),
    );
    if (input == null || !mounted) return;
    try {
      await widget.apiClient.collectFee(
        widget.token,
        studentId: student.studentId,
        yearId: widget.yearId,
        month: month.monthKey,
        accountId: input.accountId,
        amount: input.amount,
        paymentMethod: input.method,
        note: input.note,
      );
      if (!mounted) return;
      setState(() {
        _future = _load();
        _feedback =
            'Fee collected successfully. The schedule has been updated.';
      });
      widget.onCollected?.call();
      widget.messenger.hideCurrentSnackBar();
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('Fee collected successfully.')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<StudentFeeStatus>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text(snapshot.error.toString()));
      }
      return Column(
        children: [
          if (_feedback != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7EF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFB9E5CC)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF087A61),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _feedback!,
                      style: const TextStyle(
                        color: Color(0xFF075E4B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _StudentFeeSheet(
              data: snapshot.requireData,
              controller: widget.controller,
              canCollectFees:
                  widget.canCollectFees && widget.accounts.isNotEmpty,
              onCollect: _collect,
            ),
          ),
        ],
      );
    },
  );
}

class FeesScreen extends StatefulWidget {
  const FeesScreen({
    required this.apiClient,
    required this.token,
    required this.canCollectFees,
    required this.canCreatePurpose,
    required this.canEditPurpose,
    required this.canDeletePurpose,
    required this.canCreateTemplate,
    required this.canEditTemplate,
    required this.canDeleteTemplate,
    super.key,
  });

  final ApiClient apiClient;
  final String token;
  final bool canCollectFees;
  final bool canCreatePurpose, canEditPurpose, canDeletePurpose;
  final bool canCreateTemplate, canEditTemplate, canDeleteTemplate;

  bool get canManage =>
      canCreatePurpose ||
      canEditPurpose ||
      canDeletePurpose ||
      canCreateTemplate ||
      canEditTemplate ||
      canDeleteTemplate;

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  final _studentSearchController = TextEditingController();
  FeesSummary? _summary;
  List<AcademicOption> _years = const [];
  List<FeePaymentData> _payments = const [];
  List<StudentSummary> _studentResults = const [];
  List<AccountData> _accounts = const [];
  int? _yearId;
  bool _loading = true;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _studentSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final years = await widget.apiClient.academicYears(widget.token);
      final selectedYear =
          years.where((year) => year.isCurrent).firstOrNull ??
          (years.isEmpty ? null : years.first);
      if (!mounted) return;
      _years = years;
      _yearId = selectedYear?.id;
      await _loadFees();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load fees data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFees() async {
    final results = await Future.wait<dynamic>([
      widget.apiClient.feesSummary(widget.token, yearId: _yearId),
      widget.apiClient.feePayments(widget.token, yearId: _yearId),
      widget.apiClient.accounts(widget.token),
    ]);
    if (!mounted) return;
    setState(() {
      _summary = results[0] as FeesSummary;
      _payments = results[1] as List<FeePaymentData>;
      _accounts = results[2] as List<AccountData>;
    });
  }

  Future<void> _changeYear(int? yearId) async {
    if (yearId == null) return;
    setState(() {
      _yearId = yearId;
      _loading = true;
      _studentResults = const [];
    });
    try {
      await _loadFees();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchStudents() async {
    final search = _studentSearchController.text.trim();
    if (search.isEmpty) {
      setState(() => _studentResults = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final students = await widget.apiClient.academicStudents(
        widget.token,
        yearId: _yearId,
        search: search,
      );
      if (mounted) setState(() => _studentResults = students);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _summary == null) {
      return _FeesError(message: _error!, onRetry: _loadInitial);
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _FeeSummaryCards(summary: _summary!),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCECE7)),
            ),
            child: DropdownButtonFormField<int>(
              initialValue: _yearId,
              decoration: const InputDecoration(
                labelText: 'Academic session',
                prefixIcon: Icon(Icons.calendar_month_outlined),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              items: _years
                  .map(
                    (year) => DropdownMenuItem<int>(
                      value: year.id,
                      child: Text(year.name),
                    ),
                  )
                  .toList(),
              onChanged: _loading ? null : _changeYear,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.canManage)
                Expanded(
                  child: _FeeActionTile(
                    title: 'Fee setup',
                    icon: Icons.tune_rounded,
                    onTap: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => FeesManagementScreen(
                            apiClient: widget.apiClient,
                            token: widget.token,
                            years: _years,
                            canCreatePurpose: widget.canCreatePurpose,
                            canEditPurpose: widget.canEditPurpose,
                            canDeletePurpose: widget.canDeletePurpose,
                            canCreateTemplate: widget.canCreateTemplate,
                            canEditTemplate: widget.canEditTemplate,
                            canDeleteTemplate: widget.canDeleteTemplate,
                          ),
                        ),
                      );
                      if (changed == true && mounted) await _loadInitial();
                    },
                  ),
                ),
              if (widget.canManage) const SizedBox(width: 10),
              Expanded(
                child: _FeeActionTile(
                  title: 'Reports',
                  icon: Icons.query_stats_rounded,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (context) => FeesReportScreen(
                        apiClient: widget.apiClient,
                        token: widget.token,
                        years: _years,
                        canCollectFees: widget.canCollectFees,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'Find student dues',
            count: _studentResults.length,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FAF6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCDEBDF)),
            ),
            child: TextField(
              controller: _studentSearchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchStudents(),
              decoration: InputDecoration(
                hintText: 'Name, class, section, roll or registration',
                prefixIcon: const Icon(Icons.person_search_rounded),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        onPressed: _searchStudents,
                        icon: const Icon(Icons.search_rounded),
                      ),
              ),
            ),
          ),
          if (_studentResults.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._studentResults.map(
              (student) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.school_outlined),
                  ),
                  title: Text(student.name),
                  subtitle: Text(
                    '${student.registrationNo} • ${student.levelName} ${student.sectionName}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showStudentFees(student.id),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _SectionTitle(title: 'Recent payments', count: _payments.length),
          const SizedBox(height: 10),
          if (_payments.isEmpty)
            const Text('No payments recorded for this session.')
          else
            ..._payments.map(
              (payment) => _PaymentCard(
                payment: payment,
                onTap: () => showFeeReceipt(
                  context,
                  apiClient: widget.apiClient,
                  token: widget.token,
                  paymentId: payment.id,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showStudentFees(int studentId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .82,
        minChildSize: .55,
        maxChildSize: .94,
        builder: (context, controller) => FutureBuilder<StudentFeeStatus>(
          future: widget.apiClient.studentFeeStatus(
            widget.token,
            studentId,
            yearId: _yearId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            return _StudentFeeSheet(
              data: snapshot.requireData,
              controller: controller,
              canCollectFees: widget.canCollectFees,
              onCollect: _collectFee,
            );
          },
        ),
      ),
    );
  }

  Future<void> _collectFee(
    StudentFeeStatus student,
    MonthlyFeeStatus month,
  ) async {
    if (_yearId == null || _accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No account is available for collection.'),
        ),
      );
      return;
    }
    final input = await showAppFormSheet<_FeeCollectionInput>(
      context: context,
      builder: (context) => _FeeCollectionDialog(
        student: student,
        month: month,
        accounts: _accounts,
      ),
    );
    if (input == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm fee collection'),
        content: Text(
          'Collect ${_money(input.amount)} for ${student.studentName} (${month.month})?',
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
      await widget.apiClient.collectFee(
        widget.token,
        studentId: student.studentId,
        yearId: _yearId!,
        month: month.monthKey,
        accountId: input.accountId,
        amount: input.amount,
        paymentMethod: input.method,
        note: input.note,
      );
      if (!mounted) return;
      await _loadFees();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fee collected successfully.')),
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
}

class _FeeSummaryCards extends StatelessWidget {
  const _FeeSummaryCards({required this.summary});

  final FeesSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF063F3B), Color(0xFF078467)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24065F50),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -18,
            child: Icon(
              Icons.payments_rounded,
              size: 116,
              color: Colors.white.withValues(alpha: .06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF79E7BD),
                    size: 18,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'COLLECTION OVERVIEW',
                    style: TextStyle(
                      color: Color(0xFFD9F7EC),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'Total collected',
                style: TextStyle(color: Color(0xFFD9F7EC), fontSize: 13),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _money(summary.totalCollected),
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
                    child: _SmallMetric(
                      label: 'This month',
                      value: _money(summary.thisMonthCollected),
                    ),
                  ),
                  Container(width: 1, height: 38, color: Colors.white24),
                  Expanded(
                    child: _SmallMetric(
                      label: 'Payments',
                      value: summary.paymentCount.toString(),
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

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFD9F7EC), fontSize: 12),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
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

class _FeeActionTile extends StatelessWidget {
  const _FeeActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDCECE7)),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F5EE),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: const Color(0xFF087A61), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Color(0xFF7A8D87),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, this.onTap});

  final FeePaymentData payment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE2EAE7)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE3F5EE),
          foregroundColor: Color(0xFF087A61),
          child: Icon(Icons.payments_outlined),
        ),
        title: Text(payment.studentName),
        subtitle: Text(
          '${payment.registrationNo} • ${payment.month} • ${payment.status}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _money(payment.amount),
              style: const TextStyle(
                color: Color(0xFF087A61),
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Received',
              style: TextStyle(fontSize: 11, color: Color(0xFF526B63)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentFeeSheet extends StatelessWidget {
  const _StudentFeeSheet({
    required this.data,
    required this.controller,
    required this.canCollectFees,
    required this.onCollect,
  });

  final StudentFeeStatus data;
  final ScrollController controller;
  final bool canCollectFees;
  final Future<void> Function(StudentFeeStatus, MonthlyFeeStatus) onCollect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
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
                child: Icon(Icons.school_rounded, color: Color(0xFFB9F4D9)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.studentName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.registrationNo} • ${data.academicLabel}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD9F7EC),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AmountBox(label: 'Expected', amount: data.totalExpected),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AmountBox(label: 'Paid', amount: data.totalPaid),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AmountBox(label: 'Due', amount: data.totalDue),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF087A61)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Monthly fee schedule',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${data.months.length} months',
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...data.months.map(
          (month) => _FeeMonthCard(
            month: month,
            canCollectFees: canCollectFees,
            onCollect: () => onCollect(data, month),
          ),
        ),
      ],
    );
  }
}

class _FeeMonthCard extends StatelessWidget {
  const _FeeMonthCard({
    required this.month,
    required this.canCollectFees,
    required this.onCollect,
  });

  final MonthlyFeeStatus month;
  final bool canCollectFees;
  final Future<void> Function() onCollect;

  @override
  Widget build(BuildContext context) {
    final isDue = month.due > 0;
    final color = month.status == 'paid'
        ? const Color(0xFF087A61)
        : isDue
        ? const Color(0xFFC04444)
        : const Color(0xFF667085);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            month.status == 'paid'
                ? Icons.check_circle_outline_rounded
                : Icons.calendar_today_rounded,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          month.month,
          style: const TextStyle(
            color: Color(0xFF172033),
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          'Paid ${_money(month.paid)}  •  Due ${_money(month.due)}',
          style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
        ),
        trailing: _StatusBadge(status: month.status),
        onTap: canCollectFees && isDue ? () => onCollect() : null,
      ),
    );
  }
}

class _FeeCollectionInput {
  const _FeeCollectionInput({
    required this.accountId,
    required this.amount,
    required this.method,
    required this.note,
  });

  final int accountId;
  final double amount;
  final String method;
  final String note;
}

class _FeeCollectionDialog extends StatefulWidget {
  const _FeeCollectionDialog({
    required this.student,
    required this.month,
    required this.accounts,
  });

  final StudentFeeStatus student;
  final MonthlyFeeStatus month;
  final List<AccountData> accounts;

  @override
  State<_FeeCollectionDialog> createState() => _FeeCollectionDialogState();
}

class _FeeCollectionDialogState extends State<_FeeCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _noteController = TextEditingController();
  late int _accountId;
  String _method = 'cash';

  @override
  void initState() {
    super.initState();
    _accountId = widget.accounts.first.id;
    _amountController = TextEditingController(
      text: widget.month.due.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: FormDialogHeader(
        title: '${widget.month.month} fee',
        subtitle: 'Collect payment for ${widget.student.studentName}.',
        icon: Icons.payments_rounded,
        color: const Color(0xFF168A65),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormSectionLabel(
                title: 'Due ${_money(widget.month.due)}',
                subtitle: 'Select the receiving account and payment method.',
                icon: Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _accountId,
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
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount *'),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount.';
                  }
                  if (amount > widget.month.due) {
                    return 'Amount exceeds the due.';
                  }
                  return null;
                },
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
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
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
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _FeeCollectionInput(
                accountId: _accountId,
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

class _AmountBox extends StatelessWidget {
  const _AmountBox({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text(
            _money(amount),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'paid' => Colors.green,
      'partial' => Colors.orange,
      _ => Colors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

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

class _FeesError extends StatelessWidget {
  const _FeesError({required this.message, required this.onRetry});

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
