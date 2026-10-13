import 'package:flutter/material.dart';

import '../models/academic.dart';
import '../services/api_client.dart';
import '../widgets/form_design.dart';

class StudentPromotionScreen extends StatefulWidget {
  const StudentPromotionScreen({
    required this.apiClient,
    required this.token,
    required this.student,
    required this.years,
    required this.levels,
    super.key,
  });

  final ApiClient apiClient;
  final String token;
  final StudentDetails student;
  final List<AcademicOption> years;
  final List<AcademicOption> levels;

  @override
  State<StudentPromotionScreen> createState() => _StudentPromotionScreenState();
}

class _StudentPromotionScreenState extends State<StudentPromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rollController = TextEditingController();
  final _remarksController = TextEditingController();
  List<AcademicOption> _sections = const [];
  int? _sourceCycleId;
  int? _yearId;
  int? _levelId;
  int? _sectionId;
  bool _loadingSections = false;
  bool _saving = false;

  StudentCycle? get _sourceCycle => widget.student.cycles
      .where((cycle) => cycle.id == _sourceCycleId)
      .firstOrNull;

  List<AcademicOption> get _targetYears {
    final sourceYearId = _sourceCycle?.yearId;
    return widget.years.where((year) => year.id != sourceYearId).toList();
  }

  @override
  void initState() {
    super.initState();
    final source = widget.student.cycles.firstOrNull;
    _sourceCycleId = source?.id;
    _setTargetDefaults(source);
  }

  @override
  void dispose() {
    _rollController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _setTargetDefaults(StudentCycle? source) {
    final targetYears = widget.years
        .where((year) => year.id != source?.yearId)
        .toList();
    _yearId =
        targetYears.where((year) => year.isCurrent).firstOrNull?.id ??
        targetYears.firstOrNull?.id;
    final sourceIndex = widget.levels.indexWhere(
      (level) => level.id == source?.levelId,
    );
    _levelId = sourceIndex >= 0 && sourceIndex + 1 < widget.levels.length
        ? widget.levels[sourceIndex + 1].id
        : widget.levels.firstOrNull?.id;
    _sectionId = null;
    _rollController.text = source?.rollNo?.toString() ?? '';
    if (_levelId != null) _loadSections(_levelId!);
  }

  Future<void> _loadSections(int levelId) async {
    setState(() => _loadingSections = true);
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final source = _sourceCycle;
    if (source == null ||
        _yearId == null ||
        _levelId == null ||
        _sectionId == null) {
      _message('Select source and target academic information.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm promotion'),
        content: Text(
          'Promote ${widget.student.name} to the selected session, class and section?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Promote'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await widget.apiClient.promoteStudent(
        widget.token,
        studentId: widget.student.id,
        studentCycleId: source.id,
        yearId: _yearId!,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Promote student')),
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
              title: 'Source academic record',
              subtitle: 'Select the enrollment to promote from.',
              icon: Icons.history_edu_rounded,
            ),
            DropdownButtonFormField<int>(
              initialValue: _sourceCycleId,
              decoration: const InputDecoration(labelText: 'Source record *'),
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
                _setTargetDefaults(_sourceCycle);
              },
            ),
            const SizedBox(height: 18),
            const FormSectionLabel(
              title: 'Target academic record',
              subtitle: 'Choose the next session, class, section and roll.',
              icon: Icons.trending_up_rounded,
            ),
            DropdownButtonFormField<int>(
              key: ValueKey('year-$_sourceCycleId-$_yearId'),
              initialValue: _yearId,
              decoration: const InputDecoration(labelText: 'Target session *'),
              items: _targetYears
                  .map(
                    (year) => DropdownMenuItem(
                      value: year.id,
                      child: Text(year.name),
                    ),
                  )
                  .toList(),
              validator: (value) =>
                  value == null ? 'Select a target session.' : null,
              onChanged: (value) => setState(() => _yearId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey('level-$_sourceCycleId-$_levelId'),
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
                key: ValueKey('section-$_levelId-$_sectionId'),
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
              decoration: const InputDecoration(labelText: 'New roll number *'),
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
                labelText: 'Remarks (optional)',
                hintText: 'Optional promotion note',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving || _targetYears.isEmpty ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.trending_up_rounded),
              label: const Text('Promote student'),
            ),
            if (_targetYears.isEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Create another academic session before promoting this student.',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
