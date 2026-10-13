import 'package:flutter/material.dart';

import '../models/academic.dart';
import '../services/api_client.dart';
import '../widgets/form_design.dart';

class AcademicSetupScreen extends StatefulWidget {
  const AcademicSetupScreen({
    required this.apiClient,
    required this.token,
    required this.canManageSessions,
    required this.canCreateClass,
    required this.canEditClass,
    required this.canCreateSection,
    required this.canEditSection,
    super.key,
  });

  final ApiClient apiClient;
  final String token;
  final bool canManageSessions;
  final bool canCreateClass;
  final bool canEditClass;
  final bool canCreateSection;
  final bool canEditSection;

  @override
  State<AcademicSetupScreen> createState() => _AcademicSetupScreenState();
}

class _AcademicSetupScreenState extends State<AcademicSetupScreen> {
  List<AcademicOption> _years = const [];
  List<AcademicOption> _levels = const [];
  List<AcademicOption> _sections = const [];
  bool _loading = true;
  bool _changed = false;
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
        widget.apiClient.academicYears(widget.token),
        widget.apiClient.academicLevels(widget.token),
        widget.apiClient.academicSections(widget.token),
      ]);
      if (!mounted) return;
      setState(() {
        _years = results[0] as List<AcademicOption>;
        _levels = results[1] as List<AcademicOption>;
        _sections = results[2] as List<AcademicOption>;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load academic setup.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Academic setup'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sessions'),
              Tab(text: 'Classes'),
              Tab(text: 'Sections'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _load)
            : TabBarView(
                children: [
                  _optionList(
                    items: _years,
                    emptyText: 'No academic sessions found.',
                    canCreate: widget.canManageSessions,
                    canEdit: widget.canManageSessions,
                    addLabel: 'Add session',
                    onAdd: () => _editYear(),
                    onEdit: _editYear,
                    trailing: (item) => item.isCurrent
                        ? const Chip(label: Text('Current'))
                        : null,
                  ),
                  _optionList(
                    items: _levels,
                    emptyText: 'No classes found.',
                    canCreate: widget.canCreateClass,
                    canEdit: widget.canEditClass,
                    addLabel: 'Add class',
                    onAdd: () => _editLevel(),
                    onEdit: _editLevel,
                    subtitle: (item) => 'Code: ${item.code ?? '-'}',
                  ),
                  _optionList(
                    items: _sections,
                    emptyText: 'No sections found.',
                    canCreate: widget.canCreateSection,
                    canEdit: widget.canEditSection,
                    addLabel: 'Add section',
                    onAdd: () => _editSection(),
                    onEdit: _editSection,
                    subtitle: (item) {
                      final level = _levels
                          .where((level) => level.id == item.levelId)
                          .firstOrNull;
                      return '${level?.name ?? 'Unknown class'} • Code: ${item.code ?? '-'}';
                    },
                  ),
                ],
              ),
      ),
    ),
  );

  Widget _optionList({
    required List<AcademicOption> items,
    required String emptyText,
    required bool canCreate,
    required bool canEdit,
    required String addLabel,
    required VoidCallback onAdd,
    required ValueChanged<AcademicOption> onEdit,
    String Function(AcademicOption)? subtitle,
    Widget? Function(AcademicOption)? trailing,
  }) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (canCreate) ...[
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(addLabel),
          ),
          const SizedBox(height: 12),
        ],
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text(emptyText)),
          )
        else
          ...items.map(
            (item) => Card(
              child: ListTile(
                title: Text(item.name),
                subtitle: subtitle == null ? null : Text(subtitle(item)),
                trailing:
                    trailing?.call(item) ??
                    (canEdit
                        ? IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => onEdit(item),
                          )
                        : null),
                onTap: canEdit ? () => onEdit(item) : null,
              ),
            ),
          ),
      ],
    ),
  );

  Future<void> _editYear([AcademicOption? year]) async {
    final input = await showAppFormSheet<(String, bool)>(
      context: context,
      builder: (context) => _YearInputDialog(
        title: year == null ? 'Add session' : 'Edit session',
        initialName: year?.name ?? '',
        initialCurrent: year?.isCurrent ?? true,
        showCurrent: year != null,
        lockCurrent: year?.isCurrent ?? false,
      ),
    );
    if (input == null || !mounted) return;
    try {
      await widget.apiClient.saveAcademicYear(
        widget.token,
        name: input.$1,
        yearId: year?.id,
        isCurrent: input.$2,
      );
      await _afterSave('Academic session saved.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _editLevel([AcademicOption? level]) async {
    final result = await _showNameCodeDialog(
      title: level == null ? 'Add class' : 'Edit class',
      item: level,
    );
    if (result == null || !mounted) return;
    try {
      await widget.apiClient.saveAcademicLevel(
        widget.token,
        name: result.$1,
        code: result.$2,
        levelId: level?.id,
      );
      await _afterSave('Class saved.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _editSection([AcademicOption? section]) async {
    if (_levels.isEmpty) {
      _showMessage('Create a class before adding a section.');
      return;
    }
    final result = await showAppFormSheet<(int, String, String)>(
      context: context,
      builder: (context) => _SectionInputDialog(
        title: section == null ? 'Add section' : 'Edit section',
        levels: _levels,
        initialLevelId: section?.levelId ?? _levels.first.id,
        initialName: section?.name ?? '',
        initialCode: section?.code ?? '',
      ),
    );
    if (result == null || !mounted) return;
    try {
      await widget.apiClient.saveAcademicSection(
        widget.token,
        levelId: result.$1,
        name: result.$2,
        code: result.$3,
        sectionId: section?.id,
      );
      await _afterSave('Section saved.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<(String, String)?> _showNameCodeDialog({
    required String title,
    AcademicOption? item,
  }) async {
    return showAppFormSheet<(String, String)>(
      context: context,
      builder: (context) => _NameCodeInputDialog(
        title: title,
        initialName: item?.name ?? '',
        initialCode: item?.code ?? '',
      ),
    );
  }

  Future<void> _afterSave(String message) async {
    if (!mounted) return;
    _changed = true;
    await _load();
    if (mounted) _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _YearInputDialog extends StatefulWidget {
  const _YearInputDialog({
    required this.title,
    required this.initialName,
    required this.initialCurrent,
    required this.showCurrent,
    required this.lockCurrent,
  });

  final String title;
  final String initialName;
  final bool initialCurrent;
  final bool showCurrent;
  final bool lockCurrent;

  @override
  State<_YearInputDialog> createState() => _YearInputDialogState();
}

class _YearInputDialogState extends State<_YearInputDialog> {
  late final TextEditingController _nameController;
  late bool _isCurrent;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _isCurrent = widget.initialCurrent;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormSheet(
    title: FormDialogHeader(
      title: widget.title,
      subtitle: 'Set the academic session name and current status.',
      icon: Icons.calendar_month_rounded,
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Session name *'),
          ),
          if (widget.showCurrent) ...[
            const SizedBox(height: 12),
            FormChoiceTile(
              value: _isCurrent,
              onChanged: widget.lockCurrent
                  ? null
                  : (value) => setState(() => _isCurrent = value),
              title: 'Current session',
              subtitle: widget.lockCurrent
                  ? 'The active session cannot be disabled here.'
                  : 'Use this session across academic operations.',
              icon: Icons.event_available_rounded,
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final name = _nameController.text.trim();
          if (name.isEmpty) return;
          Navigator.pop(context, (name, _isCurrent));
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _NameCodeInputDialog extends StatefulWidget {
  const _NameCodeInputDialog({
    required this.title,
    required this.initialName,
    required this.initialCode,
  });

  final String title;
  final String initialName;
  final String initialCode;

  @override
  State<_NameCodeInputDialog> createState() => _NameCodeInputDialogState();
}

class _NameCodeInputDialogState extends State<_NameCodeInputDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _codeController = TextEditingController(text: widget.initialCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormSheet(
    title: FormDialogHeader(
      title: widget.title,
      subtitle: 'Use a clear class name and a short unique code.',
      icon: Icons.school_rounded,
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Class name *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(labelText: 'Class code *'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final name = _nameController.text.trim();
          final code = _codeController.text.trim();
          if (name.isEmpty || code.isEmpty) return;
          Navigator.pop(context, (name, code));
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _SectionInputDialog extends StatefulWidget {
  const _SectionInputDialog({
    required this.title,
    required this.levels,
    required this.initialLevelId,
    required this.initialName,
    required this.initialCode,
  });

  final String title;
  final List<AcademicOption> levels;
  final int initialLevelId;
  final String initialName;
  final String initialCode;

  @override
  State<_SectionInputDialog> createState() => _SectionInputDialogState();
}

class _SectionInputDialogState extends State<_SectionInputDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late int _levelId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _codeController = TextEditingController(text: widget.initialCode);
    _levelId = widget.levels.any((level) => level.id == widget.initialLevelId)
        ? widget.initialLevelId
        : widget.levels.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormSheet(
    title: FormDialogHeader(
      title: widget.title,
      subtitle: 'Assign the section to a class and provide its code.',
      icon: Icons.account_tree_rounded,
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _levelId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Class *'),
            items: widget.levels
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _levelId = value ?? _levelId),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Section name *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(labelText: 'Section code *'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final name = _nameController.text.trim();
          final code = _codeController.text.trim();
          if (name.isEmpty || code.isEmpty) return;
          Navigator.pop(context, (_levelId, name, code));
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
