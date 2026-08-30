import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/contract/office_contact.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/application_detail.dart';
import '../../../../core/models/application_model.dart';
import '../../../../core/providers/applications_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../shared/widgets/states/empty_state.dart';

/// The issued permit, plus how to claim the physical copy.
///
/// The downloaded copy is presentable: RA 8792 establishes functional
/// equivalence, so an electronic document cannot be denied legal effect
/// merely for being electronic. The verification reference is printed on the
/// face of it so anyone shown the permit can check it against the LGU rather
/// than having to take the screen at face value.
class DigitalPermitScreen extends StatelessWidget {
  final String applicationId;

  const DigitalPermitScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationsProvider>();
    final application = provider.byId(applicationId);
    final permit = application?.permit;

    if (application == null || permit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permit')),
        body: const EmptyState(
          icon: Icons.description_outlined,
          title: 'No permit yet',
          message:
              'Your permit appears here once the Building Official has '
              'approved your application and it has been generated.',
        ),
      );
    }

    final format = DateFormat('MMM d, yyyy');
    final release = application.release;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Permit')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          children: [
            _PermitFace(
              application: application,
              permit: permit,
              format: format,
            ),
            const SizedBox(height: AppSpacing.lg),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: permit.isAvailableOffline
                    ? AppColors.statusApprovedBg
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    permit.isAvailableOffline
                        ? Icons.offline_pin_outlined
                        : Icons.cloud_download_outlined,
                    size: 18,
                    color: permit.isAvailableOffline
                        ? AppColors.statusApproved
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      // `downloadPermit` sets a path and writes NO FILE — its
                      // own comment says it "stands in for writing the fetched
                      // PDF", and there is no server to fetch one from. Saying
                      // the permit is available without a connection is the
                      // costliest kind of false assurance: an applicant would
                      // rely on it at the counter, offline, with nothing to
                      // show. Honest until M-49 makes it true.
                      permit.isAvailableOffline
                          ? 'Marked for offline use. The file itself is not '
                                'saved yet — you will still need a connection '
                                'to show this permit.'
                          : 'Offline copies are not available yet. You will '
                                'need a connection to show this permit.',
                      style: AppTypography.helper,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (!permit.isAvailableOffline)
              PrimaryButton(
                label: 'Download permit',
                icon: Icons.download_outlined,
                onPressed: () async {
                  await provider.downloadPermit(applicationId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Marked for offline use. The file is not saved yet.',
                      ),
                    ),
                  );
                },
              )
            else
              SecondaryButton(
                label: 'Share a copy',
                icon: Icons.ios_share,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing opens your device’s share sheet.'),
                    ),
                  );
                },
              ),

            // Renewal, from the permit itself. TAB 09 gave this screen an
            // expiry date and TAB 13 gave it a notification; until now both
            // told the applicant their permit was running out and offered no
            // way to answer either. Shown only where the type actually
            // expires — a Certificate of Occupancy has nothing to renew.
            if (application.expiryDate != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Renew this permit',
                icon: Icons.autorenew,
                onPressed: () =>
                    context.push('/applications/$applicationId/renew'),
              ),
            ],

            if (release != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('Claim instructions', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.md),
              _ClaimInstructions(release: release),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _PermitFace extends StatelessWidget {
  final ApplicationModel application;
  final GeneratedPermit permit;
  final DateFormat format;

  const _PermitFace({
    required this.application,
    required this.permit,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.statusApproved, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (application.permitTypeLabel ?? application.type.label)
                .toUpperCase(),
            style: AppTypography.helper.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(permit.permitNumber, style: AppTypography.pageTitle),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'Issued', value: format.format(permit.issuedDate)),
          // Validity, not commencement — a different rule with a different
          // date. The catalog gives it per permit type: six months, twelve, or
          // none at all for a Certificate of Occupancy.
          _Row(
            label: 'Valid until',
            value: application.expiryDate == null
                ? 'No fixed expiry'
                : format.format(application.expiryDate!),
          ),
          _Row(label: 'Owner', value: application.businessName),
          if (permit.scope != null) _Row(label: 'Scope', value: permit.scope!),
          const Divider(height: AppSpacing.xl),

          // Expiry first when it is the nearer of the two. A Fencing Permit
          // is valid six months and must be commenced within twelve, so its
          // validity runs out first and putting commencement above it would
          // bury the date that actually matters.
          if (application.expiryApproaching(DateTime.now()))
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.statusRejectedBg,
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.expiredAsOf(DateTime.now())
                        ? 'This permit expired '
                              '${format.format(application.expiryDate!)}'
                        : 'This permit expires '
                              '${format.format(application.expiryDate!)}',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusRejected,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Validity is separate from the commencement deadline '
                    'below. Renew before this date if the work is not yet '
                    'complete.',
                    style: AppTypography.helper,
                  ),
                ],
              ),
            ),

          // PD 1096 voids a permit whose authorised work is not commenced
          // within one year, so this belongs on the face of the record and
          // not in a footnote.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.statusPendingBg,
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusSmall,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Work must commence by '
                  '${format.format(permit.commenceByDate)}',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Under PD 1096 a permit becomes null and void if the work '
                  'it authorises is not commenced within one year of issue, '
                  'or if the work is suspended or abandoned.',
                  style: AppTypography.helper,
                ),
              ],
            ),
          ),

          if (permit.conditions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Conditions',
              style: AppTypography.helper.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final condition in permit.conditions)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $condition', style: AppTypography.body),
              ),
          ],

          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusSmall,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification reference',
                  style: AppTypography.helper.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${permit.permitNumber} · ${application.applicationNumber}',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 2),
                Text(
                  'Verifiable with the Office of the Building Official that '
                  'issued it.',
                  style: AppTypography.helper,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 84, child: Text(label, style: AppTypography.helper)),
          Expanded(child: Text(value, style: AppTypography.body)),
        ],
      ),
    );
  }
}

class _ClaimInstructions extends StatelessWidget {
  final ReleaseRecord release;

  const _ClaimInstructions({required this.release});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (release.status == PermitReleaseStatus.released &&
              release.releasedAt != null) ...[
            Text(
              'Released ${format.format(release.releasedAt!)}'
              '${release.claimant != null ? ' to ${release.claimant}' : ''}',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // Where to claim. The backend omits this by design — the contract's
          // R-13 says the logistics values are LGU-specific and "omitted
          // rather than guessed" — so without a fallback this whole section
          // was a heading and the SPA paragraph, reached by an applicant the
          // app had just sent a push notification promising instructions.
          Text(
            'Where to claim',
            style: AppTypography.helper.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            release.claimLocation ?? ClaimProcedure.location,
            style: AppTypography.body,
          ),
          if (release.claimLocation == null) ...[
            const SizedBox(height: 2),
            Text(OfficeContact.addressPending, style: AppTypography.bodyMuted),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Office hours',
            style: AppTypography.helper.copyWith(fontWeight: FontWeight.w600),
          ),
          // Not invented. Philippine offices commonly open 8–5 on weekdays,
          // but "commonly" is not Castilla, and the hours are what an
          // applicant plans a trip around.
          Text(
            release.officeHours ?? OfficeContact.officeHoursPending,
            style: release.officeHours != null
                ? AppTypography.body
                : AppTypography.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          if (release.bringWithYou.isNotEmpty) ...[
            Text(
              'Bring with you',
              style: AppTypography.helper.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final item in release.bringWithYou)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $item', style: AppTypography.body),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
          // Step 3 of the checklist. Worth saying because this app models each
          // ancillary permit as its own application, so an applicant with six
          // of them has no reason to expect one visit.
          Text(ClaimProcedure.claimedTogether, style: AppTypography.body),
          const SizedBox(height: AppSpacing.xs),
          Text(ClaimProcedure.source, style: AppTypography.bodyMuted),
          const SizedBox(height: AppSpacing.md),
          if (release.claimLocation == null) ...[
            Text(
              'Call ${OfficeContact.phone} or email ${OfficeContact.email} '
              'to confirm before you travel.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusSmall,
              ),
            ),
            child: Text(
              'Someone else may claim on your behalf only as an authorised '
              'representative, presenting a notarised Special Power of '
              'Attorney and their own valid ID.',
              style: AppTypography.bodyMuted,
            ),
          ),
        ],
      ),
    );
  }
}
