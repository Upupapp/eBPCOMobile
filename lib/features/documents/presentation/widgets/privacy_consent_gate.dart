import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Consent, taken once, before the app first collects a personal document.
///
/// RA 10173 requires consent to be informed, freely given, and specific to a
/// declared purpose, and obtained *before* collection. So this stands in front
/// of the first capture rather than being buried in a policy screen the
/// applicant is unlikely to open, and it states purpose, retention, and
/// recipients in the plainest terms the subject matter allows.
///
/// Once given it is not asked again. It can be withdrawn from Profile →
/// Privacy & Data, and the gate then reappears on the next capture.
Future<bool> ensurePrivacyConsent(
  BuildContext context, {
  LocalStorageService? storage,
  DateTime Function()? clock,
}) async {
  final store = storage ?? LocalStorageService();
  if (await store.privacyConsentAt() != null) return true;
  if (!context.mounted) return false;

  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const _ConsentDialog(),
  );

  if (agreed != true) return false;
  await store.recordPrivacyConsent((clock ?? DateTime.now)());
  return true;
}

class _ConsentDialog extends StatelessWidget {
  const _ConsentDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Before you attach a document'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Documents you attach may include personal information such as '
              'your name, address, and government ID.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            const _Point(
              icon: Icons.flag_outlined,
              title: 'Why',
              body:
                  'To complete and support your permit applications to the '
                  'Office of the Building Official.',
            ),
            const _Point(
              icon: Icons.phone_iphone_outlined,
              title: 'Where it is kept',
              body:
                  'Copies are stored in this app’s own storage on your device. '
                  'Nothing is sent anywhere until you attach it to an '
                  'application and submit.',
            ),
            const _Point(
              icon: Icons.share_outlined,
              title: 'Who receives it',
              body:
                  'Only the LGU offices reviewing your application — the '
                  'Office of the Building Official and the offices it refers '
                  'your application to.',
            ),
            const _Point(
              icon: Icons.delete_outline,
              title: 'Your control',
              body:
                  'You can view, export, and delete anything you import from '
                  'Profile → Privacy & Data at any time.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('I agree'),
        ),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Point({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.secondaryBlue),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.helper.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(body, style: AppTypography.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
