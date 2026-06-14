import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/styles.dart';
import '../../widgets/language_dropdown_widget.dart';
import '../../widgets/theme_toggle_widget.dart';

const Color _profileDark = AppColors.authText;
const Color _profileMuted = AppColors.authTextMuted;
const Color _profileSurface = Colors.white;
const Color _profileBorder = Color(0xFFE2E8F0);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      context.read<AuthProvider>().loadProfileFromApi();
    });
  }

  Future<void> _refreshProfile() async {
    await context.read<AuthProvider>().loadProfileFromApi();
  }

  Color _accentColor(AuthProvider authProvider) {
    return authProvider.isEmployee ? AppColors.employee : AppColors.customer;
  }

  Future<void> _openEditProfileSheet(AuthProvider authProvider) async {
    final accentColor = _accentColor(authProvider);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditSheet(
        initialName: authProvider.displayName,
        initialEmail: authProvider.email ?? '',
        initialPhone: authProvider.currentEmployee?.phone ?? '',
        isEmployee: authProvider.isEmployee,
        accentColor: accentColor,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.edit_success'.tr()),
          backgroundColor: accentColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;
    final errorMessage = authProvider.errorMessage;
    final accentColor = _accentColor(authProvider);

    final String displayName = authProvider.displayName;
    final String? email = authProvider.email;
    final restaurantData = authProvider.restaurant;
    final String? restaurantName =
        restaurantData?['profile']?['name'] ?? restaurantData?['name'];

    final roleKey = authProvider.role ?? (authProvider.isCustomer ? 'customer' : 'staff');
    final roleLabel = 'dashboard.roles.$roleKey'.tr();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.dashboardBg : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? AppColors.dashboardHeader : _profileSurface;
    final titleColor = isDark ? AppColors.text : _profileDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'EasyEat',
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w900),
        ),
        actions: [
          const ThemeToggleWidget(),
          const LanguageDropdownWidget(),
          const SizedBox(width: 8),
        ],
      ),
      body: authProvider.isLoggedIn
          ? RefreshIndicator(
              onRefresh: _refreshProfile,
              color: accentColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHero(
                      accentColor: accentColor,
                      displayName: displayName,
                      email: email,
                      roleLabel: roleLabel,
                    ),
                    const SizedBox(height: 20),
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: accentColor.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      ),
                    if (errorMessage.isNotEmpty) ...[
                      _MessageBanner(
                        accentColor: Colors.redAccent,
                        icon: Icons.error_outline_rounded,
                        message: errorMessage,
                      ),
                      const SizedBox(height: 18),
                    ],
                    Text(
                      'dashboard.overview'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _profileDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ProfileDetailsCard(
                      accentColor: accentColor,
                      displayName: displayName,
                      email: email,
                      restaurantName: restaurantName,
                      isEmployee: authProvider.isEmployee,
                    ),
                    const SizedBox(height: 18),
                    _ProfileActionCard(
                      icon: Icons.edit_outlined,
                      title: 'profile.edit_profile'.tr(),
                      subtitle: authProvider.isEmployee
                          ? 'profile.edit_profile_employee'.tr()
                          : 'profile.edit_profile_customer'.tr(),
                      accentColor: accentColor,
                      onTap: () => _openEditProfileSheet(authProvider),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'dashboard.logout'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _profileDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LogoutActionCard(
                      label: 'dashboard.logout'.tr(),
                      onTap: () {
                        context.read<AuthProvider>().logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (_) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _MessageBanner(
                  accentColor: Colors.redAccent,
                  icon: Icons.person_off_outlined,
                  message: 'profile.error_session'.tr(),
                ),
              ),
            ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final Color accentColor;
  final String displayName;
  final String? email;
  final String roleLabel;

  const _ProfileHero({
    required this.accentColor,
    required this.displayName,
    required this.email,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final darkerAccent = Color.lerp(accentColor, Colors.black, 0.2) ?? accentColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, darkerAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'profile.title'.tr(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroChip(
                      icon: Icons.badge_outlined,
                      label: roleLabel.toUpperCase(),
                    ),
                    if (email != null && email!.isNotEmpty)
                      _HeroChip(
                        icon: Icons.email_outlined,
                        label: email!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  final Color accentColor;
  final String displayName;
  final String? email;
  final String? restaurantName;
  final bool isEmployee;

  const _ProfileDetailsCard({
    required this.accentColor,
    required this.displayName,
    required this.email,
    required this.restaurantName,
    required this.isEmployee,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _profileSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _profileBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.person_outline,
            label: 'profile.name'.tr(),
            value: displayName,
            iconColor: accentColor,
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.email_outlined,
            label: 'profile.email'.tr(),
            value: email?.isNotEmpty == true ? email! : '-',
            iconColor: accentColor,
          ),
          if (isEmployee) ...[
            const Divider(height: 1),
            _DetailRow(
              icon: Icons.restaurant_outlined,
              label: 'profile.restaurant'.tr(),
              value: restaurantName?.isNotEmpty == true
                  ? restaurantName!
                  : 'profile.not_assigned'.tr(),
              iconColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: _profileSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _profileBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _profileDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _profileMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _profileMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _profileDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditSheet extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final bool isEmployee;
  final Color accentColor;

  const _ProfileEditSheet({
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.isEmployee,
    required this.accentColor,
  });

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<AuthProvider>().updateProfile(
            name: _nameController.text,
            email: _emailController.text,
            phone: widget.isEmployee ? _phoneController.text : null,
          );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.edit_error'.tr(args: [e.toString().replaceAll('Exception: ', '')])),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: widget.accentColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'profile.edit_profile'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _profileDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.isEmployee
                        ? 'profile.edit_profile_employee'.tr()
                        : 'profile.edit_profile_customer'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: _profileMuted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('profile.name'.tr(), Icons.person_outline),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'profile.validation_name'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration('profile.email'.tr(), Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: widget.isEmployee ? TextInputAction.next : TextInputAction.done,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'profile.validation_email'.tr();
                      if (!text.contains('@') || !text.contains('.')) {
                        return 'profile.validation_email_invalid'.tr();
                      }
                      return null;
                    },
                  ),
                  if (widget.isEmployee) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration('profile.phone'.tr(), Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'profile.validation_phone'.tr();
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: Text('profile.cancel'.tr()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text('profile.save'.tr()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutActionCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LogoutActionCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _profileDark,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String message;

  const _MessageBanner({
    required this.accentColor,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
