import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/notifications/notification_evaluator.dart';
import '../../../core/providers/draft_registry.dart';
import '../../../core/providers/notifications_provider.dart';

/// Main app shell with a bottom navigation bar. Tab state is preserved via
/// go_router's [StatefulShellRoute.indexedStack], which keeps each branch's
/// navigator (and its widget tree) alive across tab switches.
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    // Once per session, after the first frame so every wizard provider is
    // mounted. An idle draft is a nudge, not a live ticker — re-evaluating on
    // every tab change would cost more than it tells anyone.
    WidgetsBinding.instance.addPostFrameCallback((_) => _nudgeIdleDrafts());
  }

  void _nudgeIdleDrafts() {
    if (!mounted) return;
    final drafts = DraftRegistry.summaries(context);
    if (drafts.isEmpty) return;
    context.read<NotificationsProvider>().recordDerived(
      const NotificationEvaluator().evaluate(
        applications: const [],
        drafts: drafts,
        asOf: DateTime.now(),
      ),
    );
  }

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No top SafeArea here: screens without an AppBar (e.g. Dashboard's
      // HeroHeader) render full-bleed and apply their own top inset;
      // AppBar-based screens already position themselves below the status
      // bar via Scaffold, so this was previously a redundant wrapper.
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          // 88dp — slightly over Material 3's 80dp default — holds one line
          // of label at 1.0x with room for a second if a narrow device wraps
          // one. It does not hold two lines of scaled-up label: at 2.0x on a
          // 320dp screen "Applications" wraps and ran 4dp past the bottom of
          // the bar. NavigationBar clips rather than reporting an overflow,
          // so that failed silently, on every primary screen at once, and
          // only a test asserting the label's rect against the bar's caught
          // it.
          //
          // So the bar grows with the text scale rather than staying put.
          // Bounded at 2x because that is where the app clamps scaling, and
          // an unbounded bar would eventually leave no room for the screen
          // above it.
          height:
              88 *
              MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Applications',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments),
              label: 'Payments',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
