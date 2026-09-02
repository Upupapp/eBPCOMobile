import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/application_detail.dart';
import '../../../../core/providers/applications_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/states/empty_state.dart';

/// The Letter of Instruction — the LGU's itemised list of what must be
/// corrected before an application can proceed.
///
/// Every item carries the evaluator's verbatim remark and its own resolve
/// action, and Resubmit stays disabled until all of them are addressed. The
/// alternative — one "resubmit" button against an unstructured block of
/// remarks — is how applicants end up resubmitting incomplete corrections and
/// collecting a second Letter of Instruction for the same defect.
class LetterOfInstructionScreen extends StatelessWidget {
  final String applicationId;

  const LetterOfInstructionScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationsProvider>();
    final application = provider.byId(applicationId);
    final letter =
        application?.openInstruction ?? application?.instructions.firstOrNull;

    if (application == null || letter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Letter of Instruction')),
        body: const EmptyState(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Nothing outstanding',
          message:
              'There is no open Letter of Instruction on this application.',
        ),
      );
    }

    final format = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Letter of Instruction')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(
                  AppConstants.screenPaddingHorizontal,
                ),
                children: [
                  _Header(
                    letter: letter,
                    issuedOn: format.format(letter.issuedAt),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'What must be corrected',
                    style: AppTypography.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final item in letter.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _InstructionTile(
                        item: item,
                        onToggle: () => provider.toggleInstructionItem(
                          applicationId,
                          letter.id,
                          item.id,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusSmall,
                      ),
                    ),
                    child: Text(
                      'Your design professional receives the same Letter of '
                      'Instruction. Coordinate with them before resubmitting '
                      'so corrected plans and documents are filed together.',
                      style: AppTypography.bodyMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(
                AppConstants.screenPaddingHorizontal,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    letter.isFullyResolved
                        ? 'All items addressed. You can resubmit.'
                        : '${letter.openCount} of ${letter.items.length} '
                              'item(s) still outstanding.',
                    style: AppTypography.helper,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: 'Resubmit application',
                    icon: Icons.send_outlined,
                    onPressed: letter.isFullyResolved
                        ? () => _resubmit(context, provider)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sends the corrections, and says so only once they are sent.
  ///
  /// This method used to be synchronous: it called the provider without
  /// awaiting it, announced "Corrections submitted. The OBO will re-evaluate
  /// your application", and popped. The provider made no request at all, so
  /// the sentence was never true — and once the screen was popped and the
  /// action item cleared, the citizen had nothing left to tell them the office
  /// was still waiting on them.
  Future<void> _resubmit(
    BuildContext context,
    ApplicationsProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await provider.resubmitAfterInstruction(applicationId);
    } catch (_) {
      // Stay on the screen. The corrections are still ticked, the letter is
      // still open, and the citizen can try again — which is the whole
      // difference between this and being told it was done.
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not send your corrections. Check your connection and try '
            'again — the office has not received them yet.',
          ),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Corrections submitted. The OBO will re-evaluate your application.',
        ),
      ),
    );
    navigator.pop();
  }
}

class _Header extends StatelessWidget {
  final LetterOfInstruction letter;
  final String issuedOn;

  const _Header({required this.letter, required this.issuedOn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.statusPending),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_late_outlined,
                color: AppColors.statusPending,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Issued $issuedOn', style: AppTypography.cardTitle),
              ),
            ],
          ),
          if (letter.issuedBy != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('By ${letter.issuedBy}', style: AppTypography.helper),
          ],
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusPill),
            child: LinearProgressIndicator(
              value: letter.progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation(
                AppColors.statusApproved,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${letter.resolvedCount} of ${letter.items.length} addressed',
            style: AppTypography.helper,
          ),
        ],
      ),
    );
  }
}

class _InstructionTile extends StatelessWidget {
  final InstructionItem item;
  final VoidCallback onToggle;

  const _InstructionTile({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppConstants.minTouchTarget,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusMedium,
            ),
            border: Border.all(
              color: item.isResolved
                  ? AppColors.statusApproved
                  : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.isResolved
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 22,
                color: item.isResolved
                    ? AppColors.statusApproved
                    : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.subject, style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.xs),
                    // Verbatim evaluator remark — the applicant's instruction.
                    Text(item.remark, style: AppTypography.body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
