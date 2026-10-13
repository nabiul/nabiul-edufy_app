import 'package:flutter/material.dart';

import '../models/academic.dart';
import '../models/attendance.dart';
import '../services/api_client.dart';
import '../widgets/form_design.dart';
import 'attendance_report_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
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
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AcademicOption> _sections = const [];
  AttendanceRegister? _register;
  Set<int> _presentIds = {};
  Map<int, String> _remarks = {};
  int? _yearId;
  int? _levelId;
  int? _sectionId;
  String _date = _isoDate(DateTime.now());
  bool _loadingSections = false;
  bool _loading = false;
  bool _saving = false;

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
      _register = null;
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

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) {
      setState(() {
        _date = _isoDate(selected);
        _register = null;
      });
    }
  }

  Future<void> _loadRegister() async {
    if (_yearId == null || _levelId == null || _sectionId == null) {
      _message('Select a session, class and section.');
      return;
    }
    setState(() => _loading = true);
    try {
      final register = await widget.apiClient.attendance(
        widget.token,
        yearId: _yearId!,
        levelId: _levelId!,
        sectionId: _sectionId!,
        date: _date,
      );
      if (!mounted) return;
      setState(() {
        _register = register;
        _presentIds = register.students
            .where((student) => student.present)
            .map((student) => student.id)
            .toSet();
        _remarks = {
          for (final student in register.students)
            if (student.remark?.isNotEmpty == true) student.id: student.remark!,
        };
      });
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editRemark(AttendanceStudent student) async {
    final value = await showAppFormSheet<String>(
      context: context,
      builder: (context) => _RemarkDialog(
        studentName: student.name,
        initialValue: _remarks[student.id] ?? '',
      ),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (value.isEmpty) {
        _remarks.remove(student.id);
      } else {
        _remarks[student.id] = value;
      }
    });
  }

  Future<void> _save() async {
    final register = _register;
    if (register == null ||
        _yearId == null ||
        _levelId == null ||
        _sectionId == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm attendance'),
        content: Text(
          'Save ${_presentIds.length} present and ${register.total - _presentIds.length} absent for $_date?',
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

    setState(() => _saving = true);
    try {
      final updated = await widget.apiClient.saveAttendance(
        widget.token,
        yearId: _yearId!,
        levelId: _levelId!,
        sectionId: _sectionId!,
        date: _date,
        presentStudentIds: _presentIds,
        remarks: _remarks,
      );
      if (!mounted) return;
      setState(() => _register = updated);
      _message('Attendance saved successfully.');
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final register = _register;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student attendance'),
        actions: [
          IconButton(
            tooltip: 'Monthly report',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) => AttendanceReportScreen(
                  apiClient: widget.apiClient,
                  token: widget.token,
                  years: widget.years,
                  levels: widget.levels,
                ),
              ),
            ),
            icon: const Icon(Icons.bar_chart_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _AttendanceOption(
            label: 'Session',
            value: _yearId,
            options: widget.years,
            onChanged: (value) => setState(() {
              _yearId = value;
              _register = null;
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AttendanceOption(
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
                    : _AttendanceOption(
                        label: 'Section',
                        value: _sectionId,
                        options: _sections,
                        onChanged: (value) => setState(() {
                          _sectionId = value;
                          _register = null;
                        }),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Attendance date'),
            subtitle: Text(_date),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _loadRegister,
            icon: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded),
            label: const Text('Load students'),
          ),
          if (register != null) ...[
            const SizedBox(height: 20),
            _AttendanceSummary(
              total: register.total,
              present: _presentIds.length,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(
                    () => _presentIds = register.students
                        .map((student) => student.id)
                        .toSet(),
                  ),
                  child: const Text('Mark all present'),
                ),
                TextButton(
                  onPressed: () => setState(() => _presentIds.clear()),
                  child: const Text('Clear all'),
                ),
              ],
            ),
            if (register.students.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No students found in this class.')),
              )
            else
              ...register.students.map(
                (student) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Checkbox(
                      value: _presentIds.contains(student.id),
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          _presentIds.add(student.id);
                        } else {
                          _presentIds.remove(student.id);
                        }
                      }),
                    ),
                    title: Text(student.name),
                    subtitle: Text(
                      'Roll ${student.rollNo ?? '-'} • ${student.registrationNo}'
                      '${_remarks[student.id]?.isNotEmpty == true ? '\n${_remarks[student.id]}' : ''}',
                    ),
                    isThreeLine: _remarks[student.id]?.isNotEmpty == true,
                    trailing: IconButton(
                      tooltip: 'Add remark',
                      onPressed: () => _editRemark(student),
                      icon: const Icon(Icons.note_alt_outlined),
                    ),
                    onTap: () => setState(() {
                      if (_presentIds.contains(student.id)) {
                        _presentIds.remove(student.id);
                      } else {
                        _presentIds.add(student.id);
                      }
                    }),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving || register.students.isEmpty ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save attendance'),
            ),
          ],
        ],
      ),
    );
  }
}

class _RemarkDialog extends StatefulWidget {
  const _RemarkDialog({required this.studentName, required this.initialValue});

  final String studentName;
  final String initialValue;

  @override
  State<_RemarkDialog> createState() => _RemarkDialogState();
}

class _RemarkDialogState extends State<_RemarkDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormSheet(
    title: FormDialogHeader(
      title: 'Attendance remark',
      subtitle: 'Add a short note for ${widget.studentName}.',
      icon: Icons.edit_note_rounded,
      color: const Color(0xFF7B5DB5),
    ),
    content: TextField(
      controller: _controller,
      maxLength: 255,
      autofocus: true,
      decoration: const InputDecoration(
        labelText: 'Remark (optional)',
        hintText: 'Optional remark',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: const Text('Save'),
      ),
    ],
  );
}

class _AttendanceOption extends StatelessWidget {
  const _AttendanceOption({
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

class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary({required this.total, required this.present});

  final int total;
  final int present;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CountCard(label: 'Total', count: total),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CountCard(label: 'Present', count: present),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CountCard(label: 'Absent', count: total - present),
        ),
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

String _isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
