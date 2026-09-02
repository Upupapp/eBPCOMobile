import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/contract/admin_vocabulary.dart';
import '../../../core/models/contact_verification.dart';
import '../../../core/providers/contact_verification_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';
import '../../../shared/widgets/layout/reflowing_row.dart';
import '../../../shared/widgets/text_fields/app_text_field.dart';

/// Verifying the details the office will use to reach the applicant.
///
/// Every notice about a permit goes to one of these two, and the applicant is
/// telephoned about an ocular inspection. The admin has modelled four statuses
/// and four methods since the first reconciliation; the app registered an
/// account and verified nothing, so the office had no way to know whether the
/// address it was writing to was one anybody read.
///
/// Two of the admin's four methods are offered here — the email link and the
/// mobile one-time code, which the applicant can drive themselves. The other
/// two happen at the office: a clerk confirming by hand, and matching against
/// an identity document already verified.
class ContactVerificationScreen extends StatefulWidget {
  const ContactVerificationScreen({super.key});

  @override
  State<ContactVerificationScreen> createState() =>
      _ContactVerificationScreenState();
}

class _ContactVerificationScreenState extends State<ContactVerificationScreen> {
  final Map<ContactChannel, TextEditingController> _codes = {
    for (final channel in ContactChannel.values)
      channel: TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in _codes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContactVerificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Contact verification')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          children: [
            Text(
              'The office sends every notice about your application to these '
              'details, and telephones you about inspections. Verifying them '
              'is how the office knows they reach you.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Said plainly, because the alternative is an applicant assuming
            // they cannot file. Whether verification ever becomes a
            // precondition is the LGU's decision, and it has not been taken.
            Text(
              'You can file, pay and claim a permit whether or not these are '
              'verified.',
              style: AppTypography.helper,
            ),

            if (provider.message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _Notice(outcome: provider.outcome, message: provider.message!),
            ],

            const SizedBox(height: AppSpacing.xl),
            for (final channel in provider.channels) ...[
              _ChannelCard(
                verification: channel,
                controller: _codes[channel.channel]!,
                busy: provider.isBusy,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            const SizedBox(height: AppSpacing.lg),
            Text(
              'Other ways the office verifies',
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Named rather than hidden: an applicant who cannot receive a code
            // — a shared number, a mailbox they have lost — needs to know
            // there is another route, and that it is at the counter.
            Text(
              'The Office of the Building Official can also confirm your '
              'details in person, or match them against an identity document '
              'you have already submitted. Ask at the counter if you cannot '
              'receive a code here.',
              style: AppTypography.helper,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final ContactVerification verification;
  final TextEditingController controller;
  final bool busy;

  const _ChannelCard({
    required this.verification,
    required this.controller,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ContactVerificationProvider>();
    final channel = verification.channel;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap rather than Row: at 2.0x text scale "Pending Verification"
          // and the channel name do not fit on one line, and the shared
          // ReflowingRow exists because Expanded-plus-a-wide-trailing-child
          // has overflowed here four times before.
          ReflowingRow(
            leading: Text(channel.label, style: AppTypography.cardTitle),
            trailing: ContactVerificationBadge(verification: verification),
          ),
          const SizedBox(height: 2),
          Text(
            verification.isMissing
                ? 'You have not given ${channel == ContactChannel.email ? 'an email address' : 'a mobile number'} yet. Add one from Edit Profile.'
                : verification.value,
            style: AppTypography.bodyMuted,
          ),

          if (verification.hasFailed && verification.failureReason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            // The reason, verbatim. "Failed" on its own leaves the applicant
            // to guess whether to try the same code again.
            Text(
              verification.failureReason!,
              style: AppTypography.helper.copyWith(
                color: AppColors.statusRejected,
              ),
            ),
          ],

          if (verification.isVerified) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Verified by ${verification.verifiedBy?.wire ?? 'the office'}.',
              style: AppTypography.helper,
            ),
          ] else if (!verification.isMissing) ...[
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: verification.isUnattempted
                  ? (channel == ContactChannel.email
                        ? 'Send verification link'
                        : 'Send code by SMS')
                  : 'Send it again',
              onPressed: busy ? null : () => provider.request(channel),
            ),

            // Asked for, but the office could send nothing. Said here rather
            // than only in the notice at the top, which scrolls away and
            // belongs to whichever channel was tapped last.
            if (verification.requestedButUndeliverable) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nothing was sent to you. The office cannot send these yet — '
                'ask at the counter to have it confirmed.',
                style: AppTypography.helper,
              ),
            ],

            // Gated on delivery, not on Pending. The office records the
            // request whether or not it could send anything, so Pending alone
            // put a "Code from the SMS" field under a code that did not exist.
            if (verification.awaitingCode || verification.hasFailed) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: controller,
                label: channel == ContactChannel.email
                    ? 'Code from the email'
                    : 'Code from the SMS',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: 'Confirm',
                onPressed: busy
                    ? null
                    : () => provider.confirm(channel, controller.text.trim()),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The channel's status, in the office's own words.
///
/// Shared with the Profile screen, which shows the same three states beside
/// the email address and the mobile number, so the two can never disagree
/// about what "Unverified" looks like.
class ContactVerificationBadge extends StatelessWidget {
  final ContactVerification verification;

  const ContactVerificationBadge({super.key, required this.verification});

  @override
  Widget build(BuildContext context) {
    final (Color colour, Color background) = switch (verification.status) {
      ContactVerificationStatus.verified => (
        AppColors.statusApproved,
        AppColors.statusApprovedBg,
      ),
      ContactVerificationStatus.pendingVerification => (
        AppColors.statusPending,
        AppColors.statusPendingBg,
      ),
      ContactVerificationStatus.verificationFailed => (
        AppColors.statusRejected,
        AppColors.statusRejectedBg,
      ),
      ContactVerificationStatus.unverified => (
        AppColors.textSecondary,
        AppColors.background,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: verification.isMissing ? AppColors.background : background,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Text(
        verification.label,
        style: AppTypography.helper.copyWith(
          color: verification.isMissing ? AppColors.textSecondary : colour,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final VerificationOutcome outcome;
  final String message;

  const _Notice({required this.outcome, required this.message});

  @override
  Widget build(BuildContext context) {
    final background = switch (outcome) {
      VerificationOutcome.rejected => AppColors.statusRejectedBg,
      VerificationOutcome.unavailable => AppColors.statusPendingBg,
      VerificationOutcome.queued => AppColors.statusInfoBg,
      VerificationOutcome.none => AppColors.statusInfoBg,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Text(message, style: AppTypography.body),
    );
  }
}
