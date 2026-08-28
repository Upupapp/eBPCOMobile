import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/contract/permit_forms.dart';
import '../../../../core/models/application_lineage.dart';
import '../../../../core/models/application_model.dart';
import '../../../../core/providers/application_intent_provider.dart';
import '../../../../core/providers/applications_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../routes/wizard_routes.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../shared/widgets/states/error_state.dart';

/// Which of the two continuations this is.
enum ContinuationKind { renewal, amendment }

/// Starts a renewal or an amendment from the record it continues.
///
/// The app filed everything as New. Both lines have carried New / Renewal /
/// Amendment as an action since the first reconciliation, and every permit but
/// the Certificate of Occupancy expires at six or twelve months — so an
/// applicant whose permit was lapsing had one route open to them: the catalog,
/// where they would file a first-time application for work the office had
/// already approved.
///
/// This screen is deliberately thin. It does not re-ask what the office
/// already holds, and it does not invent a shorter requirements list, because
/// the LGU publishes none: the renewal requirements are the office's to state,
/// and guessing at them would send someone to the counter under-prepared. What
/// it does is name what is being continued, say plainly what carries forward
/// and what does not, put the official form and the charter one tap away, and
/// then hand the applicant to the same wizard the catalog would have opened —
/// with the action and the reference attached.
class ContinueApplicationScreen extends StatelessWidget {
  final String applicationId;
  final ContinuationKind kind;

  const ContinueApplicationScreen({
    super.key,
    required this.applicationId,
    required this.kind,
  });

  bool get _isRenewal => kind == ContinuationKind.renewal;

  @override
  Widget build(BuildContext context) {
    final application = context.watch<ApplicationsProvider>().byId(
      applicationId,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isRenewal ? 'Renew permit' : 'Amend application'),
      ),
      body: SafeArea(child: _body(context, application)),
    );
  }

  Widget _body(BuildContext context, ApplicationModel? application) {
    if (application == null) {
      return ErrorState(
        icon: Icons.help_outline,
        title: 'Application not found',
        message:
            'We could not find the application you are trying to '
            '${_isRenewal ? 'renew' : 'amend'}. Open it from your '
            'applications list and try again.',
      );
    }

    final permitTypeLabel = application.permitTypeLabel;
    final wizardRoute = permitTypeLabel == null
        ? null
        : wizardRouteForLabel(permitTypeLabel);

    // Renewing something that never became a permit is refiling, not renewing,
    // and saying so is more use than a button that files the wrong thing.
    final permitNumber =
        application.permitNumber ?? application.permit?.permitNumber;
    if (_isRenewal && permitNumber == null) {
      return const ErrorState(
        icon: Icons.pending_outlined,
        title: 'No permit to renew yet',
        message:
            'This application has not been issued as a permit, so there is '
            'nothing to renew. You can still follow its progress from your '
            'applications list.',
      );
    }

    if (wizardRoute == null || permitTypeLabel == null) {
      // The legacy Business Permit flow, and anything filed under a label the
      // catalog does not name.
      return const ErrorState(
        icon: Icons.description_outlined,
        title: 'Not available for this permit',
        message:
            'This permit was filed under an older flow that has no renewal or '
            'amendment path in the app. The Office of the Building Official '
            'can take it at the counter.',
      );
    }

    final form = permitFormForLabel(permitTypeLabel);

    return ListView(
      padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
      children: [
        Text(permitTypeLabel, style: AppTypography.pageTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _isRenewal
              ? 'Renewing permit $permitNumber, issued to '
                    '${application.businessName}.'
              : 'Amending application ${application.applicationNumber}, filed '
                    '${application.businessName}.',
          style: AppTypography.bodyMuted,
        ),

        if (_isRenewal && application.expiryDate != null) ...[
          const SizedBox(height: AppSpacing.md),
          _Panel(
            background: AppColors.statusPendingBg,
            title:
                'Valid until '
                '${_formatted(application.expiryDate!)}',
            body:
                'A renewal filed before this date keeps your permit '
                'continuous. This is separate from the deadline to start '
                'work.',
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        Text('What carries forward', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        // Only what the app actually holds on the record. Listing more would
        // be a promise about the office's own carry-forward that nobody here
        // is in a position to make.
        for (final line in [
          'The permit type: $permitTypeLabel',
          'The name on the record: ${application.businessName}',
          if (_isRenewal)
            'The permit being renewed: $permitNumber'
          else
            'The application being amended: '
                '${application.applicationNumber}',
        ])
          _Bullet(line),

        const SizedBox(height: AppSpacing.lg),
        Text('What you supply again', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        _Panel(
          background: AppColors.statusInfoBg,
          title: 'The office decides what it still needs',
          body: _isRenewal
              ? 'The Municipality of Castilla has not published a shorter '
                    'requirements list for renewals, so this app does not '
                    'invent one. Expect to be asked for the same documents '
                    'again, and ask the office which of them it will accept '
                    'from your original filing.'
              : 'An amendment is assessed against the same requirements as '
                    'the original. Supply the corrected details and any '
                    'document that has changed.',
        ),

        if (form != null) ...[
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: form.isOfficialCastillaForm
                ? 'View the official form'
                : 'View the reference form',
            onPressed: () =>
                context.push('/forms/${Uri.encodeComponent(permitTypeLabel)}'),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: 'View the full requirements',
          onPressed: () =>
              context.push('/charter/${Uri.encodeComponent(permitTypeLabel)}'),
        ),

        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: _isRenewal ? 'Start the renewal' : 'Start the amendment',
          onPressed: () {
            context.read<ApplicationIntentProvider>().start(
              _isRenewal
                  ? ApplicationLineage.renewal(
                      priorApplicationId: application.id,
                      priorPermitNumber: permitNumber!,
                      priorApplicationNumber: application.applicationNumber,
                      permitTypeLabel: permitTypeLabel,
                    )
                  : ApplicationLineage.amendment(
                      priorApplicationId: application.id,
                      priorApplicationNumber: application.applicationNumber,
                      permitTypeLabel: permitTypeLabel,
                    ),
            );
            context.push(wizardRoute);
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  static String _formatted(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check, size: 16, color: AppColors.statusApproved),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTypography.body)),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  final Color background;
  final String title;
  final String body;

  const _Panel({
    required this.background,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(body, style: AppTypography.helper),
      ],
    ),
  );
}
