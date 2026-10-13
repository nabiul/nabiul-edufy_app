import 'package:flutter/material.dart';

import '../models/academic.dart';
import '../services/api_client.dart';
import '../widgets/form_design.dart';

class StudentFormScreen extends StatefulWidget {
  const StudentFormScreen({
    required this.apiClient,
    required this.token,
    required this.years,
    required this.levels,
    this.student,
    super.key,
  });

  final ApiClient apiClient;
  final String token;
  final List<AcademicOption> years;
  final List<AcademicOption> levels;
  final StudentDetails? student;

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  List<AcademicOption> _sections = const [];
  int? _yearId;
  int? _levelId;
  int? _sectionId;
  String _gender = 'male';
  String _religion = 'islam';
  String _feeCategory = 'general';
  bool _loadingSections = false;
  bool _saving = false;

  StudentCycle? get _cycle => widget.student?.cycles.isNotEmpty == true
      ? widget.student!.cycles.first
      : null;

  @override
  void initState() {
    super.initState();
    final student = widget.student;
    final cycle = _cycle;
    _yearId =
        cycle?.yearId ??
        widget.years.where((year) => year.isCurrent).firstOrNull?.id ??
        widget.years.firstOrNull?.id;
    _levelId = cycle?.levelId ?? widget.levels.firstOrNull?.id;
    _sectionId = cycle?.sectionId;
    _gender = student?.gender ?? 'male';
    _religion = student?.religion ?? 'islam';
    _feeCategory = cycle?.feeCategory ?? 'general';
    _fields = {
      'name': TextEditingController(text: student?.name),
      'name_bangla': TextEditingController(text: student?.banglaName),
      'dob': TextEditingController(text: student?.dob),
      'roll': TextEditingController(text: cycle?.rollNo?.toString()),
      'phone': TextEditingController(text: student?.phone),
      'email': TextEditingController(text: student?.email),
      'sms_phone': TextEditingController(
        text: student?.smsPhone ?? student?.phone,
      ),
      'present_address': TextEditingController(text: student?.address),
      'permanent_address': TextEditingController(
        text: student?.permanentAddress,
      ),
      'father_name': TextEditingController(text: student?.fatherName),
      'father_phone': TextEditingController(text: student?.fatherPhone),
      'mother_name': TextEditingController(text: student?.motherName),
      'mother_phone': TextEditingController(text: student?.motherPhone),
      'discount': TextEditingController(
        text: (cycle?.discount ?? 0).toStringAsFixed(2),
      ),
    };
    _loadSections(_levelId);
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSections(int? levelId) async {
    setState(() => _loadingSections = true);
    try {
      final sections = await widget.apiClient.academicSections(
        widget.token,
        levelId: levelId,
      );
      if (!mounted) return;
      setState(() {
        _sections = sections;
        if (!sections.any((section) => section.id == _sectionId)) {
          _sectionId = sections.firstOrNull?.id;
        }
      });
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loadingSections = false);
    }
  }

  Future<void> _pickDob() async {
    final initial = DateTime.tryParse(_fields['dob']!.text) ?? DateTime(2015);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() => _fields['dob']!.text = _isoDate(date));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fields['dob']!.text.trim().isEmpty) {
      _showMessage('Select date of birth.');
      return;
    }
    if (_yearId == null || _levelId == null || _sectionId == null) {
      _showMessage('Select a session, class and section.');
      return;
    }
    final editing = widget.student != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editing ? 'Confirm update' : 'Confirm student'),
        content: Text(
          editing
              ? 'Save changes for ${_fields['name']!.text.trim()}?'
              : 'Create ${_fields['name']!.text.trim()} as a new student?',
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
      await widget.apiClient.saveStudent(widget.token, {
        'year_id': _yearId,
        'level_id': _levelId,
        'section_id': _sectionId,
        'roll_no': int.parse(_fields['roll']!.text),
        'fee_category': _feeCategory,
        'discount': double.tryParse(_fields['discount']!.text) ?? 0,
        'name_english': _fields['name']!.text.trim(),
        'name_bangla': _nullable('name_bangla'),
        'dob': _fields['dob']!.text,
        'phone': _nullable('phone'),
        'email': _nullable('email'),
        'religion': _religion,
        'gender': _gender,
        'permanent_address': _fields['permanent_address']!.text.trim(),
        'present_address': _fields['present_address']!.text.trim(),
        'father_name_english': _fields['father_name']!.text.trim(),
        'father_phone': _fields['father_phone']!.text.trim(),
        'mother_name_english': _fields['mother_name']!.text.trim(),
        'mother_phone': _fields['mother_phone']!.text.trim(),
        'sms_phone': _fields['sms_phone']!.text.trim(),
      }, studentId: widget.student?.id);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _nullable(String key) {
    final value = _fields[key]!.text.trim();
    return value.isEmpty ? null : value;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.student != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit student' : 'Add student')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: FormRequiredHint(),
            ),
            const _FormHeading('Academic information'),
            _OptionField(
              label: 'Session',
              value: _yearId,
              options: widget.years,
              onChanged: editing
                  ? null
                  : (value) => setState(() => _yearId = value),
            ),
            const SizedBox(height: 12),
            _OptionField(
              label: 'Class',
              value: _levelId,
              options: widget.levels,
              onChanged: editing
                  ? null
                  : (value) {
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
              _OptionField(
                label: 'Section',
                value: _sectionId,
                options: _sections,
                onChanged: editing
                    ? null
                    : (value) => setState(() => _sectionId = value),
              ),
            const SizedBox(height: 12),
            _textField('roll', 'Roll number', number: true, readOnly: editing),
            if (editing) ...[
              const SizedBox(height: 8),
              const Text(
                'Use Transfer or Promote to change session, class, section, or roll.',
              ),
            ],
            const SizedBox(height: 12),
            _enumField(
              'Fee category',
              _feeCategory,
              const {
                'general': 'General',
                'half_free': 'Half free',
                'full_free': 'Full free',
              },
              (value) => setState(() => _feeCategory = value),
            ),
            const SizedBox(height: 12),
            _textField('discount', 'Discount', number: true, required: false),
            const _FormHeading('Student information'),
            _textField('name', 'Name in English'),
            const SizedBox(height: 12),
            _textField('name_bangla', 'Name in Bangla', required: false),
            const SizedBox(height: 12),
            AppDateField(
              label: 'Date of birth',
              value: _fields['dob']!.text.isEmpty
                  ? 'Select date'
                  : _fields['dob']!.text,
              required: true,
              onTap: _pickDob,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _enumField('Gender', _gender, const {
                    'male': 'Male',
                    'female': 'Female',
                    'other': 'Other',
                  }, (value) => setState(() => _gender = value)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _enumField(
                    'Religion',
                    _religion,
                    const {
                      'islam': 'Islam',
                      'hinduism': 'Hinduism',
                      'christianity': 'Christianity',
                      'buddhism': 'Buddhism',
                      'other': 'Other',
                    },
                    (value) => setState(() => _religion = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _textField('phone', 'Student phone', required: false, phone: true),
            const SizedBox(height: 12),
            _textField('sms_phone', 'SMS phone', phone: true),
            const SizedBox(height: 12),
            _textField('email', 'Email', required: false, email: true),
            const SizedBox(height: 12),
            _textField('present_address', 'Present address', lines: 2),
            const SizedBox(height: 12),
            _textField('permanent_address', 'Permanent address', lines: 2),
            const _FormHeading('Guardian information'),
            _textField('father_name', "Father's name"),
            const SizedBox(height: 12),
            _textField('father_phone', "Father's phone", phone: true),
            const SizedBox(height: 12),
            _textField('mother_name', "Mother's name"),
            const SizedBox(height: 12),
            _textField('mother_phone', "Mother's phone", phone: true),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(editing ? 'Save changes' : 'Create student'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    String key,
    String label, {
    bool required = true,
    bool number = false,
    bool phone = false,
    bool email = false,
    int lines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: _fields[key],
      maxLines: lines,
      readOnly: readOnly,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : phone
          ? TextInputType.phone
          : email
          ? TextInputType.emailAddress
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: required ? '$label *' : '$label (optional)',
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label is required.';
        }
        if (key == 'roll' && (int.tryParse(value ?? '') ?? 0) < 1) {
          return 'Enter a valid roll number.';
        }
        if (email && value?.isNotEmpty == true && !value!.contains('@')) {
          return 'Enter a valid email.';
        }
        return null;
      },
    );
  }

  Widget _enumField(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: '$label *'),
      items: options.entries
          .map(
            (item) =>
                DropdownMenuItem(value: item.key, child: Text(item.value)),
          )
          .toList(),
      onChanged: (value) => onChanged(value!),
    );
  }
}

class _OptionField extends StatelessWidget {
  const _OptionField({
    required this.label,
    required this.value,
    required this.options,
    this.onChanged,
  });

  final String label;
  final int? value;
  final List<AcademicOption> options;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: options.any((option) => option.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: '$label *'),
      items: options
          .map(
            (option) =>
                DropdownMenuItem(value: option.id, child: Text(option.name)),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? '$label is required.' : null,
    );
  }
}

class _FormHeading extends StatelessWidget {
  const _FormHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final icon = title.startsWith('Academic')
        ? Icons.school_rounded
        : title.startsWith('Guardian')
        ? Icons.family_restroom_rounded
        : Icons.badge_rounded;
    return Container(
      margin: const EdgeInsets.only(top: 22, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE5F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF1FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xFF3D5AF1), size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

String _isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
