import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/avatars/app_avatar.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Log out',
      message: 'Are you sure you want to log out of your E-BPCO account?',
      confirmLabel: 'Log Out',
      isDestructive: true,
    );
    if (!confirmed) return;
    if (!context.mounted) return;

    await context.read<AuthProvider>().logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingHorizontal,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    AppAvatar(
                      size: 80,
                      initials: user?.initials ?? 'U',
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'User',
                      style: AppTypography.sectionTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(user?.email ?? '', style: AppTypography.bodyMuted),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const _ProfileSectionTitle('Account'),
              _ProfileActionTile(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                onTap: () => context.push('/profile/edit'),
              ),
              _ProfileActionTile(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => context.push('/profile/change-password'),
              ),
              const SizedBox(height: 20),
              const _ProfileSectionTitle('Personal Information'),
              _ProfileTile(
                icon: Icons.person_outline,
                label: 'Full Name',
                value: user?.fullName ?? '-',
              ),
              _ProfileTile(
                icon: Icons.mail_outline,
                label: 'Email Address',
                value: user?.email ?? '-',
              ),
              _ProfileTile(
                icon: Icons.call_outlined,
                label: 'Mobile Number',
                value: (user?.mobileNumber.isNotEmpty ?? false)
                    ? user!.mobileNumber
                    : 'Not provided',
              ),
              const SizedBox(height: 20),
              const _ProfileSectionTitle('Settings'),
              _ProfileActionTile(
                icon: Icons.notifications_outlined,
                label: 'Notification Preferences',
                onTap: () => _showComingSoon(context),
              ),
              _ProfileActionTile(
                icon: Icons.language_outlined,
                label: 'Language',
                onTap: () => _showComingSoon(context),
              ),
              const SizedBox(height: 20),
              const _ProfileSectionTitle('Support & Legal'),
              _ProfileActionTile(
                icon: Icons.help_outline,
                label: 'Help and Support',
                onTap: () => _showComingSoon(context),
              ),
              _ProfileActionTile(
                icon: Icons.description_outlined,
                label: 'Terms and Conditions',
                onTap: () => _showComingSoon(context),
              ),
              _ProfileActionTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () => _showComingSoon(context),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: Text(
                  'Log Out',
                  style: AppTypography.button.copyWith(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This section will be available in a future update.'),
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  final String title;

  const _ProfileSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTypography.label.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        backgroundColor: AppColors.surfaceMuted,
        padding: const EdgeInsets.all(12),
        showBorder: false,
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.caption),
                  Text(
                    value,
                    style: AppTypography.bodyStrong,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppConstants.minTouchTarget,
          ),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: AppTypography.body),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
