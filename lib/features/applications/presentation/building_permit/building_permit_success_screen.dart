import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/building_permit_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/avatars/app_avatar.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../shared/widgets/cards/app_card.dart';

/// Shown right after "Submit Application for Assessment". The application
/// is not paid or approved yet — only submitted for the Office of the
/// Building Official to review.
class BuildingPermitSuccessScreen extends StatelessWidget {
  const BuildingPermitSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<BuildingPermitProvider>().draft;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPaddingHorizontal,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.maxFormWidth,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppAvatar(
                        size: 96,
                        icon: Icons.check_circle,
                        iconSize: 56,
                        backgroundColor: AppColors.statusApprovedBg,
                        foregroundColor: AppColors.statusApproved,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Application submitted!',
                        style: AppTypography.pageTitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Building Permit application has been submitted for '
                        'assessment. The Office of the Building Official will '
                        'review your application and required documents next.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMuted.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DetailRow(
                              label: 'Application Reference Number',
                              value: draft?.referenceNumber ?? '—',
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Submitted Date',
                              value: draft?.submittedDate != null
                                  ? dateFormat.format(draft!.submittedDate!)
                                  : '—',
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Status',
                              value: 'Submitted for Assessment',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: 'View Application Status',
                        onPressed: () => context.push(
                          '/applications/new/building-permit/status',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'Return to Applications',
                        onPressed: () => context.go('/app/applications'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodyStrong),
      ],
    );
  }
}
