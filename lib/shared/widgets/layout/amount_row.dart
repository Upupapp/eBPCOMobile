import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// A label on one side and a peso amount on the other, which drops the amount
/// onto its own line when the two cannot share one.
///
/// A plain `Row` of `Expanded(label)` and an unbounded amount is the obvious
/// way to write this, and it is what the order of payment and payment history
/// screens both did. It fails the same way in both: the amount is laid out
/// first at its natural width, so at 200% text scale it takes almost the whole
/// line and the label is handed what is left — three and a half pixels, in the
/// case that surfaced this. The label then overflows.
///
/// Ellipsising instead would be worse. These are fee names and centavo amounts
/// on a document the applicant pays against; "Electrical fee" abbreviated to
/// "E…" and a truncated peso figure are both useless, and money in particular
/// must never be shortened. So the pair reflows rather than shrinks.
///
/// [Wrap] does the deciding, which keeps it free of a text-scale threshold:
/// the amount moves to a second run exactly when it does not fit beside the
/// label, at any scale and any width. The label is bounded to the incoming
/// width so that a long one wraps within the row instead of pushing past it.
///
/// Labels passed here should size to their content — a `Row` or `Column` with
/// `MainAxisSize.min` — since a label that always fills the width would push
/// the amount to a second line unconditionally.
class AmountRow extends StatelessWidget {
  final Widget label;
  final Widget amount;

  const AmountRow({super.key, required this.label, required this.amount});

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
            child: label,
          ),
          amount,
        ],
      ),
    );
  }
}
