import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/contract/admin_vocabulary.dart';
import '../../../core/models/contact_verification.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/contact_verification_provider.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/profile_photo_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/badges/status_badge.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/dialogs/permission_dialogs.dart';
import '../../../shared/widgets/layout/reflowing_row.dart';
import 'contact_verification_screen.dart';
import 'widgets/profile_photo_avatar.dart';
import 'widgets/profile_photo_bottom_sheet.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfilePhotoService _photoService = ProfilePhotoService();
  final PermissionService _permissionService = PermissionService();

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of your eBPCO account?',
      confirmLabel: 'Log Out',
      isDestructive: true,
    );
    if (!confirmed) return;
    if (!context.mounted) return;

    await context.read<AuthProvider>().logout();
    if (context.mounted) context.go('/login');
  }

  Future<void> _handleEditPhoto(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final hasPhoto = authProvider.currentUser?.photoPath != null;

    await showProfilePhotoOptions(
      context,
      hasPhoto: hasPhoto,
      onTakePhoto: () => _handleTakePhoto(context),
      onChooseFromGallery: () => _handleChooseFromGallery(context),
      onRemovePhoto: () => _handleRemovePhoto(context),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleTakePhoto(BuildContext context) async {
    final status = await requestPermissionWithPriming(
      context,
      permissionService: _permissionService,
      kind: AppPermissionKind.camera,
      primerTitle: cameraPermissionPrimerTitle,
      primerMessage: cameraPermissionPrimerMessage,
    );
    if (status != AppPermissionStatus.granted) {
      if (status == AppPermissionStatus.denied && context.mounted) {
        _showMessage(context, 'Camera permission is required.');
      }
      return;
    }
    if (!context.mounted) return;

    final result = await _photoService.takePhoto();
    if (!context.mounted) return;
    await _handlePhotoPickResult(context, result);
  }

  Future<void> _handleChooseFromGallery(BuildContext context) async {
    final status = await requestPermissionWithPriming(
      context,
      permissionService: _permissionService,
      kind: AppPermissionKind.photos,
      primerTitle: photosPermissionPrimerTitle,
      primerMessage: photosPermissionPrimerMessage,
    );
    if (status != AppPermissionStatus.granted) {
      if (status == AppPermissionStatus.denied && context.mounted) {
        _showMessage(context, 'Photo access is required.');
      }
      return;
    }
    if (!context.mounted) return;

    final result = await _photoService.chooseFromGallery();
    if (!context.mounted) return;
    await _handlePhotoPickResult(context, result);
  }

  Future<void> _handlePhotoPickResult(
    BuildContext context,
    ProfilePhotoPickResult result,
  ) async {
    switch (result.outcome) {
      case ProfilePhotoPickOutcome.success:
        await context.read<AuthProvider>().updateProfilePhoto(
          result.file!.path,
        );
        if (context.mounted) {
          _showMessage(context, 'Profile photo updated successfully.');
        }
      case ProfilePhotoPickOutcome.cancelled:
        // Leave the current photo untouched.
        break;
      case ProfilePhotoPickOutcome.invalidFile:
        _showMessage(context, 'Unsupported file format.');
      case ProfilePhotoPickOutcome.error:
        _showMessage(context, 'The selected file could not be opened.');
    }
  }

  Future<void> _handleRemovePhoto(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Remove Profile Photo?',
      message: 'Are you sure you want to remove your current profile photo?',
      confirmLabel: 'Remove Photo',
      isDestructive: true,
    );
    if (!confirmed) return;
    if (!context.mounted) return;

    await _photoService.removeSavedPhoto();
    if (!context.mounted) return;
    await context.read<AuthProvider>().updateProfilePhoto(null);
    if (context.mounted) {
      _showMessage(context, 'Profile photo removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final verification = context.watch<ContactVerificationProvider>();
    final dateFormat = DateFormat('MMM d, yyyy');

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
                    ProfilePhotoAvatar(
                      photoPath: user?.photoPath,
                      initials: user?.initials ?? 'U',
                      onEditTap: () => _handleEditPhoto(context),
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
              _ProfileActionTile(
                icon: Icons.folder_outlined,
                label: 'My Documents',
                subtitle: 'View and manage your imported documents',
                onTap: () => context.push('/profile/documents'),
              ),
              _ProfileActionTile(
                icon: Icons.badge_outlined,
                label: 'Professionals & Representatives',
                subtitle:
                    'Your architect or engineer, and anyone who may act for you',
                onTap: () => context.push('/profile/professionals'),
              ),
              _ProfileActionTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy & Data',
                subtitle: 'See what is held about you, and delete it',
                onTap: () => context.push('/profile/privacy-data'),
              ),
              _ProfileActionTile(
                icon: Icons.receipt_long_outlined,
                label: 'Citizen’s Charter',
                subtitle: 'Processing times, fees, and what to bring',
                // The office's own name for the permit, not the catalog card's
                // short one. `charterFor` is keyed on the canonical label, so
                // 'New Construction' missed and fell through to the generic
                // ancillary entry — which pledges 7 working days against the
                // Building Permit's real 20. Under RA 11032 that number is the
                // published service standard an applicant holds the office to,
                // so quoting the wrong one is not a display bug.
                onTap: () => context.push(
                  '/charter/'
                  '${Uri.encodeComponent(CanonicalPermitType.buildingPermitNewConstruction.wire)}',
                ),
              ),
              const SizedBox(height: 20),
              const _ProfileSectionTitle('Personal Information'),
              _ProfileTile(
                icon: Icons.person_outline,
                label: 'Full Name',
                value: user?.fullName ?? '-',
              ),
              // Per channel, because an account whose email is confirmed and
              // whose mobile number is not is a real and common state, and one
              // status for the pair could not say so.
              _ProfileTile(
                icon: Icons.mail_outline,
                label: 'Email Address',
                value: user?.email ?? '-',
                trailing: ContactVerificationBadge(
                  verification: verification.of(ContactChannel.email),
                ),
              ),
              _ProfileTile(
                icon: Icons.call_outlined,
                label: 'Mobile Number',
                value: (user?.mobileNumber.isNotEmpty ?? false)
                    ? user!.mobileNumber
                    : 'Not provided',
                trailing: ContactVerificationBadge(
                  verification: verification.of(ContactChannel.mobile),
                ),
              ),
              if (verification.actionable.isNotEmpty)
                _ProfileActionTile(
                  icon: Icons.verified_user_outlined,
                  label: 'Verify your contact details',
                  onTap: () => context.push('/profile/contact-verification'),
                ),
              _ProfileTile(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: (user?.fullAddress.isNotEmpty ?? false)
                    ? user!.fullAddress
                    : 'Not provided',
              ),
              _ProfileTile(
                icon: Icons.badge_outlined,
                label: 'Account Type',
                value: user?.accountType ?? '-',
              ),
              _ProfileStatusTile(
                icon: Icons.verified_user_outlined,
                label: 'Account Status',
                status: user?.accountStatus,
              ),
              _ProfileTile(
                icon: Icons.calendar_today_outlined,
                label: 'Registered Since',
                value: user?.registeredSince != null
                    ? dateFormat.format(user!.registeredSince!)
                    : 'Not available',
              ),
              const SizedBox(height: 20),
              const _ProfileSectionTitle('Settings'),
              _ProfileActionTile(
                icon: Icons.notifications_outlined,
                label: 'Notification Preferences',
                onTap: () => context.push('/profile/notifications'),
              ),
              _ProfileActionTile(
                icon: Icons.language_outlined,
                label: 'Language',
                onTap: () => context.push('/profile/language'),
              ),
              const SizedBox(height: 20),
              const _ProfileSectionTitle('Support & Legal'),
              _ProfileActionTile(
                icon: Icons.help_outline,
                label: 'Help and Support',
                onTap: () => context.push('/profile/help'),
              ),
              _ProfileActionTile(
                icon: Icons.description_outlined,
                label: 'Terms and Conditions',
                onTap: () => context.push('/profile/terms'),
              ),
              _ProfileActionTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () => context.push('/profile/privacy'),
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

  /// Sits at the end of the row. Used by the two contact channels to carry
  /// their verification status, which belongs beside the detail it describes
  /// rather than in a section of its own.
  final Widget? trailing;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
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
                  if (trailing == null)
                    Text(
                      value,
                      style: AppTypography.bodyStrong,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    // Inside the column rather than beside it: at 2.0x the
                    // badge alone is wider than the space an Expanded value
                    // leaves it, and it has to be able to drop onto its own
                    // line. Same reason ReflowingRow exists at all.
                    ReflowingRow(
                      leading: Text(
                        value,
                        style: AppTypography.bodyStrong,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: trailing!,
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

class _ProfileStatusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final AccountStatus? status;

  const _ProfileStatusTile({
    required this.icon,
    required this.label,
    required this.status,
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
              child: Text(
                label,
                style: AppTypography.caption,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (status != null)
              Flexible(
                child: StatusBadge(
                  label: status!.label,
                  color: status!.color,
                  backgroundColor: status!.backgroundColor,
                ),
              )
            else
              Text('-', style: AppTypography.bodyStrong),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.label,
    this.subtitle,
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
                child: subtitle == null
                    ? Text(label, style: AppTypography.body)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: AppTypography.body),
                          const SizedBox(height: 2),
                          Text(subtitle!, style: AppTypography.caption),
                        ],
                      ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
