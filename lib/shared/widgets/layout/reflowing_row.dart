import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Two things that sit at opposite ends of a line and move onto separate
/// lines — rather than shrinking — when the line is too short to hold both.
///
/// The obvious spelling is `Row(children: [Expanded(a), b])`, and it is wrong
/// in a specific way that keeps recurring here. `Row` sizes the unbounded
/// child first, at whatever width it wants, and hands `Expanded` the
/// remainder. When `b` is wide — a long peso amount, a "Forgot password?"
/// button, a status label — the remainder can be a few pixels, and `a`
/// overflows. Widening the test viewport hides it; a narrow phone or a raised
/// system font size brings it back.
///
/// [Wrap] makes the decision instead, which keeps this free of a text-scale
/// threshold to tune and get wrong: the trailing item moves to a second run
/// exactly when it does not fit beside the leading one, at any scale and any
/// width. [leading] is bounded to the incoming width so a long one wraps
/// inside the row rather than pushing past it.
///
/// [leading] should size to its content — a `Row` or `Column` with
/// `MainAxisSize.min` — since one that always fills the width would push
/// [trailing] onto a second line unconditionally.
class ReflowingRow extends StatelessWidget {
  final Widget leading;
  final Widget trailing;

  const ReflowingRow({
    super.key,
    required this.leading,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: leading,
          ),
          trailing,
        ],
      ),
    );
  }
}
