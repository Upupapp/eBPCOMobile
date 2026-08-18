import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/documents_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';

/// The Data Privacy Act rights, made operational.
///
/// RA 10173 gives a data subject rights to be informed, to access, to correct,
/// to object, and to erase. Most apps describe those rights in a policy
/// document and provide no way to exercise them. Each control here does the
/// thing it names, and where the app genuinely cannot act — anything already
/// submitted to the LGU — it says so plainly instead of implying otherwise.
class PrivacyDataScreen extends StatelessWidget {
  const PrivacyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final documents = context.watch<DocumentsProvider>();
    final storedCount = documents.allDocuments.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Privacy & Data')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What this app holds about you',
                    style: AppTypography.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your name, mobile number, and email; the businesses and '
                    'properties you file under; the documents you import; and '
                    'the applications you submit. Documents you import are '
                    'copied into this app’s own storage on your device and are '
                    'sent nowhere until you attach them to an application.',
                    style: AppTypography.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Your rights', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.md),

            _RightTile(
              icon: Icons.visibility_outlined,
              title: 'Access what is held',
              body:
                  '$storedCount document(s) are stored on this device. Open My '
                  'Documents to see every one, when it was imported, and where '
                  'it has been used.',
              actionLabel: 'Open My Documents',
              onTap: () => Navigator.of(context).pushNamed('/profile/documents'),
            ),
            const _RightTile(
              icon: Icons.edit_outlined,
              title: 'Correct what is wrong',
              body:
                  'Edit your profile to correct your name, mobile number, or '
                  'email. Details already submitted with an application are '
                  'corrected through the Office of the Building Official, not '
                  'here.',
            ),
            const _RightTile(
              icon: Icons.download_outlined,
              title: 'Take a copy',
              body:
                  'Every document you imported can be previewed and shared '
                  'from My Documents, so you always hold your own copy.',
            ),
            _RightTile(
              icon: Icons.delete_outline,
              title: 'Delete what you imported',
              body:
                  'Removing a document deletes the file from this device as '
                  'well as the record of it.',
              actionLabel: storedCount == 0 ? null : 'Delete all documents',
              destructive: true,
              onTap: storedCount == 0
                  ? null
                  : () => _confirmDeleteAll(context, storedCount),
            ),

            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.statusPendingBg,
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What deleting here cannot reach',
                    style: AppTypography.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Anything already submitted with an application is held by '
                    'the Office of the Building Official as part of a public '
                    'record, and deleting it from this device does not remove '
                    'it from theirs. To ask the LGU to correct or erase what '
                    'they hold, contact their Data Protection Officer.',
                    style: AppTypography.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context, int count) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete all documents?',
      message:
          'This removes $count document(s) and their files from this device. '
          'Documents you already submitted with an application stay with the '
          'Office of the Building Official.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    await context.read<DocumentsProvider>().removeAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Documents deleted from this device.')),
    );
  }
}

class _RightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onTap;
  final bool destructive;

  const _RightTile({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = destructive ? AppColors.statusRejected : AppColors.secondaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: tone),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(body, style: AppTypography.bodyMuted),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: tone,
                  minimumSize: const Size(0, AppConstants.minTouchTarget),
                ),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
