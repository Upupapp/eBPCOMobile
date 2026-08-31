import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/contract/lgu_source_notice.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../cards/app_card.dart';

/// The conditions a permit will be issued subject to, shown before an
/// applicant commits to filing.
///
/// **Written for the two wizards that had nowhere to show them.** Excavation
/// and Sign both declare `permitConditions` and neither has an evaluation
/// step, so their lists rendered nowhere at all — which is how the excavation
/// permit's **cash bond** stayed invisible: more than 50 cubic metres and more
/// than 2 metres deep costs the owner fifty thousand pesos before they break
/// ground, and the app never said so.
///
/// Placed before the declaration rather than after it, because these are the
/// obligations the applicant is about to certify they understand. The other
/// nine wizards show the same list on their Evaluation & Permit Status step,
/// after submission — appropriate there, since that screen is about what the
/// office is doing. This one is about what the applicant is taking on.
///
/// [isReferenceForm] carries the same warning the form viewer does: three
/// permits ship a form the Municipality has not published, and one of them —
/// Sign — is signed by a **City** Building Official, which Castilla, a
/// municipality, cannot be.
class PermitConditionsCard extends StatelessWidget {
  final List<String> conditions;
  final bool isReferenceForm;

  const PermitConditionsCard({
    super.key,
    required this.conditions,
    this.isReferenceForm = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('What this permit will require of you',
            style: AppTypography.cardTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isReferenceForm
              ? LguSourceNotice.conditionsFromReferenceForm
              : 'These conditions will apply once the permit is issued. Read '
                    'them before you file — some of them cost money or time '
                    'before work can start.',
          style: AppTypography.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final condition in conditions) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(condition, style: AppTypography.body),
                    ),
                  ],
                ),
                if (condition != conditions.last)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
