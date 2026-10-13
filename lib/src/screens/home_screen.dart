import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/dashboard_data.dart';
import '../services/api_client.dart';
import 'academic_screen.dart';
import 'accounts_screen.dart';
import 'fees_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.apiClient,
    required this.token,
    required this.onLoggedOut,
    super.key,
  });

  final ApiClient apiClient;
  final String token;
  final VoidCallback onLoggedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  bool _loading = true;
  String? _error;
  AppUser? _user;
  DashboardData? _dashboard;

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
        widget.apiClient.me(widget.token),
        widget.apiClient.dashboard(widget.token),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as AppUser;
        _dashboard = results[1] as DashboardData;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        widget.onLoggedOut();
        return;
      }
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load app data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await widget.apiClient.logout(widget.token);
    } finally {
      widget.onLoggedOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Academic', 'Fees', 'Accounts', 'Profile'];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ADMIN WORKSPACE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(titles[_tabIndex]),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (_user != null)
            Padding(
              padding: const EdgeInsets.only(left: 2, right: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _tabIndex = 4),
                child: CircleAvatar(
                  radius: 19,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    _user!.fullName.isEmpty
                        ? '?'
                        : _user!.fullName[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _body(),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE3E9F2))),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A172033),
              blurRadius: 20,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (index) => setState(() => _tabIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school_rounded),
              label: 'Academic',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Fees',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance_rounded),
              label: 'Accounts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading && _dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _dashboard == null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    return switch (_tabIndex) {
      0 => _DashboardTab(
        dashboard: _dashboard!,
        onRefresh: _load,
        onNavigate: (index) => setState(() => _tabIndex = index),
      ),
      1 => AcademicScreen(
        apiClient: widget.apiClient,
        token: widget.token,
        canCreateStudent: _user!.canCreateStudent,
        canEditStudent: _user!.canEditStudent,
        canManageAttendance: _user!.canManageAttendance,
        canManageSessions: _user!.canManageSessions,
        canCreateClass: _user!.canCreateClass,
        canEditClass: _user!.canEditClass,
        canCreateSection: _user!.canCreateSection,
        canEditSection: _user!.canEditSection,
        canPromoteStudent: _user!.canPromoteStudent,
        canTransferStudent: _user!.canTransferStudent,
        canCollectFees: _user!.canCollectFees,
      ),
      2 => FeesScreen(
        apiClient: widget.apiClient,
        token: widget.token,
        canCollectFees: _user!.canCollectFees,
        canCreatePurpose: _user!.canCreateFeePurpose,
        canEditPurpose: _user!.canEditFeePurpose,
        canDeletePurpose: _user!.canDeleteFeePurpose,
        canCreateTemplate: _user!.canCreateFeeTemplate,
        canEditTemplate: _user!.canEditFeeTemplate,
        canDeleteTemplate: _user!.canDeleteFeeTemplate,
      ),
      3 => AccountsScreen(
        apiClient: widget.apiClient,
        token: widget.token,
        canCreateDeposit: _user!.canCreateDeposit,
        canCreateWithdrawal: _user!.canCreateWithdrawal,
        canCreateTransfer: _user!.canCreateTransfer,
        canCreateAccount: _user!.canCreateAccount,
        canEditAccount: _user!.canEditAccount,
        canDeleteAccount: _user!.canDeleteAccount,
        canCreatePurpose: _user!.canCreateAccountPurpose,
        canEditPurpose: _user!.canEditAccountPurpose,
        canDeletePurpose: _user!.canDeleteAccountPurpose,
      ),
      _ => _ProfileTab(user: _user!, onLogout: _logout),
    };
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.dashboard,
    required this.onRefresh,
    required this.onNavigate,
  });

  final DashboardData dashboard;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF263AA8), Color(0xFF4F6CF7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x263D5AF1),
                  blurRadius: 26,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned(
                  right: -42,
                  top: -58,
                  child: _HeroOrb(size: 170, opacity: .10),
                ),
                const Positioned(
                  right: 52,
                  bottom: -52,
                  child: _HeroOrb(size: 116, opacity: .08),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'SCHOOL MANAGEMENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        dashboard.greeting,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dashboard.siteName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Text('Workspace', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text(
                'Quick access',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WorkspaceShortcut(
                  label: 'Academic',
                  caption: 'Students',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF3D5AF1),
                  background: const Color(0xFFEEF1FF),
                  onTap: () => onNavigate(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WorkspaceShortcut(
                  label: 'Fees',
                  caption: 'Collection',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF0B9B8E),
                  background: const Color(0xFFE8F8F5),
                  onTap: () => onNavigate(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WorkspaceShortcut(
                  label: 'Accounts',
                  caption: 'Finance',
                  icon: Icons.account_balance_rounded,
                  color: const Color(0xFFD27B13),
                  background: const Color(0xFFFFF4DD),
                  onTap: () => onNavigate(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Important summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Students',
                  value: dashboard.studentCount.toString(),
                  icon: Icons.school_rounded,
                  color: const Color(0xFF3D5AF1),
                  background: const Color(0xFFEEF1FF),
                  onTap: () => onNavigate(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Accounts',
                  value: dashboard.accountCount.toString(),
                  icon: Icons.account_balance_rounded,
                  color: const Color(0xFFD27B13),
                  background: const Color(0xFFFFF4DD),
                  onTap: () => onNavigate(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryMetric(
            label: 'Fees collected this month',
            value: _money(dashboard.feesCollectedThisMonth),
            icon: Icons.payments_rounded,
            color: const Color(0xFF0B9B8E),
            background: const Color(0xFFE8F8F5),
            onTap: () => onNavigate(2),
          ),
          const SizedBox(height: 24),
          _ClassStudentChart(data: dashboard.studentsByClass),
        ],
      ),
    );
  }
}

class _ClassStudentChart extends StatelessWidget {
  const _ClassStudentChart({required this.data});

  final List<ClassStudentCount> data;

  @override
  Widget build(BuildContext context) {
    final maxCount = data.fold<int>(
      0,
      (max, item) => item.studentCount > max ? item.studentCount : max,
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E9F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: Color(0xFF3D5AF1)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Students by class',
                  style: TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Text(
                'Current session',
                style: TextStyle(color: Color(0xFF667085), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (data.isEmpty)
            const Text(
              'No class-wise student data available.',
              style: TextStyle(color: Color(0xFF667085)),
            )
          else
            ...data.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  children: [
                    SizedBox(
                      width: 78,
                      child: Text(
                        item.className,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF344054),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: maxCount == 0
                              ? 0
                              : item.studentCount / maxCount,
                          backgroundColor: const Color(0xFFEEF1FF),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF4F6CF7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 28,
                      child: Text(
                        item.studentCount.toString(),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
      border: Border.all(color: Colors.white.withValues(alpha: opacity)),
    ),
  );
}

class _WorkspaceShortcut extends StatelessWidget {
  const _WorkspaceShortcut({
    required this.label,
    required this.caption,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String label;
  final String caption;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 10, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 13),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: color),
          ],
        ),
      ),
    ),
  );
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.user, required this.onLogout});

  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF172033), Color(0xFF344267)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x20172033),
                blurRadius: 26,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .18),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  user.fullName.isEmpty
                      ? '?'
                      : user.fullName.substring(0, 1).toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (user.roles.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.roles.first.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Account details', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _ProfileRow(
                icon: Icons.badge_outlined,
                label: 'Role',
                value: user.roles.join(', '),
              ),
              _ProfileRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email,
              ),
              _ProfileRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user.phone,
              ),
              _ProfileRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: user.address,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label, this.value});

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value?.isNotEmpty == true ? value! : 'Not provided'),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(double value) => '৳${value.toStringAsFixed(2)}';
