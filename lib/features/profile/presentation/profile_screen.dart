import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/confirmation_dialog.dart';

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
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryNavy,
                      child: Text(
                        user?.initials ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'User',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
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
                label: const Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.error),
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
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryNavy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
                child: Text(label, style: const TextStyle(fontSize: 14.5)),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
