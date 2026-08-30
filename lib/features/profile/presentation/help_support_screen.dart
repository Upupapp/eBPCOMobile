import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/alerts/app_alert.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/layout/section_header.dart';
import '../../../core/contract/office_contact.dart';

const _faqs = [
  (
    question: 'How do I apply for a building permit?',
    answer:
        'Go to the Applications tab, choose the project type that matches '
        'your construction, and follow the step-by-step form. You can save '
        'your progress as a draft at any point.',
  ),
  (
    question: 'How long does application processing take?',
    answer:
        'Processing time depends on the Office of the Building Official\'s '
        'evaluation of your application and submitted documents. You can '
        'track your application\'s status from the Applications tab.',
  ),
  (
    question: 'Can I edit my application after submitting it?',
    answer:
        'Submitted applications cannot be edited directly. If corrections '
        'are needed, the evaluating office will contact you with '
        'instructions on how to proceed.',
  ),
  (
    question: 'What payment methods are supported?',
    answer:
        'Pay Onsite and Bank Transfer are supported once your application '
        'has been assessed. Full online payment integration is planned for '
        'a future release.',
  ),
  (
    question: 'Is my personal information secure?',
    answer:
        'This prototype uses mock data only and does not transmit '
        'information to a live server. See the Privacy Policy for details '
        'on how a production version would handle your data.',
  ),
];

/// Static FAQ + contact reference page. "Contact Support" and "Send
/// Feedback" are mock actions — there is no live support channel behind
/// them in this prototype.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _showMockAction(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help and Support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          children: [
            const AppAlert(
              variant: AppAlertVariant.info,
              message:
                  'This feature is currently available as a prototype for '
                  'demonstration purposes.',
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Frequently Asked Questions'),
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    for (final faq in _faqs)
                      ExpansionTile(
                        title: Text(
                          faq.question,
                          style: AppTypography.bodyStrong,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        expandedAlignment: Alignment.centerLeft,
                        iconColor: AppColors.primary,
                        collapsedIconColor: AppColors.textMuted,
                        children: [
                          Text(
                            faq.answer,
                            style: AppTypography.bodyMuted.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Contact Information'),
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContactRow(
                    icon: Icons.access_time_outlined,
                    label: 'Office Hours',
                    value: 'Monday to Friday, 8:00 AM – 5:00 PM',
                  ),
                  SizedBox(height: AppSpacing.md),
                  SizedBox(height: AppSpacing.md),
                  // The phone number, the email address and the office address
                  // that used to sit here were all fabricated, and all pointed
                  // at Quezon City rather than Sorsogon. See OfficeContact.
                  _ContactRow(
                    icon: Icons.account_balance_outlined,
                    label: 'Office',
                    value:
                        '${OfficeContact.office} — '
                        '${OfficeContact.engineeringOffice}, '
                        '${OfficeContact.localGovernment}',
                  ),
                  SizedBox(height: AppSpacing.md),
                  _ContactRow(
                    icon: Icons.language_outlined,
                    label: 'Website',
                    value: OfficeContact.website,
                  ),
                  SizedBox(height: AppSpacing.md),
                  _ContactRow(
                    icon: Icons.call_outlined,
                    label: 'Phone',
                    value:
                        '${OfficeContact.phone} — replies '
                        '${OfficeContact.replyPledge}',
                  ),
                  SizedBox(height: AppSpacing.md),
                  _ContactRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: OfficeContact.email,
                  ),
                  SizedBox(height: AppSpacing.md),
                  // Provenance beside the details. An applicant deciding
                  // whether to trust a number is owed where it came from, and
                  // this app printed an invented one until yesterday.
                  _ContactRow(
                    icon: Icons.verified_outlined,
                    label: 'Where these came from',
                    value: OfficeContact.contactSource,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Contact Support',
              icon: Icons.support_agent_outlined,
              onPressed: () => _showMockAction(
                context,
                'This would open a support request in a live version of the app.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Send Feedback',
              icon: Icons.feedback_outlined,
              onPressed: () => _showMockAction(
                context,
                'Thanks! Feedback submission is a mock action in this prototype.',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'Version 1.0 Prototype',
                style: AppTypography.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.bodyStrong),
            ],
          ),
        ),
      ],
    );
  }
}
