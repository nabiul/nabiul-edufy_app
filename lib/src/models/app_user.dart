class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.roles,
    required this.abilities,
    this.email,
    this.phone,
    this.address,
  });

  final int id;
  final String fullName;
  final String username;
  final String? email;
  final String? phone;
  final String? address;
  final List<String> roles;
  final Map<String, bool> abilities;

  bool get canCollectFees => abilities['collect_fees'] ?? false;
  bool get canCreateDeposit => abilities['create_deposit'] ?? false;
  bool get canCreateWithdrawal => abilities['create_withdrawal'] ?? false;
  bool get canCreateTransfer => abilities['create_transfer'] ?? false;
  bool get canCreateFeePurpose => abilities['create_fee_purpose'] ?? false;
  bool get canEditFeePurpose => abilities['edit_fee_purpose'] ?? false;
  bool get canDeleteFeePurpose => abilities['delete_fee_purpose'] ?? false;
  bool get canCreateFeeTemplate => abilities['create_fee_template'] ?? false;
  bool get canEditFeeTemplate => abilities['edit_fee_template'] ?? false;
  bool get canDeleteFeeTemplate => abilities['delete_fee_template'] ?? false;
  bool get canManageFees =>
      canCreateFeePurpose ||
      canEditFeePurpose ||
      canDeleteFeePurpose ||
      canCreateFeeTemplate ||
      canEditFeeTemplate ||
      canDeleteFeeTemplate;
  bool get canCreateAccount => abilities['create_account'] ?? false;
  bool get canEditAccount => abilities['edit_account'] ?? false;
  bool get canDeleteAccount => abilities['delete_account'] ?? false;
  bool get canCreateAccountPurpose =>
      abilities['create_account_purpose'] ?? false;
  bool get canEditAccountPurpose => abilities['edit_account_purpose'] ?? false;
  bool get canDeleteAccountPurpose =>
      abilities['delete_account_purpose'] ?? false;
  bool get canManageAccounts =>
      canCreateAccount ||
      canEditAccount ||
      canDeleteAccount ||
      canCreateAccountPurpose ||
      canEditAccountPurpose ||
      canDeleteAccountPurpose;
  bool get canCreateStudent => abilities['create_student'] ?? false;
  bool get canEditStudent => abilities['edit_student'] ?? false;
  bool get canManageAttendance => abilities['manage_attendance'] ?? false;
  bool get canManageSessions => abilities['manage_sessions'] ?? false;
  bool get canCreateClass => abilities['create_class'] ?? false;
  bool get canEditClass => abilities['edit_class'] ?? false;
  bool get canCreateSection => abilities['create_section'] ?? false;
  bool get canEditSection => abilities['edit_section'] ?? false;
  bool get canPromoteStudent => abilities['promote_student'] ?? false;
  bool get canTransferStudent => abilities['transfer_student'] ?? false;
  bool get canManageAcademicSetup =>
      canManageSessions ||
      canCreateClass ||
      canEditClass ||
      canCreateSection ||
      canEditSection;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int,
    fullName: json['full_name'] as String? ?? '',
    username: json['username'] as String? ?? '',
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    roles: (json['roles'] as List<dynamic>? ?? const [])
        .map((role) => role.toString())
        .toList(),
    abilities: (json['abilities'] as Map<String, dynamic>? ?? const {}).map(
      (key, value) => MapEntry(key, value == true),
    ),
  );
}
