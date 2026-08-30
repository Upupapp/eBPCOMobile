import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/citizens_charter.dart';
import '../../../core/models/permit_classification.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/contract/lgu_source_notice.dart';

/// The LGU's Citizen's Charter entry for one permit service.
///
/// RA 11032 obliges every agency to publish what a service costs, how long it
/// takes, and what the applicant must bring. Putting it in the app is what
/// turns that from a poster in a lobby into something an applicant can hold
/// the office to.
class CitizensCharterScreen extends StatelessWidget {
  final String permitType;

  const CitizensCharterScreen({super.key, required this.permitType});

  @override
  Widget build(BuildContext context) {
    final entry = charterFor(permitType);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Citizen’s Charter')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          children: [
            Text(entry.permitType, style: AppTypography.pageTitle),
            const SizedBox(height: AppSpacing.md),

            _Panel(
              tone: AppColors.lightBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.classification.label} · '
                    '${entry.pledgedWorkingDays} working days',
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.secondaryBlueDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LguSourceNotice.pledgeIsStatutory,
                    style: AppTypography.bodyMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Where this screen's content actually comes from. It is titled
            // with the name of a document the LGU is required to publish, and
            // until Castilla's own is supplied (M-08) the offices, the
            // where-to-secure column and the fee basis are a national
            // compilation. An applicant makes trips on that column.
            _Panel(
              tone: AppColors.surfaceMuted,
              child: Text(
                LguSourceNotice.charterProvenance,
                style: AppTypography.bodyMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Fees', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(entry.feeBasis, style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'The exact amount appears on your Order of Payment once the '
              'office has assessed your application.',
              style: AppTypography.helper,
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Offices involved', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            for (final office in entry.offices)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.account_balance_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(office, style: AppTypography.body)),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),

            Text('What to bring', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Each requirement shows where to secure it.',
              style: AppTypography.bodyMuted,
            ),
            if (!LguSourceNotice.isConfirmedForPermit(permitType)) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                LguSourceNotice.unconfirmedRequirements,
                style: AppTypography.helper,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            for (final requirement in entry.requirements)
              _RequirementTile(requirement: requirement),

            const SizedBox(height: AppSpacing.xl),
            _Panel(
              tone: AppColors.statusPendingBg,
              child: Text(
                'If the office has not acted within the period above, you may '
                'raise it with the Office of the Building Official and, if it '
                'remains unresolved, with the Anti-Red Tape Authority.',
                style: AppTypography.body,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Color tone;
  final Widget child;

  const _Panel({required this.tone, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: child,
    );
  }
}

class _RequirementTile extends StatelessWidget {
  final CharterRequirement requirement;

  const _RequirementTile({required this.requirement});

  @override
  Widget build(BuildContext context) {
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
          Text(requirement.item, style: AppTypography.body),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.place_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  requirement.whereToSecure,
                  style: AppTypography.helper,
                ),
              ),
            ],
          ),
          if (requirement.requiresNotarisation) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.statusPendingBg,
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusPill,
                ),
              ),
              child: Text(
                'Wet-signed notarised original required',
                style: AppTypography.helper.copyWith(
                  color: AppColors.statusPending,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
