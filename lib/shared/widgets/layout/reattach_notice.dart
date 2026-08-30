import 'package:flutter/material.dart';

// ignore: unused_import — referenced from the doc comment above.
import 'wizard_progress_header.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// What a resumed draft could not give back, said on the screen where the
/// slots are.
///
/// M-48 keeps an applicant's typing and, since attachments were copied into
/// the app's own storage, their files too. It cannot keep a file that was
/// never in our storage, or one the applicant has cleared since — and the
/// Drafts row names those. But the Drafts row is where they *chose* the draft,
/// not where they *fill it in*: an applicant who resumes into step 7 sees
/// empty slots on a step they remember finishing, and nothing on that screen
/// says why.
///
/// Dismissible on purpose. It is an explanation, not an error — the applicant
/// may well re-attach later, and a banner that cannot be closed becomes
/// furniture the eye stops reading.
///
/// **Bounded, for the reason [WizardProgressHeader] records.** This sits in the
/// same Column, above an `Expanded(PageView)`, so anything unbounded here
/// takes space from the form itself. Twenty-four document names at 200% text
/// scale overflowed by 2,741 pixels and would have left the applicant unable
/// to reach the fields — measured, not guessed, and caught before it shipped.
///
/// So the names are capped and ellipsised while the COUNT is not: an applicant
/// always learns how many are missing, and the Drafts row, which scrolls,
/// carries the full list.
class ReattachNotice extends StatelessWidget {
  const ReattachNotice({
    super.key,
    required this.documents,
    required this.onDismiss,
  });

  /// The documents by name, in the order the wizard holds them.
  final List<String> documents;

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const SizedBox.shrink();
    final one = documents.length == 1;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppConstants.screenPaddingHorizontal,
        AppSpacing.sm,
        AppConstants.screenPaddingHorizontal,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.attach_file_outlined,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  one
                      ? 'One file was not kept with this draft'
                      : '${documents.length} files were not kept with this '
                            'draft',
                  // Full contrast: the amber does not reach AA on this
                  // background, and the icon already carries the tone.
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  // The count survives truncation. It is the part that tells
                  // an applicant whether they are missing one file or twenty.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Please attach ${one ? 'it' : 'them'} again: '
                  '${documents.join(', ')}.',
                  style: AppTypography.body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Dismiss',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
