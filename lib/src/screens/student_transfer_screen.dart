import 'package:flutter/material.dart';

import '../models/academic.dart';
import '../services/api_client.dart';
import '../widgets/form_design.dart';

class StudentTransferScreen extends StatefulWidget {
  const StudentTransferScreen({
    required this.apiClient,
    required this.token,
    required this.student,
    required this.levels,
    super.key,
  });

  final ApiClient apiClient;
  final String token;
  final StudentDetails student;
  final List<AcademicOption> levels;

  @override
  State<StudentTransferScreen> createState() => _StudentTransferScreenState();
}

class _StudentTransferScreenState extends State<StudentTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rollController = TextEditingController();
  final _remarksController = TextEditingController();
  List<AcademicOption> _sections = const [];
  int? _sourceCycleId;
  int? _levelId;
  int? _sectionId;
  bool _loadingSections = false;
  bool _saving = false;

  StudentCycle? get _sourceCycle => widget.student.cycles
      .where((cycle) => cycle.id == _sourceCycleId)
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    final source = widget.student.cycles.firstOrNull;
    _sourceCycleId = source?.id;
    _setSource(source);
  }

  @override
  void dispose() {
    _rollController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _setSource(StudentCycle? source) {
    _levelId = source?.levelId ?? widget.levels.firstOrNull?.id;
    _rollController.text = source?.rollNo?.toString() ?? '';
    if (_levelId != null) {
      _loadSections(_levelId!, preferredSectionId: source?.sectionId);
    }
  }

  Future<void> _loadSections(int levelId, {int? preferredSectionId}) async {
    setState(() => _loadingSections = true);
    try {
      final sections = await widget.apiClient.academicSections(
        widget.token,
        levelId: levelId,
      );
      if (!mounted) return;
      setState(() {
        _sections = sections;
        _sectionId = sections.any((section) => section.id == preferredSectionId)
            ? preferredSectionId
            : sections.firstOrNull?.id;
      });
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _loadingSections = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final source = _sourceCycle;
    if (source == null || _levelId == null || _sectionId == null) {
      _message('Select source record, class and section.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm transfer'),
        content: Text(
          'Transfer ${widget.student.name} within ${source.year}? This change will be saved in transfer history.',
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

    setState(() => _saving = true);
    try {
      await widget.apiClient.transferStudent(
        widget.token,
        studentId: widget.student.id,
        studentCycleId: source.id,
        levelId: _levelId!,
        sectionId: _sectionId!,
        rollNo: int.parse(_rollController.text),
        remarks: _remarksController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
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
    final source = _sourceCycle;
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer student')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: FormRequiredHint(),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(widget.student.name),
                subtitle: Text(widget.student.registrationNo),
              ),
            ),
            const SizedBox(height: 16),
            const FormSectionLabel(
              title: 'Current academic record',
              subtitle: 'Choose the enrollment that will be transferred.',
              icon: Icons.history_edu_rounded,
            ),
            DropdownButtonFormField<int>(
              initialValue: _sourceCycleId,
              decoration: const InputDecoration(labelText: 'Academic record *'),
              items: widget.student.cycles
                  .map(
                    (cycle) => DropdownMenuItem(
                      value: cycle.id,
                      child: Text(
                        '${cycle.year} • ${cycle.level} • ${cycle.section}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _sourceCycleId = value);
                _setSource(_sourceCycle);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text('Session'),
              subtitle: Text(source?.year ?? '-'),
              leading: const Icon(Icons.calendar_month_outlined),
            ),
            const SizedBox(height: 12),
            const FormSectionLabel(
              title: 'Transfer destination',
              subtitle: 'Set the target class, section and roll number.',
              icon: Icons.move_up_rounded,
            ),
            DropdownButtonFormField<int>(
              key: ValueKey('transfer-level-$_sourceCycleId-$_levelId'),
              initialValue: _levelId,
              decoration: const InputDecoration(labelText: 'Target class *'),
              items: widget.levels
                  .map(
                    (level) => DropdownMenuItem(
                      value: level.id,
                      child: Text(level.name),
                    ),
                  )
                  .toList(),
              validator: (value) => value == null ? 'Select a class.' : null,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _levelId = value;
                  _sectionId = null;
                });
                _loadSections(value);
              },
            ),
            const SizedBox(height: 12),
            if (_loadingSections)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<int>(
                key: ValueKey('transfer-section-$_levelId-$_sectionId'),
                initialValue: _sectionId,
                decoration: const InputDecoration(
                  labelText: 'Target section *',
                ),
                items: _sections
                    .map(
                      (section) => DropdownMenuItem(
                        value: section.id,
                        child: Text(section.name),
                      ),
                    )
                    .toList(),
                validator: (value) =>
                    value == null ? 'Select a section.' : null,
                onChanged: (value) => setState(() => _sectionId = value),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rollController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target roll number *',
              ),
              validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                  ? 'Enter a valid roll number.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Transfer reason (optional)',
                hintText: 'Optional note',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz_rounded),
              label: const Text('Transfer student'),
            ),
          ],
        ),
      ),
    );
  }
}
