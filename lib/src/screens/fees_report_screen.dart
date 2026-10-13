import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/academic.dart';
import '../models/fees.dart';
import '../services/api_client.dart';
import '../widgets/report_design.dart';
import 'fee_receipt_sheet.dart';
import 'fees_screen.dart';

class FeesReportScreen extends StatefulWidget {
  const FeesReportScreen({
    required this.apiClient,
    required this.token,
    required this.years,
    required this.canCollectFees,
    super.key,
  });

  final ApiClient apiClient;
  final String token;
  final List<AcademicOption> years;
  final bool canCollectFees;

  @override
  State<FeesReportScreen> createState() => _FeesReportScreenState();
}

class _FeesReportScreenState extends State<FeesReportScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<AcademicOption> _levels = const [];
  List<AcademicOption> _sections = const [];
  FeesReport? _report;
  List<FeeDueStudent> _dues = const [];
  String _mode = 'collections';
  int? _yearId;
  int? _levelId;
  int? _sectionId;
  late String _startDate;
  late String _endDate;
  bool _loading = false;
  bool _loadingOptions = true;
  int _paymentLimit = 20;
  bool _loadingMorePayments = false;
  int _duePage = 0;
  int _dueNextOffset = 0;
  bool _dueHasMore = false;
  int _dueTotal = 0;
  double _dueTotalAmount = 0;
  bool _loadingMoreDues = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _yearId =
        widget.years.where((year) => year.isCurrent).firstOrNull?.id ??
        widget.years.firstOrNull?.id;
    _startDate = _isoDate(DateTime(today.year, today.month));
    _endDate = _isoDate(today);
    _loadOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final levels = await widget.apiClient.academicLevels(widget.token);
      if (mounted) setState(() => _levels = levels);
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future<void> _selectLevel(int? value) async {
    setState(() {
      _levelId = value;
      _sectionId = null;
      _sections = const [];
      _clearResults();
    });
    if (value == null || !mounted) return;
    try {
      final sections = await widget.apiClient.academicSections(
        widget.token,
        levelId: value,
      );
      if (mounted) setState(() => _sections = sections);
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  void _clearResults() {
    _report = null;
    _dues = const [];
    _paymentLimit = 20;
    _duePage = 0;
    _dueNextOffset = 0;
    _dueHasMore = false;
    _dueTotal = 0;
    _dueTotalAmount = 0;
  }

  Future<void> _pickDate({required bool start}) async {
    final value = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(start ? _startDate : _endDate) ?? DateTime.now(),
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
      _clearResults();
    });
  }

  Future<void> _load() async {
    if (_yearId == null) {
      _message('Select an academic session.');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_mode == 'collections') {
        final report = await widget.apiClient.feesReport(
          widget.token,
          yearId: _yearId!,
          startDate: _startDate,
          endDate: _endDate,
          levelId: _levelId,
        );
        if (mounted) setState(() => _report = report);
      } else {
        final dues = await widget.apiClient.feeDuesPage(
          widget.token,
          yearId: _yearId!,
          levelId: _levelId,
          sectionId: _sectionId,
          search: _searchController.text.trim(),
          page: 1,
          perPage: 20,
          offset: 0,
        );
        if (mounted) {
          setState(() {
            _dues = dues.items;
            _duePage = dues.page;
            _dueNextOffset = dues.nextOffset;
            _dueHasMore = dues.hasMore;
            _dueTotal = dues.total > 0 ? dues.total : dues.items.length;
            _dueTotalAmount = dues.totalDue;
          });
        }
      }
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('Could not load the fees report. Please retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMoreDues() async {
    if (_loadingMoreDues || !_dueHasMore || _yearId == null) return;
    setState(() => _loadingMoreDues = true);
    try {
      final page = await widget.apiClient.feeDuesPage(
        widget.token,
        yearId: _yearId!,
        levelId: _levelId,
        sectionId: _sectionId,
        search: _searchController.text.trim(),
        page: _duePage + 1,
        perPage: 20,
        offset: _dueNextOffset,
      );
      if (mounted) {
        setState(() {
          _dues = [..._dues, ...page.items];
          _duePage = page.page;
          _dueNextOffset = page.nextOffset;
          _dueHasMore = page.hasMore;
          _dueTotal = _dues.length;
          _dueTotalAmount += page.totalDue;
        });
      }
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('Could not load more students. Please retry.');
    } finally {
      if (mounted) setState(() => _loadingMoreDues = false);
    }
  }

  bool _handleScroll(UserScrollNotification notification) {
    if (notification.direction != ScrollDirection.reverse ||
        notification.metrics.extentAfter > 500) {
      return false;
    }
    if (_mode == 'dues') {
      _loadMoreDues();
    } else if (_report != null &&
        !_loadingMorePayments &&
        _paymentLimit < _report!.payments.length) {
      _loadingMorePayments = true;
      setState(() => _paymentLimit += 20);
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _loadingMorePayments = false);
      });
    }
    return false;
  }

  void _showDueMonths(FeeDueStudent student) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Text(
            student.studentName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            '${student.registrationNo} • ${student.level} ${student.section}',
          ),
          const SizedBox(height: 12),
          ...student.months.map(
            (month) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(month.month),
              trailing: Text(
                _money(month.due),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Total due',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            trailing: Text(
              _money(student.totalDue),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fees reports')),
      body: NotificationListener<UserScrollNotification>(
        onNotification: _handleScroll,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            ReportPageIntro(
              eyebrow: 'FEES ANALYTICS',
              title: _mode == 'collections'
                  ? 'Collection insights'
                  : 'Outstanding dues',
              subtitle: _mode == 'collections'
                  ? 'Track collections, fee purposes and payment receipts.'
                  : 'Find students with unpaid fees and review due months.',
              icon: _mode == 'collections'
                  ? Icons.payments_rounded
                  : Icons.pending_actions_rounded,
              colors: const [Color(0xFF4A2A0A), Color(0xFFC57A18)],
            ),
            const SizedBox(height: 22),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'collections',
                  label: Text('Collections'),
                  icon: Icon(Icons.payments_outlined),
                ),
                ButtonSegment(
                  value: 'dues',
                  label: Text('Due list'),
                  icon: Icon(Icons.pending_actions_outlined),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (value) => setState(() {
                _mode = value.first;
                _clearResults();
              }),
            ),
            const SizedBox(height: 22),
            const ReportSectionHeader(
              title: 'Report filters',
              subtitle: 'Narrow results by academic information and period.',
              icon: Icons.tune_rounded,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _yearId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Academic session'),
              items: widget.years
                  .map(
                    (year) => DropdownMenuItem(
                      value: year.id,
                      child: Text(year.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _yearId = value;
                _clearResults();
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _levelId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ..._levels.map(
                        (level) => DropdownMenuItem<int?>(
                          value: level.id,
                          child: Text(level.name),
                        ),
                      ),
                    ],
                    onChanged: _loadingOptions ? null : _selectLevel,
                  ),
                ),
                if (_mode == 'dues') ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _sectionId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Section'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All'),
                        ),
                        ..._sections.map(
                          (section) => DropdownMenuItem<int?>(
                            value: section.id,
                            child: Text(section.name),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        _sectionId = value;
                        _clearResults();
                      }),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (_mode == 'collections')
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
              )
            else
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _load(),
                decoration: const InputDecoration(
                  labelText: 'Name, class, section, roll or registration',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
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
              label: Text(
                _mode == 'collections' ? 'Generate report' : 'Load dues',
              ),
            ),
            if (_mode == 'collections' && _report != null)
              _CollectionReportView(
                report: _report!,
                paymentLimit: _paymentLimit,
                onPayment: (payment) => showFeeReceipt(
                  context,
                  apiClient: widget.apiClient,
                  token: widget.token,
                  paymentId: payment.id,
                ),
              ),
            if (_mode == 'dues' && !_loading) ...[
              const SizedBox(height: 20),
              Card(
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    title: const Text('Outstanding dues'),
                    subtitle: Text(
                      '$_dueTotal student(s) • ${_dues.length} loaded',
                    ),
                    trailing: Text(
                      _money(_dueTotalAmount),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_dues.isEmpty)
                const ReportEmptyState(
                  message: 'No outstanding dues found.',
                  icon: Icons.task_alt_rounded,
                )
              else
                ..._dues.map(
                  (student) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        onTap: () => _showDueMonths(student),
                        title: Text(student.studentName),
                        subtitle: Text(
                          '${student.registrationNo} • Roll ${student.rollNo ?? '-'}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _money(student.totalDue),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (widget.canCollectFees)
                              TextButton.icon(
                                onPressed: () async {
                                  await showStudentFeeCollection(
                                    context: context,
                                    apiClient: widget.apiClient,
                                    token: widget.token,
                                    studentId: student.studentId,
                                    yearId: _yearId!,
                                    canCollectFees: widget.canCollectFees,
                                  );
                                  if (mounted) await _load();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 28),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(
                                  Icons.add_card_rounded,
                                  size: 15,
                                ),
                                label: const Text('Collect'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (_dueHasMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'Scroll down to load more students…',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollectionReportView extends StatelessWidget {
  const _CollectionReportView({
    required this.report,
    required this.paymentLimit,
    required this.onPayment,
  });

  final FeesReport report;
  final int paymentLimit;
  final ValueChanged<FeePaymentData> onPayment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A5548), Color(0xFF0B9B8E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL COLLECTED',
                style: TextStyle(
                  color: Color(0xFFC9EEE8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _money(report.totalCollected),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${report.paymentCount} payments • ${report.studentCount} students',
                style: const TextStyle(color: Color(0xFFC9EEE8), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ReportSectionHeader(
          title: 'Daily collections',
          count: report.daily.length,
          icon: Icons.calendar_view_week_rounded,
        ),
        const SizedBox(height: 8),
        ...report.daily.map(
          (day) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(day.date),
            trailing: Text(_money(day.amount)),
          ),
        ),
        const SizedBox(height: 18),
        ReportSectionHeader(
          title: 'Fee purpose breakdown',
          count: report.purposes.length,
          icon: Icons.donut_large_rounded,
        ),
        const SizedBox(height: 8),
        ...report.purposes.map(
          (purpose) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(purpose.purpose),
            trailing: Text(_money(purpose.amount)),
          ),
        ),
        const SizedBox(height: 18),
        ReportSectionHeader(
          title: 'Payment receipts',
          count: report.payments.length,
          icon: Icons.receipt_long_rounded,
        ),
        const SizedBox(height: 8),
        ...report.payments
            .take(paymentLimit)
            .map(
              (payment) => Card(
                child: ListTile(
                  onTap: () => onPayment(payment),
                  title: Text(payment.studentName),
                  subtitle: Text(
                    '${payment.registrationNo} • ${payment.month}',
                  ),
                  trailing: Text(
                    _money(payment.amount),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
        if (paymentLimit < report.payments.length)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'Scroll down to load more receipts…',
                style: TextStyle(color: Color(0xFF667085), fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

String _money(double value) => '৳${value.toStringAsFixed(2)}';

String _isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
