import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/academic.dart';
import '../models/enquiry.dart';
import '../services/api_client.dart';
import 'enquiry_form_screen.dart';
import 'enquiry_details_screen.dart';

class EnquiriesScreen extends StatefulWidget {
  const EnquiriesScreen({required this.apiClient, required this.token, required this.canCreate, required this.canEdit, super.key});
  final ApiClient apiClient;
  final String token;
  final bool canCreate;
  final bool canEdit;

  @override
  State<EnquiriesScreen> createState() => _EnquiriesScreenState();
}

class _EnquiriesScreenState extends State<EnquiriesScreen> {
  final _search = TextEditingController();
  List<Enquiry> _items = const [];
  EnquiryOptions _options = const EnquiryOptions(
    levels: [], years: [],
    statuses: ['new', 'contacted', 'interested', 'follow_up', 'admitted', 'not_interested', 'lost'],
  );
  String? _status;
  bool _dueOnly = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await Future.wait<dynamic>([
        widget.apiClient.enquiries(widget.token, search: _search.text.trim(), status: _status, due: _dueOnly),
        widget.apiClient.enquiryOptions(widget.token),
      ]);
      if (mounted) setState(() { _items = result[0] as List<Enquiry>; _options = result[1] as EnquiryOptions; });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _label(String value) => value.replaceAll('_', ' ').split(' ').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  Color _color(String status) => switch (status) {
    'admitted' || 'interested' => Colors.green,
    'follow_up' => Colors.orange,
    'lost' || 'not_interested' => Colors.red,
    'contacted' => Colors.blue,
    _ => Colors.indigo,
  };

  Future<void> _contact(String phone, String action) async {
    var clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (action == 'whatsapp') {
      clean = clean.replaceFirst('+', '');
      if (clean.startsWith('0')) clean = '880${clean.substring(1)}';
    }
    final uri = switch (action) {
      'call' => Uri(scheme: 'tel', path: clean),
      'sms' => Uri(scheme: 'sms', path: clean),
      _ => Uri.parse('https://wa.me/$clean'),
    };
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This action is not available on this device.')));
      }
    } catch (_) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This action is not available on this device.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Row(children: [
            Expanded(child: TextField(controller: _search, onSubmitted: (_) => _load(), decoration: const InputDecoration(labelText: 'Search enquiry', prefixIcon: Icon(Icons.search)))),
            IconButton(onPressed: _load, icon: const Icon(Icons.search_rounded)),
          ]),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [const DropdownMenuItem<String>(value: null, child: Text('All statuses')), ..._options.statuses.map((status) => DropdownMenuItem(value: status, child: Text(_label(status))))],
            onChanged: (value) { setState(() => _status = value); _load(); },
          ),
          Align(alignment: Alignment.centerLeft, child: FilterChip(label: const Text('Due follow-ups'), selected: _dueOnly, avatar: const Icon(Icons.event_busy, size: 18), onSelected: (value) { setState(() => _dueOnly = value); _load(); })),
          if (widget.canCreate) Padding(padding: const EdgeInsets.only(top: 12), child: FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('New admission enquiry'))),
          const SizedBox(height: 16),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_error != null) _Error(message: _error!, onRetry: _load)
          else if (_items.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No enquiries found.')))
          else ..._items.map(_card),
        ],
      ),
    );
  }

  Widget _card(Enquiry item) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _openDetails(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          CircleAvatar(radius: 20, backgroundColor: _color(item.status).withAlpha(25), child: Text(item.studentName.isEmpty ? '?' : item.studentName[0].toUpperCase(), style: TextStyle(color: _color(item.status), fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(item.studentName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))), Text(_label(item.status), style: TextStyle(color: _color(item.status), fontSize: 11, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 3),
            Text('${item.phone}  •  ${item.levelName ?? 'Class not selected'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (item.nextFollowUpAt != null) Text('Follow-up: ${_date(item.nextFollowUpAt!)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.orange, fontSize: 11)),
          ])),
          const SizedBox(width: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(visualDensity: VisualDensity.compact, tooltip: 'Call', onPressed: () => _contact(item.phone, 'call'), icon: const Icon(Icons.call, size: 19, color: Colors.green)),
            IconButton(visualDensity: VisualDensity.compact, tooltip: 'WhatsApp', onPressed: () => _contact(item.phone, 'whatsapp'), icon: const Icon(Icons.chat, size: 19, color: Colors.teal)),
            IconButton(visualDensity: VisualDensity.compact, tooltip: 'Text', onPressed: () => _contact(item.phone, 'sms'), icon: const Icon(Icons.sms_outlined, size: 19, color: Colors.blue)),
            if (widget.canEdit) IconButton(visualDensity: VisualDensity.compact, tooltip: 'Add follow-up', onPressed: () => _followUpWithCalendar(item), icon: const Icon(Icons.event_available_outlined, size: 19, color: Colors.orange)),
          ]),
        ]),
      ),
    ),
  );

  String _date(String value) => value.length >= 16 ? value.substring(0, 16).replaceFirst('T', ' ') : value;
  Future<void> _openDetails(Enquiry item) async { await Navigator.push(context, MaterialPageRoute(builder: (_) => EnquiryDetailsScreen(apiClient: widget.apiClient, token: widget.token, enquiry: item, options: _options, canEdit: widget.canEdit))); _load(); }
  Future<void> _openForm([Enquiry? item]) async { final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EnquiryFormScreen(apiClient: widget.apiClient, token: widget.token, options: _options, enquiry: item))); if (saved == true) _load(); }
  Future<void> _followUpWithCalendar(Enquiry item) async { final selectedDate = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365))); if (selectedDate == null || !mounted) return; final followUpAt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59); final notes = TextEditingController(); final outcome = TextEditingController(); final saved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(scrollable: true, title: Text('Follow-up: ${item.studentName}'), content: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_month), title: const Text('Next follow-up date'), subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}')), TextField(controller: outcome, decoration: const InputDecoration(labelText: 'Outcome')), TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () async { if (notes.text.trim().isEmpty) return; try { await widget.apiClient.saveEnquiryFollowUp(widget.token, item.id, {'contacted_at': DateTime.now().toIso8601String(), 'contact_method': 'phone', 'outcome': outcome.text.trim(), 'notes': notes.text.trim(), 'next_follow_up_at': followUpAt.toIso8601String()}); if (context.mounted) Navigator.pop(context, true); } on ApiException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message))); } }, child: const Text('Save'))])); if (saved == true) _load(); }
}

class _EnquiryFormDialog extends StatefulWidget {
  const _EnquiryFormDialog({required this.apiClient, required this.token, required this.options, required this.enquiry});
  final ApiClient apiClient; final String token; final EnquiryOptions options; final Enquiry? enquiry;
  @override State<_EnquiryFormDialog> createState() => _EnquiryFormDialogState();
}

class _EnquiryFormDialogState extends State<_EnquiryFormDialog> {
  late final Map<String, TextEditingController> _fields;
  int? _levelId, _yearId; late String _status; bool _saving = false;
  bool get _editing => widget.enquiry != null;
  @override void initState() { super.initState(); final item = widget.enquiry; _fields = {for (final key in ['student_name', 'guardian_name', 'phone', 'alternate_phone', 'email', 'source', 'next_follow_up_at', 'admission_application_id', 'notes', 'lost_reason']) key: TextEditingController()}; _fields['student_name']!.text = item?.studentName ?? ''; _fields['guardian_name']!.text = item?.guardianName ?? ''; _fields['phone']!.text = item?.phone ?? ''; _fields['alternate_phone']!.text = item?.alternatePhone ?? ''; _fields['email']!.text = item?.email ?? ''; _fields['source']!.text = item?.source ?? ''; _fields['next_follow_up_at']!.text = item?.nextFollowUpAt ?? ''; _fields['admission_application_id']!.text = item?.admissionApplicationId?.toString() ?? ''; _fields['notes']!.text = item?.notes ?? ''; _levelId = item?.levelId; _yearId = item?.yearId; _status = item?.status ?? 'new'; }
  @override void dispose() { for (final controller in _fields.values) { controller.dispose(); } super.dispose(); }
  TextField _text(String key, String label, {TextInputType? type, int maxLines = 1}) => TextField(controller: _fields[key], keyboardType: type, maxLines: maxLines, decoration: InputDecoration(labelText: label));
  Future<void> _save() async { if (_fields['student_name']!.text.trim().isEmpty || _fields['phone']!.text.trim().isEmpty) return; setState(() => _saving = true); final data = {'student_name': _fields['student_name']!.text.trim(), 'guardian_name': _fields['guardian_name']!.text.trim(), 'phone': _fields['phone']!.text.trim(), 'alternate_phone': _fields['alternate_phone']!.text.trim(), 'email': _fields['email']!.text.trim(), 'level_id': _levelId, 'year_id': _yearId, 'source': _fields['source']!.text.trim(), 'status': _status, 'next_follow_up_at': _fields['next_follow_up_at']!.text.trim().isEmpty ? null : _fields['next_follow_up_at']!.text.trim(), 'admission_application_id': int.tryParse(_fields['admission_application_id']!.text.trim()), 'notes': _fields['notes']!.text.trim(), 'lost_reason': _fields['lost_reason']!.text.trim()}; try { await widget.apiClient.saveEnquiry(widget.token, data, id: widget.enquiry?.id); if (mounted) Navigator.pop(context, true); } on ApiException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message))); } finally { if (mounted) setState(() => _saving = false); } }
  @override Widget build(BuildContext context) => AlertDialog(title: Text(_editing ? 'Edit admission enquiry' : 'New admission enquiry'), content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [_text('student_name', 'Student name'), _text('guardian_name', 'Guardian name'), _text('phone', 'Primary phone', type: TextInputType.phone), _text('alternate_phone', 'Alternate phone', type: TextInputType.phone), _text('email', 'Email', type: TextInputType.emailAddress), DropdownButtonFormField<int>(initialValue: _levelId, decoration: const InputDecoration(labelText: 'Interested class'), items: widget.options.levels.map((AcademicOption option) => DropdownMenuItem(value: option.id, child: Text(option.name))).toList(), onChanged: (value) => setState(() => _levelId = value)), DropdownButtonFormField<int>(initialValue: _yearId, decoration: const InputDecoration(labelText: 'Academic year'), items: widget.options.years.map((AcademicOption option) => DropdownMenuItem(value: option.id, child: Text(option.name))).toList(), onChanged: (value) => setState(() => _yearId = value)), _text('source', 'Source'), DropdownButtonFormField<String>(initialValue: _status, decoration: const InputDecoration(labelText: 'Status'), items: widget.options.statuses.map((status) => DropdownMenuItem(value: status, child: Text(status.replaceAll('_', ' ')))).toList(), onChanged: (value) => setState(() => _status = value ?? 'new')), _text('next_follow_up_at', 'Next follow-up (ISO date/time)'), _text('admission_application_id', 'Admission application ID', type: TextInputType.number), _text('notes', 'Notes', maxLines: 3), _text('lost_reason', 'Lost reason', maxLines: 2)]))), actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving...' : 'Save'))]);
}

class _Error extends StatelessWidget { const _Error({required this.message, required this.onRetry}); final String message; final VoidCallback onRetry; @override Widget build(BuildContext context) => Column(children: [Text(message), TextButton(onPressed: onRetry, child: const Text('Retry'))]); }
