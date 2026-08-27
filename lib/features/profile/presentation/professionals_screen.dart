import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/professional_model.dart';
import '../../../core/providers/professionals_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import 'widgets/professional_form_sheet.dart';
import 'widgets/representative_form_sheet.dart';

/// The people attached to the applicant's projects: licensed professionals
/// who sign and seal, and representatives who may act on their behalf.
///
/// Both are held here rather than retyped into every wizard, which is also
/// what makes a lapsed PRC catchable before a filing is refused for it.
class ProfessionalsScreen extends StatelessWidget {
  const ProfessionalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfessionalsProvider>();
    // From the provider, not DateTime.now(): the tiles below render the same
    // expiry verdicts the provider computes, so both must be judging against
    // the same day or the list and the warnings can disagree.
    final now = provider.now;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Professionals & Representatives')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          children: [
            Text('Design professionals', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'The architect or engineer who signs and seals your plans. Their '
              'PRC licence and Professional Tax Receipt must be current on the '
              'day you file.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.md),

            if (provider.professionals.isEmpty)
              const _EmptyCard(
                icon: Icons.badge_outlined,
                message:
                    'No professionals yet. Add the architect or engineer for '
                    'your project so their details carry across every permit '
                    'you file.',
              )
            else
              for (final professional in provider.professionals)
                _ProfessionalTile(
                  professional: professional,
                  asOf: now,
                  onEdit: () => showProfessionalFormSheet(
                    context,
                    existing: professional,
                  ),
                  onRemove: () => _confirmRemove(
                    context,
                    name: professional.fullName,
                    onConfirm: () =>
                        provider.removeProfessional(professional.id),
                  ),
                ),

            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => showProfessionalFormSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add a professional'),
            ),

            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Authorised representatives',
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Someone who may file or claim on your behalf. They must present '
              'a notarised Special Power of Attorney and their own valid ID — '
              'a scan is not a substitute for the wet-signed original.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.md),

            if (provider.representatives.isEmpty)
              const _EmptyCard(
                icon: Icons.people_outline,
                message:
                    'No representatives yet. Add one only if someone else will '
                    'file or claim for you.',
              )
            else
              for (final representative in provider.representatives)
                _RepresentativeTile(
                  representative: representative,
                  asOf: now,
                  onEdit: () => showRepresentativeFormSheet(
                    context,
                    existing: representative,
                  ),
                  onRemove: () => _confirmRemove(
                    context,
                    name: representative.fullName,
                    onConfirm: () =>
                        provider.removeRepresentative(representative.id),
                  ),
                ),

            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => showRepresentativeFormSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add a representative'),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context, {
    required String name,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Remove $name?',
      message:
          'This removes them from this device. Applications you already filed '
          'naming them are unaffected.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed) onConfirm();
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message, style: AppTypography.bodyMuted)),
        ],
      ),
    );
  }
}

class _ProfessionalTile extends StatelessWidget {
  final ProfessionalModel professional;
  final DateTime asOf;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ProfessionalTile({
    required this.professional,
    required this.asOf,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');
    final expired = professional.isPrcExpired(asOf);
    final dueSoon = !expired && professional.prcNeedsAttention(asOf);
    final ptrStale = professional.isPtrStale(asOf);
    final flagged = expired || dueSoon || ptrStale;

    return _RecordCard(
      title: professional.fullName,
      subtitle: professional.discipline.label,
      flagged: flagged,
      onEdit: onEdit,
      onRemove: onRemove,
      children: [
        _Fact(
          label: 'PRC',
          value:
              '${professional.prcNumber} · valid to '
              '${format.format(professional.prcValidityDate)}',
        ),
        _Fact(
          label: 'PTR',
          value:
              '${professional.ptrNumber} · '
              '${format.format(professional.ptrDateIssued)}, '
              '${professional.ptrPlaceIssued}',
        ),
        if (expired)
          const _Flag(
            tone: AppColors.statusRejected,
            message:
                'This PRC licence has expired. Plans signed and sealed under '
                'it will be returned.',
          )
        else if (dueSoon)
          _Flag(
            tone: AppColors.statusPending,
            message:
                'PRC expires in ${professional.prcDaysRemaining(asOf)} days. '
                'Renew before your next filing.',
          ),
        if (ptrStale)
          const _Flag(
            tone: AppColors.statusPending,
            message:
                'This Professional Tax Receipt is from a previous year. A '
                'current-year PTR is required on a new filing.',
          ),
        if (!professional.hasCompleteCredentials)
          const _Flag(
            tone: AppColors.statusPending,
            message:
                'Copies of the PRC ID and PTR are not attached yet. Wizards '
                'will ask for them at filing time.',
          ),
      ],
    );
  }
}

class _RepresentativeTile extends StatelessWidget {
  final AuthorizedRepresentative representative;
  final DateTime asOf;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _RepresentativeTile({
    required this.representative,
    required this.asOf,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');
    final blocking = representative.blockingReason(asOf);

    return _RecordCard(
      title: representative.fullName,
      subtitle: representative.relationship,
      flagged: blocking != null,
      onEdit: onEdit,
      onRemove: onRemove,
      children: [
        if (representative.authorizedUntil != null)
          _Fact(
            label: 'Authorised to',
            value: format.format(representative.authorizedUntil!),
          ),
        if (blocking != null)
          _Flag(tone: AppColors.statusRejected, message: blocking)
        else
          const _Flag(
            tone: AppColors.statusApproved,
            message:
                'Ready to act. They must still bring the original notarised '
                'SPA and their ID when claiming.',
          ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool flagged;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final List<Widget> children;

  const _RecordCard({
    required this.title,
    required this.subtitle,
    required this.flagged,
    required this.onEdit,
    required this.onRemove,
    required this.children,
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
          color: flagged ? AppColors.statusPending : AppColors.border,
          width: flagged ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.cardTitle),
                    Text(subtitle, style: AppTypography.bodyMuted),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: AppTypography.helper)),
          Expanded(child: Text(value, style: AppTypography.body)),
        ],
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  final Color tone;
  final String message;

  const _Flag({required this.tone, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Text(message, style: AppTypography.helper.copyWith(color: tone)),
    );
  }
}
