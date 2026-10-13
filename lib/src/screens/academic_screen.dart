import 'package:flutter/material.dart';

import '../models/academic.dart';
import '../services/api_client.dart';
import 'student_form_screen.dart';
import 'student_promotion_screen.dart';
import 'student_transfer_screen.dart';
import 'attendance_screen.dart';
import 'academic_setup_screen.dart';
import 'fees_screen.dart';

class AcademicScreen extends StatefulWidget {
  const AcademicScreen({
    required this.apiClient,
    required this.token,
    required this.canCreateStudent,
    required this.canEditStudent,
    required this.canManageAttendance,
    required this.canManageSessions,
    required this.canCreateClass,
    required this.canEditClass,
    required this.canCreateSection,
    required this.canEditSection,
    required this.canPromoteStudent,
    required this.canTransferStudent,
    this.canCollectFees = false,
    super.key,
  });

  final ApiClient apiClient;
  final String token;
  final bool canCreateStudent;
  final bool canEditStudent;
  final bool canManageAttendance;
  final bool canManageSessions;
  final bool canCreateClass;
  final bool canEditClass;
  final bool canCreateSection;
  final bool canEditSection;
  final bool canPromoteStudent;
  final bool canTransferStudent;
  final bool canCollectFees;

  @override
  State<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen> {
  final _searchController = TextEditingController();
  final _studentScrollController = ScrollController();
  AcademicSummary? _summary;
  List<AcademicOption> _years = const [];
  List<AcademicOption> _levels = const [];
  List<AcademicOption> _sections = const [];
  List<StudentSummary> _students = const [];
  int? _yearId;
  int? _levelId;
  int? _sectionId;
  bool _loading = true;
  bool _studentLoading = false;
  bool _loadingMoreStudents = false;
  int _studentPage = 0;
  int _studentLastPage = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _studentScrollController.addListener(_onStudentScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _studentScrollController.dispose();
    super.dispose();
  }

  void _onStudentScroll() {
    if (_studentScrollController.position.pixels >=
            _studentScrollController.position.maxScrollExtent - 240 &&
        !_studentLoading &&
        !_loadingMoreStudents &&
        _studentPage < _studentLastPage) {
      _loadMoreStudents();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        widget.apiClient.academicSummary(widget.token),
        widget.apiClient.academicYears(widget.token),
        widget.apiClient.academicLevels(widget.token),
      ]);
      final summary = results[0] as AcademicSummary;
      final years = results[1] as List<AcademicOption>;
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _years = years;
        _levels = results[2] as List<AcademicOption>;
        _sections = const [];
        _yearId = summary.currentYear?.id;
      });
      await _loadStudents();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load academic data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _studentLoading = true);
    try {
      final result = await widget.apiClient.academicStudentsPage(
        widget.token,
        yearId: _yearId,
        levelId: _levelId,
        sectionId: _sectionId,
        search: _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _students = result.students;
          _studentPage = result.page;
          _studentLastPage = result.lastPage;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _studentLoading = false);
    }
  }

  Future<void> _loadMoreStudents() async {
    if (_studentPage >= _studentLastPage) return;
    setState(() => _loadingMoreStudents = true);
    try {
      final result = await widget.apiClient.academicStudentsPage(
        widget.token,
        yearId: _yearId,
        levelId: _levelId,
        sectionId: _sectionId,
        search: _searchController.text.trim(),
        page: _studentPage + 1,
      );
      if (mounted) {
        setState(() {
          _students = [..._students, ...result.students];
          _studentPage = result.page;
          _studentLastPage = result.lastPage;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loadingMoreStudents = false);
    }
  }

  Future<void> _selectLevel(int? levelId) async {
    setState(() {
      _levelId = levelId;
      _sectionId = null;
      _sections = const [];
      _studentLoading = true;
    });
    if (levelId == null) {
      await _loadStudents();
      return;
    }
    try {
      final sections = await widget.apiClient.academicSections(
        widget.token,
        levelId: levelId,
      );
      if (!mounted || _levelId != levelId) return;
      setState(() => _sections = sections);
      await _loadStudents();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _studentLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _summary == null) {
      return _AcademicError(message: _error!, onRetry: _loadInitial);
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView(
        controller: _studentScrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SummaryCards(summary: _summary!),
          if (widget.canManageSessions ||
              widget.canCreateClass ||
              widget.canEditClass ||
              widget.canCreateSection ||
              widget.canEditSection ||
              widget.canManageAttendance) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (widget.canManageSessions ||
                    widget.canCreateClass ||
                    widget.canEditClass ||
                    widget.canCreateSection ||
                    widget.canEditSection)
                  Expanded(
                    child: _AcademicAction(
                      title: 'Academic setup',
                      subtitle: 'Sessions & classes',
                      icon: Icons.grid_view_rounded,
                      onTap: _openAcademicSetup,
                    ),
                  ),
                if ((widget.canManageSessions ||
                        widget.canCreateClass ||
                        widget.canEditClass ||
                        widget.canCreateSection ||
                        widget.canEditSection) &&
                    widget.canManageAttendance)
                  const SizedBox(width: 10),
                if (widget.canManageAttendance)
                  Expanded(
                    child: _AcademicAction(
                      title: 'Attendance',
                      subtitle: 'Mark today’s class',
                      icon: Icons.fact_check_rounded,
                      onTap: _openAttendance,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Students',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (widget.canCreateStudent)
                FilledButton.icon(
                  onPressed: () => _openStudentForm(),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Add'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE3E9F7)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _loadStudents(),
                  decoration: InputDecoration(
                    hintText: 'Name, class, section, roll or registration',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Search',
                      onPressed: _loadStudents,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _FilterField(
                  label: 'Session',
                  value: _yearId,
                  options: _years,
                  onChanged: (value) {
                    setState(() => _yearId = value);
                    _loadStudents();
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FilterField(
                        key: ValueKey('class-filter-$_levelId'),
                        label: 'Class',
                        value: _levelId,
                        options: _levels,
                        onChanged: _selectLevel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FilterField(
                        label: 'Section',
                        value: _sectionId,
                        options: _sections,
                        onChanged: _levelId == null
                            ? null
                            : (value) {
                                setState(() => _sectionId = value);
                                _loadStudents();
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_studentLoading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_students.isEmpty)
            const _AcademicEmpty()
          else
            ..._students.map(
              (student) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StudentCard(
                  student: student,
                  onTap: () => _showStudent(student),
                ),
              ),
            ),
          if (_loadingMoreStudents)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _showStudent(StudentSummary student) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .78,
        minChildSize: .5,
        maxChildSize: .94,
        builder: (context, controller) => FutureBuilder<StudentDetails>(
          future: widget.apiClient.academicStudent(widget.token, student.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            return _StudentDetailsView(
              student: snapshot.requireData,
              controller: controller,
              canEdit: widget.canEditStudent,
              canPromote: widget.canPromoteStudent,
              canTransfer: widget.canTransferStudent,
              onFees: () => showStudentFeeCollection(
                context: context,
                apiClient: widget.apiClient,
                token: widget.token,
                studentId: snapshot.requireData.id,
                yearId: snapshot.requireData.cycles.first.yearId,
                canCollectFees: widget.canCollectFees,
                onCollected: () {
                  if (mounted) _loadInitial();
                },
              ),
              onEdit: () {
                Navigator.pop(context);
                _openStudentForm(snapshot.requireData).then((_) {
                  if (mounted) _showStudent(student);
                });
              },
              onPromote: () {
                Navigator.pop(context);
                _openPromotion(snapshot.requireData);
              },
              onTransfer: () {
                Navigator.pop(context);
                _openTransfer(snapshot.requireData);
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _openAcademicSetup() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AcademicSetupScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          canManageSessions: widget.canManageSessions,
          canCreateClass: widget.canCreateClass,
          canEditClass: widget.canEditClass,
          canCreateSection: widget.canCreateSection,
          canEditSection: widget.canEditSection,
        ),
      ),
    );
    if (changed == true && mounted) await _loadInitial();
  }

  Future<void> _openStudentForm([StudentDetails? student]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => StudentFormScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          years: _years,
          levels: _levels,
          student: student,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _loadInitial();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              student == null
                  ? 'Student created successfully.'
                  : 'Student updated successfully.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openPromotion(StudentDetails student) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => StudentPromotionScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          student: student,
          years: _years,
          levels: _levels,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _loadInitial();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student promoted successfully.')),
        );
      }
    }
  }

  Future<void> _openTransfer(StudentDetails student) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => StudentTransferScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          student: student,
          levels: _levels,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _loadInitial();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student transferred successfully.')),
        );
      }
    }
  }

  Future<void> _openAttendance() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => AttendanceScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          years: _years,
          levels: _levels,
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final AcademicSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF142B6F), Color(0xFF3567E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x203D5AF1),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -30,
            child: Icon(
              Icons.school_rounded,
              size: 126,
              color: Colors.white.withValues(alpha: .07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CAMPUS OVERVIEW',
                          style: TextStyle(
                            color: Color(0xFFE4EBFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          summary.currentYear?.name ?? 'Not selected',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Students',
                      value: summary.studentCount,
                      icon: Icons.groups_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      label: 'Classes',
                      value: summary.levelCount,
                      icon: Icons.school_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      label: 'Sections',
                      value: summary.sectionCount,
                      icon: Icons.account_tree_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 19),
          const SizedBox(height: 5),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFE4EBFF), fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AcademicAction extends StatelessWidget {
  const _AcademicAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFEDF3FF),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3567E9),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF526079)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<AcademicOption> options;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('All')),
        ...options.map(
          (option) => DropdownMenuItem<int?>(
            value: option.id,
            child: Text(option.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.onTap});

  final StudentSummary student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EBF4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEAF0FF),
              foregroundColor: const Color(0xFF294FBA),
              child: Text(
                student.name.isEmpty ? '?' : student.name[0].toUpperCase(),
              ),
            ),
            title: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${student.levelName} • ${student.sectionName} • Roll ${student.rollNo ?? '-'}\n${student.registrationNo}',
            ),
            isThreeLine: true,
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentDetailsView extends StatelessWidget {
  const _StudentDetailsView({
    required this.student,
    required this.controller,
    required this.canEdit,
    required this.canPromote,
    required this.canTransfer,
    required this.onEdit,
    required this.onPromote,
    required this.onTransfer,
    required this.onFees,
  });

  final StudentDetails student;
  final ScrollController controller;
  final bool canEdit;
  final bool canPromote;
  final bool canTransfer;
  final VoidCallback onEdit;
  final VoidCallback onPromote;
  final VoidCallback onTransfer;
  final VoidCallback onFees;

  @override
  Widget build(BuildContext context) {
    final currentCycle = student.cycles.isEmpty ? null : student.cycles.first;
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
      children: [
        _StudentProfileHeader(student: student, currentCycle: currentCycle),
        if (canEdit ||
            (canPromote && currentCycle != null) ||
            (canTransfer && currentCycle != null) ||
            currentCycle != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E7F0)),
            ),
            child: Row(
              children: [
                if (canEdit)
                  Expanded(
                    child: _StudentAction(
                      label: 'Edit',
                      icon: Icons.edit_rounded,
                      color: const Color(0xFF3567E9),
                      onTap: onEdit,
                    ),
                  ),
                if (canPromote && currentCycle != null)
                  Expanded(
                    child: _StudentAction(
                      label: 'Promote',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF0B8A72),
                      onTap: onPromote,
                    ),
                  ),
                if (canTransfer && currentCycle != null)
                  Expanded(
                    child: _StudentAction(
                      label: 'Transfer',
                      icon: Icons.swap_horiz_rounded,
                      color: const Color(0xFFD17A16),
                      onTap: onTransfer,
                    ),
                  ),
                if (currentCycle != null)
                  Expanded(
                    child: _StudentAction(
                      label: 'Fees',
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF0B9B8E),
                      onTap: onFees,
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        _StudentSection(
          title: 'Personal information',
          icon: Icons.badge_outlined,
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.translate_rounded,
                label: 'Bangla name',
                value: student.banglaName,
              ),
              _DetailRow(
                icon: Icons.cake_outlined,
                label: 'Date of birth',
                value: student.dob,
              ),
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Gender',
                value: student.gender,
              ),
              _DetailRow(
                icon: Icons.bloodtype_outlined,
                label: 'Blood group',
                value: student.bloodGroup,
              ),
              _DetailRow(
                icon: Icons.favorite_border_rounded,
                label: 'Religion',
                value: student.religion,
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _StudentSection(
          title: 'Contact details',
          icon: Icons.contact_phone_outlined,
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: student.phone,
              ),
              _DetailRow(
                icon: Icons.sms_outlined,
                label: 'SMS phone',
                value: student.smsPhone,
              ),
              _DetailRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: student.email,
              ),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Present address',
                value: student.address,
              ),
              _DetailRow(
                icon: Icons.home_outlined,
                label: 'Permanent address',
                value: student.permanentAddress,
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _StudentSection(
          title: 'Guardian information',
          icon: Icons.family_restroom_rounded,
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Father',
                value: student.fatherName,
              ),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Father phone',
                value: student.fatherPhone,
              ),
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Mother',
                value: student.motherName,
              ),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Mother phone',
                value: student.motherPhone,
                showDivider: false,
              ),
            ],
          ),
        ),
        if (student.cycles.isNotEmpty) ...[
          const SizedBox(height: 14),
          _StudentSection(
            title: 'Academic journey',
            icon: Icons.school_outlined,
            child: Column(
              children: student.cycles.indexed.map((entry) {
                final index = entry.$1;
                final cycle = entry.$2;
                return _AcademicHistoryItem(
                  cycle: cycle,
                  isCurrent: index == 0,
                  showLine: index < student.cycles.length - 1,
                );
              }).toList(),
            ),
          ),
        ],
        if (student.transferHistory.isNotEmpty) ...[
          const SizedBox(height: 14),
          _StudentSection(
            title: 'Transfer history',
            icon: Icons.route_outlined,
            child: Column(
              children: student.transferHistory.indexed.map((entry) {
                final index = entry.$1;
                final log = entry.$2;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < student.transferHistory.length - 1 ? 14 : 0,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${log.fromLevel} • ${log.fromSection}',
                          style: const TextStyle(color: Color(0xFF667085)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Icon(
                            Icons.south_rounded,
                            color: Color(0xFFD17A16),
                            size: 18,
                          ),
                        ),
                        Text(
                          '${log.toLevel} • ${log.toSection}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${log.year} • Roll ${log.fromRollNo ?? '-'} → ${log.toRollNo ?? '-'}'
                          '${log.transferredBy?.isNotEmpty == true ? '\nTransferred by ${log.transferredBy}' : ''}'
                          '${log.remarks?.isNotEmpty == true ? '\n${log.remarks}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _StudentProfileHeader extends StatelessWidget {
  const _StudentProfileHeader({required this.student, this.currentCycle});

  final StudentDetails student;
  final StudentCycle? currentCycle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF142B6F), Color(0xFF3567E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -24,
            child: Icon(
              Icons.school_rounded,
              size: 124,
              color: Colors.white.withValues(alpha: .06),
            ),
          ),
          Column(
            children: [
              Container(
                width: 74,
                height: 74,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x30000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  student.name.isEmpty ? '?' : student.name[0].toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF294FBA),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Text(
                student.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (student.banglaName?.isNotEmpty == true) ...[
                const SizedBox(height: 3),
                Text(
                  student.banglaName!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFE4EBFF)),
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'ID  ${student.registrationNo}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                  ),
                ),
              ),
              if (currentCycle != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_stories_rounded,
                        color: Color(0xFFB8D1FF),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${currentCycle!.level} • ${currentCycle!.section}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${currentCycle!.year} • Roll ${currentCycle!.rollNo ?? '-'}',
                              style: const TextStyle(
                                color: Color(0xFFE4EBFF),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF63DDB4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            color: Color(0xFF073E35),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentAction extends StatelessWidget {
  const _StudentAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentSection extends StatelessWidget {
  const _StudentSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E7F0)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            color: const Color(0xFFF5F7FC),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF3567E9), size: 20),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final hasValue = value?.trim().isNotEmpty == true;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF3567E9), size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasValue ? value! : 'Not provided',
                      style: TextStyle(
                        color: hasValue
                            ? const Color(0xFF172033)
                            : const Color(0xFF98A2B3),
                        fontWeight: hasValue
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(),
      ],
    );
  }
}

class _AcademicHistoryItem extends StatelessWidget {
  const _AcademicHistoryItem({
    required this.cycle,
    required this.isCurrent,
    required this.showLine,
  });

  final StudentCycle cycle;
  final bool isCurrent;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent ? const Color(0xFF3567E9) : const Color(0xFF98A2B3);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: .25),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
              if (showLine)
                Container(width: 2, height: 66, color: const Color(0xFFDDE3EF)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${cycle.level} • ${cycle.section}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (isCurrent)
                      const Text(
                        'Current',
                        style: TextStyle(
                          color: Color(0xFF3567E9),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${cycle.year} • Roll ${cycle.rollNo ?? '-'}'
                  '${cycle.group?.isNotEmpty == true ? ' • ${cycle.group}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AcademicEmpty extends StatelessWidget {
  const _AcademicEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.person_search_rounded, size: 48),
          SizedBox(height: 10),
          Text('No students match the selected filters.'),
        ],
      ),
    );
  }
}

class _AcademicError extends StatelessWidget {
  const _AcademicError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
