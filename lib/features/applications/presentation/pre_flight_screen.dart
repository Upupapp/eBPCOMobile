import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/citizens_charter.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';

/// The gate before a permit wizard.
///
/// Three questions, asked before nine steps rather than during them. An
/// applicant without a locational clearance will be stopped by the office
/// whatever they type into step 4, and finding that out at step 7 — after an
/// evening of form-filling — is the experience this exists to prevent.
///
/// It never blocks. Someone may be mid-way through securing a clearance, or
/// may know something the app does not, so "Continue anyway" is always
/// available. The point is that they proceed informed.
class PreFlightScreen extends StatefulWidget {
  final String permitType;

  /// Where to go once the applicant chooses to proceed.
  final String wizardRoute;

  const PreFlightScreen({
    super.key,
    required this.permitType,
    required this.wizardRoute,
  });

  @override
  State<PreFlightScreen> createState() => _PreFlightScreenState();
}

class _PreFlightScreenState extends State<PreFlightScreen> {
  /// null = unanswered, so an untouched question is not treated as a "no".
  final Map<_Prerequisite, bool?> _answers = {
    for (final prerequisite in _Prerequisite.values) prerequisite: null,
  };

  bool get _allAnswered => !_answers.values.contains(null);
  Iterable<_Prerequisite> get _missing =>
      _answers.entries.where((e) => e.value == false).map((e) => e.key);

  @override
  Widget build(BuildContext context) {
    final charter = charterFor(widget.permitType);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Before you start')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          children: [
            Text(widget.permitType, style: AppTypography.pageTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Three quick questions. They take a minute and can save you an '
              'evening of form-filling.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xl),

            for (final prerequisite in _Prerequisite.values)
              _Question(
                prerequisite: prerequisite,
                answer: _answers[prerequisite],
                onAnswer: (value) =>
                    setState(() => _answers[prerequisite] = value),
              ),

            if (_missing.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _Guidance(missing: _missing.toList()),
            ],

            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: _missing.isEmpty
                  ? 'Start the application'
                  : 'Continue anyway',
              onPressed: _allAnswered
                  ? () => context.pushReplacement(widget.wizardRoute)
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Not yet — take me back',
              onPressed: () => Navigator.of(context).pop(),
            ),

            const SizedBox(height: AppSpacing.xl),
            Text(
              'You will need ${charter.requirements.length} documents in total. '
              'See the Citizen’s Charter for the full list and where to secure '
              'each one.',
              style: AppTypography.helper,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'View the full requirements',
              onPressed: () => context.push(
                '/charter/${Uri.encodeComponent(widget.permitType)}',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

/// The three things that most often stall an application before it starts.
enum _Prerequisite { locationalClearance, proofOfOwnership, designProfessional }

extension _PrerequisiteX on _Prerequisite {
  String get question {
    switch (this) {
      case _Prerequisite.locationalClearance:
        return 'Do you have your Locational or Zoning Clearance?';
      case _Prerequisite.proofOfOwnership:
        return 'Do you have proof of ownership, or the right to build?';
      case _Prerequisite.designProfessional:
        return 'Have you engaged a licensed architect or engineer?';
    }
  }

  String get why {
    switch (this) {
      case _Prerequisite.locationalClearance:
        return 'It confirms your project is allowed at this location, and the '
            'building permit cannot be issued without it.';
      case _Prerequisite.proofOfOwnership:
        return 'A Certified True Copy of the title, or a document showing your '
            'right to build if you are not the registered owner.';
      case _Prerequisite.designProfessional:
        return 'Your plans must be signed and dry-sealed by a licensed '
            'professional with a current PRC licence and PTR.';
    }
  }

  String get whereToSecure {
    switch (this) {
      case _Prerequisite.locationalClearance:
        return 'City or Municipal Planning and Development Office';
      case _Prerequisite.proofOfOwnership:
        return 'Land Registration Authority / Registry of Deeds, or your own '
            'deed of sale, lease, or owner’s consent';
      case _Prerequisite.designProfessional:
        return 'A PRC-licensed architect or engineer. Add them under Profile → '
            'Professionals so their details carry across every permit.';
    }
  }
}

class _Question extends StatelessWidget {
  final _Prerequisite prerequisite;
  final bool? answer;
  final ValueChanged<bool> onAnswer;

  const _Question({
    required this.prerequisite,
    required this.answer,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: answer == false ? AppColors.statusPending : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prerequisite.question, style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(prerequisite.why, style: AppTypography.bodyMuted),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Choice(
                  label: 'Yes',
                  selected: answer == true,
                  onTap: () => onAnswer(true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Choice(
                  label: 'Not yet',
                  selected: answer == false,
                  onTap: () => onAnswer(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppConstants.minTouchTarget,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: selected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Guidance extends StatelessWidget {
  final List<_Prerequisite> missing;

  const _Guidance({required this.missing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            missing.length == 1
                ? 'One thing to secure first'
                : '${missing.length} things to secure first',
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'You can still start the application — nothing is lost, and your '
            'draft is saved. It cannot be approved until these are in hand.',
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final prerequisite in missing)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: AppColors.statusPending,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      prerequisite.whereToSecure,
                      style: AppTypography.body,
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
