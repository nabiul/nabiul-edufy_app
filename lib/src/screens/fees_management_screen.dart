import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/academic.dart';
import '../models/fees.dart';
import '../services/api_client.dart';
import '../widgets/form_design.dart';

class FeesManagementScreen extends StatefulWidget {
  const FeesManagementScreen({
    required this.apiClient,
    required this.token,
    required this.years,
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
  final List<AcademicOption> years;
  final bool canCreatePurpose, canEditPurpose, canDeletePurpose;
  final bool canCreateTemplate, canEditTemplate, canDeleteTemplate;
  @override
  State<FeesManagementScreen> createState() => _FeesManagementScreenState();
}

class _FeesManagementScreenState extends State<FeesManagementScreen> {
  List<AcademicOption> _levels = const [];
  List<FeePurposeData> _purposes = const [];
  List<FeeTemplateData> _templates = const [];
  late int? _yearId;
  bool _loading = true, _changed = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _yearId =
        widget.years.where((e) => e.isCurrent).firstOrNull?.id ??
        widget.years.firstOrNull?.id;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    List<AcademicOption>? levels;
    List<FeePurposeData>? purposes;
    List<FeeTemplateData>? templates;
    final errors = <String>[];

    await Future.wait<void>([
      () async {
        try {
          levels = await widget.apiClient.academicLevels(widget.token);
        } catch (error) {
          errors.add(_errorMessage(error));
        }
      }(),
      () async {
        try {
          purposes = await widget.apiClient.feePurposes(widget.token);
        } catch (error) {
          errors.add(_errorMessage(error));
        }
      }(),
      () async {
        try {
          templates = await widget.apiClient.feeTemplates(
            widget.token,
            yearId: _yearId,
          );
        } catch (error) {
          errors.add(_errorMessage(error));
        }
      }(),
    ]);
    if (!mounted) return;
    setState(() {
      if (levels != null) _levels = levels!;
      if (purposes != null) _purposes = purposes!;
      if (templates != null) _templates = templates!;
      _error = errors.isEmpty ? null : errors.toSet().join('\n');
      _loading = false;
    });
  }

  String _errorMessage(Object error) => error is ApiException
      ? error.message
      : 'Could not read data from ${ApiConfig.baseUrl}.';

  Future<void> _editPurpose([FeePurposeData? purpose]) async {
    final value = await showAppFormSheet<_FeePurposeInput>(
      context: context,
      builder: (_) => _FeePurposeDialog(purpose: purpose),
    );
    if (value == null || !mounted) return;
    try {
      await widget.apiClient.saveFeePurpose(
        widget.token,
        id: purpose?.id,
        name: value.name,
        category: value.category,
        isResidential: value.residential,
      );
      await _saved(
        purpose == null ? 'Fee purpose created.' : 'Fee purpose updated.',
      );
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    }
  }

  Future<void> _editTemplate([FeeTemplateData? template]) async {
    if (_yearId == null || _levels.isEmpty || _purposes.isEmpty) {
      _message('Create session, class and fee purpose first.');
      return;
    }
    final value = await showAppFormSheet<_FeeTemplateInput>(
      context: context,
      builder: (_) => _FeeTemplateDialog(
        years: widget.years,
        levels: _levels,
        purposes: _purposes,
        template: template,
        initialYearId: _yearId!,
      ),
    );
    if (value == null || !mounted) return;
    try {
      await widget.apiClient.saveFeeTemplate(
        widget.token,
        id: template?.id,
        yearId: value.yearId,
        levelId: value.levelId,
        month: value.month,
        items: value.items,
      );
      await _saved(
        template == null ? 'Fee template created.' : 'Fee template updated.',
      );
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    }
  }

  Future<void> _delete(String label, Future<void> Function() action) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete $label?'),
        content: const Text('Records currently in use cannot be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await action();
      await _saved('$label deleted.');
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    }
  }

  Future<void> _saved(String value) async {
    _changed = true;
    await _load();
    if (mounted) _message(value);
  }

  void _message(String value) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(value)));
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage fees'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Purposes'),
              Tab(text: 'Templates'),
            ],
          ),
        ),
        body: _loading && _purposes.isEmpty && _templates.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _purposes.isEmpty && _templates.isEmpty
            ? _ManagementLoadError(
                message: _error!,
                server: ApiConfig.baseUrl,
                onRetry: _load,
              )
            : TabBarView(children: [_purposeList(), _templateList()]),
      ),
    ),
  );
  Widget _purposeList() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _listStatus('Existing fee purposes', _purposes.length),
      if (_error != null) _warning(_error!),
      if (widget.canCreatePurpose)
        FilledButton.icon(
          onPressed: () => _editPurpose(),
          icon: const Icon(Icons.add),
          label: const Text('Add fee purpose'),
        ),
      const SizedBox(height: 12),
      if (_purposes.isEmpty) const _EmptyList('No fee purposes found.'),
      ..._purposes.map(
        (p) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.sell_outlined)),
            title: Text(
              p.name.trim().isEmpty ? 'Unnamed purpose' : p.name.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '${p.category}${p.isResidential ? ' • Residential' : ''}',
              style: const TextStyle(color: Color(0xFF4E5B73)),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) => v == 'edit'
                  ? _editPurpose(p)
                  : _delete(
                      'fee purpose',
                      () =>
                          widget.apiClient.deleteFeePurpose(widget.token, p.id),
                    ),
              itemBuilder: (_) => [
                if (widget.canEditPurpose)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (widget.canDeletePurpose)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        ),
      ),
    ],
  );
  Widget _templateList() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      DropdownButtonFormField<int>(
        initialValue: _yearId,
        decoration: const InputDecoration(labelText: 'Session'),
        items: widget.years
            .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
            .toList(),
        onChanged: (v) async {
          setState(() => _yearId = v);
          await _load();
        },
      ),
      const SizedBox(height: 12),
      _listStatus('Existing templates', _templates.length),
      if (_error != null) _warning(_error!),
      if (widget.canCreateTemplate)
        FilledButton.icon(
          onPressed: () => _editTemplate(),
          icon: const Icon(Icons.add),
          label: const Text('Add fee template'),
        ),
      const SizedBox(height: 12),
      if (_templates.isEmpty)
        const _EmptyList('No templates found for this session.'),
      ..._templates.map(
        (t) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () => _viewTemplate(t),
            leading: const CircleAvatar(
              child: Icon(Icons.receipt_long_outlined),
            ),
            title: Text('${t.level} • ${t.month}'),
            subtitle: Text(
              '${t.items.length} item(s) • ${t.totalAmount.toStringAsFixed(2)}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) => v == 'view'
                  ? _viewTemplate(t)
                  : v == 'edit'
                  ? _editTemplate(t)
                  : _delete(
                      'fee template',
                      () => widget.apiClient.deleteFeeTemplate(
                        widget.token,
                        t.id,
                      ),
                    ),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'view', child: Text('View')),
                if (widget.canEditTemplate)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (widget.canDeleteTemplate)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  void _viewTemplate(FeeTemplateData template) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          children: [
            Text(
              '${template.level} • ${template.month}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Session ${template.year}  •  ${template.items.length} fee item(s)',
              style: const TextStyle(color: Color(0xFF667085)),
            ),
            const SizedBox(height: 18),
            ...template.items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.sell_outlined),
                  title: Text(item.purpose),
                  trailing: Text(
                    '৳${item.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Total template amount',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              trailing: Text(
                '৳${template.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF087A61),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listStatus(String label, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        Chip(label: Text('$count')),
      ],
    ),
  );

  Widget _warning(String message) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: const Icon(Icons.warning_amber_rounded),
      title: Text(message),
      trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
    ),
  );
}

class _EmptyList extends StatelessWidget {
  const _EmptyList(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Center(child: Text(message)),
  );
}

class _ManagementLoadError extends StatelessWidget {
  const _ManagementLoadError({
    required this.message,
    required this.server,
    required this.onRetry,
  });
  final String message;
  final String server;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            server,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _FeePurposeInput {
  const _FeePurposeInput(this.name, this.category, this.residential);
  final String name, category;
  final bool residential;
}

class _FeePurposeDialog extends StatefulWidget {
  const _FeePurposeDialog({this.purpose});
  final FeePurposeData? purpose;
  @override
  State<_FeePurposeDialog> createState() => _FeePurposeDialogState();
}

class _FeePurposeDialogState extends State<_FeePurposeDialog> {
  late final TextEditingController _name;
  late String _category;
  late bool _residential;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.purpose?.name);
    _category = widget.purpose?.categoryValue ?? 'general';
    _residential = widget.purpose?.isResidential ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormSheet(
    title: FormDialogHeader(
      title: widget.purpose == null ? 'Add fee purpose' : 'Edit fee purpose',
      subtitle: 'Define how this fee will be categorized and applied.',
      icon: Icons.sell_rounded,
      color: const Color(0xFFB77414),
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Purpose name *'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Fee category *'),
            items: const [
              DropdownMenuItem(value: 'general', child: Text('General')),
              DropdownMenuItem(value: 'half_free', child: Text('Half free')),
              DropdownMenuItem(value: 'full_free', child: Text('Full free')),
            ],
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          FormChoiceTile(
            title: 'Residential fee',
            subtitle: 'Apply this purpose to residential students.',
            icon: Icons.home_work_rounded,
            value: _residential,
            onChanged: (v) => setState(() => _residential = v),
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
          final name = _name.text.trim();
          if (name.length >= 3) {
            Navigator.pop(
              context,
              _FeePurposeInput(name, _category, _residential),
            );
          }
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _FeeTemplateInput {
  const _FeeTemplateInput(this.yearId, this.levelId, this.month, this.items);
  final int yearId, levelId;
  final String month;
  final List<Map<String, dynamic>> items;
}

class _FeeTemplateDialog extends StatefulWidget {
  const _FeeTemplateDialog({
    required this.years,
    required this.levels,
    required this.purposes,
    required this.initialYearId,
    this.template,
  });
  final List<AcademicOption> years, levels;
  final List<FeePurposeData> purposes;
  final int initialYearId;
  final FeeTemplateData? template;
  @override
  State<_FeeTemplateDialog> createState() => _FeeTemplateDialogState();
}

class _FeeTemplateDialogState extends State<_FeeTemplateDialog> {
  static const months = [
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december',
  ];
  late int _yearId, _levelId;
  late String _month;
  late final Map<int, TextEditingController> _amounts;
  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _yearId = t?.yearId ?? widget.initialYearId;
    _levelId = t?.levelId ?? widget.levels.first.id;
    _month = t?.monthValue ?? months[DateTime.now().month - 1];
    _amounts = {
      for (final p in widget.purposes)
        p.id: TextEditingController(
          text:
              t?.items
                  .where((i) => i.purposeId == p.id)
                  .firstOrNull
                  ?.amount
                  .toStringAsFixed(2) ??
              '',
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _amounts.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormSheet(
    title: FormDialogHeader(
      title: widget.template == null ? 'Add fee template' : 'Edit fee template',
      subtitle: 'Set the session, class, month and fee amounts.',
      icon: Icons.receipt_long_rounded,
      color: const Color(0xFFB77414),
    ),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _yearId,
              decoration: const InputDecoration(labelText: 'Session *'),
              items: widget.years
                  .map(
                    (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _yearId = v!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _levelId,
              decoration: const InputDecoration(labelText: 'Class *'),
              items: widget.levels
                  .map(
                    (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _levelId = v!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _month,
              decoration: const InputDecoration(labelText: 'Month *'),
              items: months
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text('${e[0].toUpperCase()}${e.substring(1)}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _month = v!),
            ),
            const SizedBox(height: 16),
            const FormSectionLabel(
              title: 'Fee amounts',
              subtitle: 'Enter at least one amount; leave unused fees blank.',
              icon: Icons.payments_outlined,
            ),
            ...widget.purposes.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _amounts[p.id],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '${p.name} (optional)',
                    prefixText: '৳ ',
                  ),
                ),
              ),
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
          final items = widget.purposes
              .map(
                (p) => {
                  'purpose_id': p.id,
                  'amount': double.tryParse(_amounts[p.id]!.text),
                },
              )
              .where((e) => (e['amount'] as double? ?? 0) > 0)
              .toList();
          if (items.isNotEmpty) {
            Navigator.pop(
              context,
              _FeeTemplateInput(_yearId, _levelId, _month, items),
            );
          }
        },
        child: const Text('Save'),
      ),
    ],
  );
}
