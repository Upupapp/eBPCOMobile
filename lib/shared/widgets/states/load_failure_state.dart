import 'package:flutter/material.dart';

import '../buttons/secondary_button.dart';
import 'empty_state.dart';

/// Shown when a list could not be loaded — as distinct from a list that is
/// genuinely empty.
///
/// Every list screen used to render `isLoading ? spinner : isEmpty ? empty :
/// list`, which has no branch for failure. Before the providers were fixed a
/// failed load left the spinner up forever. After they were fixed it fell
/// through to the empty state, which is worse in one specific way: "You have
/// no applications yet" is a claim about the applicant's records, and making
/// it because a request timed out tells them something false about their own
/// filing.
///
/// So failure gets its own state, and it offers the one thing that might
/// actually help.
class LoadFailureState extends StatelessWidget {
  /// What could not be loaded, as it would read mid-sentence: "your
  /// applications", "your documents".
  final String what;

  final Future<void> Function() onRetry;

  const LoadFailureState({
    super.key,
    required this.what,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Could not load $what',
      message:
          'Check your internet connection and try again. Nothing you have '
          'already filed is affected.',
      action: SecondaryButton(label: 'Try Again', onPressed: onRetry),
    );
  }
}
