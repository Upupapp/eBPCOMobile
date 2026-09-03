import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// What an expired related Building Permit means for this filing.
///
/// Eleven wizard steps offer Approved / Pending / Expired for the Building
/// Permit an ancillary permit attaches to. They required a number for
/// Approved, and treated the other two identically — under a hint reading
/// "Optional while pending approval", which is simply untrue of an expired
/// permit. **Not one of the eleven mentioned `expired` anywhere.**
///
/// The two are not the same wait. A pending Building Permit is expected to be
/// approved and the ancillary permit issues after it; an expired one will not
/// become approved by waiting, and the citizen has to act. The confirmation
/// screen already tells them issuance depends on the Building Permit — at the
/// point where they say theirs has expired, the app said nothing.
///
/// A notice, not a refusal. The office decides what it will accept; this names
/// the consequence so the citizen is not waiting on something that cannot
/// happen.
class RelatedPermitNotice extends StatelessWidget {
  /// True when the citizen has said the related Building Permit has expired.
  final bool isExpired;

  const RelatedPermitNotice({super.key, required this.isExpired});

  @override
  Widget build(BuildContext context) {
    if (!isExpired) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            size: 16,
            color: AppColors.statusPending,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'An expired Building Permit will not be approved by waiting. '
              'This permit cannot be issued until it is renewed at the Office '
              'of the Building Official. You can still file now, so your '
              'papers are lodged, but nothing will move until then.',
              style: AppTypography.helper.copyWith(
                color: AppColors.statusPending,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
