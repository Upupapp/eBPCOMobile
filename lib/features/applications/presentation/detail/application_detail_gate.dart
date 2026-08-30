import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/applications_provider.dart';

/// Fetches the full record before a screen that needs it is read.
///
/// **The promise and its destination are fed by different payloads, and this
/// is where they are made to agree.**
///
/// The Home action stack is computed from scalars a LIST payload carries —
/// `openInstructionCount`, `lifecycleStatus` — so the app promises "3 items
/// must be corrected" and offers "View instructions". Everything those
/// promises point at lives in sub-objects the list may omit: `instructions`,
/// `evaluations`, `permit`, `release`, `inspection`, `payment`. The contract
/// keeps `GET /applications/{id}` as a separate operation described as "One
/// application **in full**" for exactly that reason, and
/// `ApplicationDto.parse` already noted that "a summary payload may omit the
/// letters themselves".
///
/// Every one of those destinations is behind a null guard. So the app could
/// send an applicant to a screen with nothing on it, and go on telling them
/// three things needed correcting.
///
/// `HttpApplicationsRepository.fetchDetail` existed the whole time and could
/// not be called: the interface every caller holds did not declare it.
///
/// **Applied at the router, not in five screens.** Four of these screens —
/// the letter, the permit, the outcome and the Order of Payment — are also
/// reachable directly from a push notification's deep link, without passing
/// through the detail screen, so a fetch on the detail screen alone would
/// leave four ways in uncovered.
class ApplicationDetailGate extends StatefulWidget {
  final String applicationId;
  final Widget child;

  const ApplicationDetailGate({
    super.key,
    required this.applicationId,
    required this.child,
  });

  @override
  State<ApplicationDetailGate> createState() => _ApplicationDetailGateState();
}

class _ApplicationDetailGateState extends State<ApplicationDetailGate> {
  @override
  void initState() {
    super.initState();
    // Deferred past the first frame: `loadDetail` notifies its listeners, and
    // a notify during build throws. The provider itself guards against a
    // repeat, so the rebuild this triggers does not fetch again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ApplicationsProvider>().loadDetail(widget.applicationId);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
