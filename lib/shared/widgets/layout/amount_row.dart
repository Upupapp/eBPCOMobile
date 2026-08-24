import 'package:flutter/material.dart';

import 'reflowing_row.dart';

/// A label on one side and a peso amount on the other, which drops the amount
/// onto its own line when the two cannot share one.
///
/// This is [ReflowingRow] named for the case it was built for, and the naming
/// carries the reason it cannot simply ellipsise. These are fee names and
/// centavo amounts on an Order of Payment the applicant pays against:
/// "Electrical fee" shortened to "E…" is useless, and a truncated peso figure
/// is worse than useless. So the pair reflows rather than shrinks.
class AmountRow extends StatelessWidget {
  final Widget label;
  final Widget amount;

  const AmountRow({super.key, required this.label, required this.amount});

  @override
  Widget build(BuildContext context) =>
      ReflowingRow(leading: label, trailing: amount);
}
