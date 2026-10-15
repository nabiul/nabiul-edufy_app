import 'package:flutter/material.dart';

import '../models/academic.dart';
import '../models/enquiry.dart';
import '../services/api_client.dart';
import '../widgets/form_design.dart';

class EnquiryFormScreen extends StatefulWidget {
  const EnquiryFormScreen({required this.apiClient, required this.token, required this.options, this.enquiry, super.key});
  final ApiClient apiClient;
  final String token;
  final EnquiryOptions options;
  final Enquiry? enquiry;

  @override
  State<EnquiryFormScreen> createState() => _EnquiryFormScreenState();
}

class _EnquiryFormScreenState extends State<EnquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  int? _levelId, _yearId;
  late String _status;
  DateTime? _followUpDate;
  bool _saving = false;

  bool get _editing => widget.enquiry != null;

  @override
  void initState() {
    super.initState();
    final item = widget.enquiry;
    _fields = {
      for (final key in ['student_name', 'guardian_name', 'phone', 'alternate_phone', 'email', 'source', 'admission_application_id', 'notes', 'lost_reason'])
        key: TextEditingController(),
    };
    _fields['student_name']!.text = item?.studentName ?? '';
    _fields['guardian_name']!.text = item?.guardianName ?? '';
    _fields['phone']!.text = item?.phone ?? '';
    _fields['alternate_phone']!.text = item?.alternatePhone ?? '';
    _fields['email']!.text = item?.email ?? '';
    _fields['source']!.text = item?.source ?? '';
    _fields['admission_application_id']!.text = item?.admissionApplicationId?.toString() ?? '';
    _fields['notes']!.text = item?.notes ?? '';
    _levelId = item?.levelId;
    _yearId = item?.yearId;
    _status = item?.status ?? 'new';
    _followUpDate = item?.nextFollowUpAt == null ? null : DateTime.tryParse(item!.nextFollowUpAt!);
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextFormField _field(String key, String label, {bool required = false, TextInputType? type, int lines = 1}) => TextFormField(
    controller: _fields[key],
    keyboardType: type,
    maxLines: lines,
    validator: required ? (value) => value?.trim().isEmpty == true ? 'Required' : null : null,
    decoration: InputDecoration(labelText: required ? '$label *' : label),
  );

  Future<void> _pickFollowUpDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (selected != null && mounted) {
      setState(() => _followUpDate = selected);
    }
  }

  String _dateLabel() {
    if (_followUpDate == null) return 'Select next follow-up date';
    return '${_followUpDate!.day.toString().padLeft(2, '0')}/${_followUpDate!.month.toString().padLeft(2, '0')}/${_followUpDate!.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final followUpAt = _followUpDate == null
        ? null
        : DateTime(_followUpDate!.year, _followUpDate!.month, _followUpDate!.day, 23, 59).toIso8601String();
    final data = {
      'student_name': _fields['student_name']!.text.trim(),
      'guardian_name': _fields['guardian_name']!.text.trim(),
      'phone': _fields['phone']!.text.trim(),
      'alternate_phone': _fields['alternate_phone']!.text.trim(),
      'email': _fields['email']!.text.trim(),
      'level_id': _levelId,
      'year_id': _yearId,
      'source': _fields['source']!.text.trim(),
      'status': _status,
      'next_follow_up_at': followUpAt,
      'admission_application_id': int.tryParse(_fields['admission_application_id']!.text.trim()),
      'notes': _fields['notes']!.text.trim(),
      'lost_reason': _fields['lost_reason']!.text.trim(),
    };
    try {
      await widget.apiClient.saveEnquiry(widget.token, data, id: widget.enquiry?.id);
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit admission enquiry' : 'New admission enquiry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const Align(alignment: Alignment.centerRight, child: FormRequiredHint()),
            const FormSectionLabel(title: 'Student and guardian information', icon: Icons.person_outline_rounded),
            _field('student_name', 'Student name', required: true),
            const SizedBox(height: 12),
            _field('guardian_name', 'Guardian name'),
            const SizedBox(height: 12),
            _field('phone', 'Primary phone', required: true, type: TextInputType.phone),
            const SizedBox(height: 12),
            _field('alternate_phone', 'Alternate phone', type: TextInputType.phone),
            const SizedBox(height: 12),
            _field('email', 'Email', type: TextInputType.emailAddress),
            const FormSectionLabel(title: 'Admission interest', icon: Icons.school_outlined),
            DropdownButtonFormField<int>(initialValue: _levelId, decoration: const InputDecoration(labelText: 'Interested class'), items: widget.options.levels.map((AcademicOption option) => DropdownMenuItem(value: option.id, child: Text(option.name))).toList(), onChanged: (value) => setState(() => _levelId = value)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(initialValue: _yearId, decoration: const InputDecoration(labelText: 'Academic year'), items: widget.options.years.map((AcademicOption option) => DropdownMenuItem(value: option.id, child: Text(option.name))).toList(), onChanged: (value) => setState(() => _yearId = value)),
            const SizedBox(height: 12),
            _field('source', 'Source'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: _status, decoration: const InputDecoration(labelText: 'Status'), items: widget.options.statuses.map((status) => DropdownMenuItem(value: status, child: Text(status.replaceAll('_', ' ')))).toList(), onChanged: (value) => setState(() => _status = value ?? 'new')),
            const SizedBox(height: 12),
            AppDateField(label: 'Next follow-up', value: _dateLabel(), onTap: _pickFollowUpDate),
            const FormSectionLabel(title: 'Notes', icon: Icons.notes_rounded),
            _field('admission_application_id', 'Admission application ID', type: TextInputType.number),
            const SizedBox(height: 12),
            _field('notes', 'Notes', lines: 4),
            const SizedBox(height: 12),
            _field('lost_reason', 'Lost reason', lines: 2),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_editing ? 'Save changes' : 'Create enquiry')),
          ],
        ),
      ),
    );
  }
}
