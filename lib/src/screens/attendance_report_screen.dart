import 'package:flutter/material.dart';

import '../models/academic.dart';
import '../models/attendance.dart';
import '../services/api_client.dart';
import '../widgets/report_design.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({
    required this.apiClient,
    required this.token,
    required this.years,
    required this.levels,
    super.key,
  });

  final ApiClient apiClient;
  final String token;
  final List<AcademicOption> years;
  final List<AcademicOption> levels;

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  List<AcademicOption> _sections = const [];
  AttendanceReport? _report;
  int? _yearId;
  int? _levelId;
  int? _sectionId;
  String _month = _yearMonth(DateTime.now());
  bool _loadingSections = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _yearId =
        widget.years.where((year) => year.isCurrent).firstOrNull?.id ??
        widget.years.firstOrNull?.id;
    _levelId = widget.levels.firstOrNull?.id;
    _loadSections(_levelId);
  }

  Future<void> _loadSections(int? levelId) async {
    if (levelId == null) return;
    setState(() {
      _loadingSections = true;
      _report = null;
    });
    try {
      final sections = await widget.apiClient.academicSections(
        widget.token,
        levelId: levelId,
      );
      if (!mounted) return;
      setState(() {
        _sections = sections;
        _sectionId = sections.firstOrNull?.id;
      });
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _loadingSections = false);
    }
  }

  Future<void> _pickMonth() async {
    final initial = DateTime.tryParse('$_month-01') ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select any date in the report month',
    );
    if (date != null && mounted) {
      setState(() {
        _month = _yearMonth(date);
        _report = null;
      });
    }
  }

  Future<void> _loadReport() async {
    if (_yearId == null || _levelId == null || _sectionId == null) {
      _message('Select a session, class and section.');
      return;
    }
    setState(() => _loading = true);
    try {
      final report = await widget.apiClient.attendanceReport(
        widget.token,
        yearId: _yearId!,
        levelId: _levelId!,
        sectionId: _sectionId!,
        month: _month,
      );
      if (mounted) setState(() => _report = report);
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showStudent(StudentAttendanceReport student) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .68,
        minChildSize: .45,
        maxChildSize: .9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text(
              student.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text('Roll ${student.rollNo ?? '-'} • ${student.registrationNo}'),
            const SizedBox(height: 16),
            _StudentCounts(student: student),
            const SizedBox(height: 20),
            const Text(
              'Present dates',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _DateWrap(dates: student.presentDates, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Absent dates',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _DateWrap(dates: student.absentDates, color: Colors.red),
          ],
        ),
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
    final report = _report;
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly attendance report')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const ReportPageIntro(
            eyebrow: 'ATTENDANCE ANALYTICS',
            title: 'Monthly attendance',
            subtitle:
                'Compare presence, absence and attendance rates student by student.',
            icon: Icons.fact_check_rounded,
            colors: [Color(0xFF123C39), Color(0xFF0B9B8E)],
          ),
          const SizedBox(height: 24),
          const ReportSectionHeader(
            title: 'Report filters',
            subtitle: 'Choose an academic group and report month.',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 12),
          _ReportOption(
            label: 'Session',
            value: _yearId,
            options: widget.years,
            onChanged: (value) => setState(() {
              _yearId = value;
              _report = null;
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ReportOption(
                  label: 'Class',
                  value: _levelId,
                  options: widget.levels,
                  onChanged: (value) {
                    setState(() {
                      _levelId = value;
                      _sectionId = null;
                    });
                    _loadSections(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _loadingSections
                    ? const Center(child: CircularProgressIndicator())
                    : _ReportOption(
                        label: 'Section',
                        value: _sectionId,
                        options: _sections,
                        onChanged: (value) => setState(() {
                          _sectionId = value;
                          _report = null;
                        }),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ReportDateTile(
            label: 'Report month',
            date: _month,
            onTap: _pickMonth,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _loadReport,
            icon: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bar_chart_rounded),
            label: const Text('Generate report'),
          ),
          if (report != null) ...[
            const SizedBox(height: 20),
            const ReportSectionHeader(
              title: 'Attendance overview',
              subtitle: 'Summary for the selected class and month.',
              icon: Icons.insights_rounded,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ReportMetric(
                    label: 'Days',
                    value: report.attendanceDays.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportMetric(
                    label: 'Students',
                    value: report.studentCount.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportMetric(
                    label: 'Average',
                    value: '${report.averagePercentage.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (report.attendanceDays == 0)
              const ReportEmptyState(
                message: 'No attendance was taken in this month.',
                icon: Icons.event_busy_rounded,
              )
            else ...[
              const SizedBox(height: 20),
              ReportSectionHeader(
                title: 'Student attendance',
                count: report.students.length,
                icon: Icons.groups_rounded,
              ),
              const SizedBox(height: 8),
              ...report.students.map(
                (student) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _showStudent(student),
                    leading: CircleAvatar(
                      child: Text('${student.rollNo ?? '-'}'),
                    ),
                    title: Text(student.name),
                    subtitle: Text(
                      'Present ${student.present} • Absent ${student.absent}',
                    ),
                    trailing: Text(
                      '${student.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: student.percentage >= 75
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReportOption extends StatelessWidget {
  const _ReportOption({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<AcademicOption> options;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: options.any((option) => option.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option.id,
              child: Text(option.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final color = label == 'Average' || label == 'Rate'
        ? const Color(0xFF3D5AF1)
        : label == 'Absent'
        ? const Color(0xFFC04444)
        : const Color(0xFF0B8A72);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF526174),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCounts extends StatelessWidget {
  const _StudentCounts({required this.student});

  final StudentAttendanceReport student;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReportMetric(
            label: 'Present',
            value: student.present.toString(),
          ),
        ),
        Expanded(
          child: _ReportMetric(
            label: 'Absent',
            value: student.absent.toString(),
          ),
        ),
        Expanded(
          child: _ReportMetric(
            label: 'Rate',
            value: '${student.percentage.toStringAsFixed(1)}%',
          ),
        ),
      ],
    );
  }
}

class _DateWrap extends StatelessWidget {
  const _DateWrap({required this.dates, required this.color});

  final List<String> dates;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty) return const Text('None');
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: dates
          .map(
            (date) => Chip(
              backgroundColor: color.withValues(alpha: .1),
              side: BorderSide(color: color.withValues(alpha: .35)),
              label: Text(date),
            ),
          )
          .toList(),
    );
  }
}

String _yearMonth(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}';
