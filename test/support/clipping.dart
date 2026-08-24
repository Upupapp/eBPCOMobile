import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds text that does not fit inside a fixed-height box.
///
/// This exists because of a defect no overflow test could see. The bottom
/// navigation bar pinned itself to `height: 88`, and at 2.0x text scale
/// "Applications" wrapped to a second line and ran 4dp past the bottom of the
/// bar — on every primary screen at once. Six render tests at three scales
/// passed while it happened, because nothing overflowed a `Flex`: the label
/// simply extended beyond the box that was supposed to contain it, and got cut
/// off in the paint.
///
/// `expect(tester.takeException(), isNull)` cannot catch that. Only comparing
/// the text's rectangle against its container's can.
///
/// The check is deliberately about **height only**. A fixed-height box holding
/// a horizontally scrolling list is a normal, correct thing — the application
/// list's segment strip is one — and its content is meant to run off the sides.
/// What is never correct is content taller than the box it is pinned inside,
/// because no amount of scrolling reveals it.
///
/// Boxes with no text inside are skipped, which is what keeps this quiet: the
/// hundreds of `SizedBox(height: 8)` spacers hold nothing and never report.

/// A box that pins its height, and so can cut off text that grows.
typedef _FixedBox = ({Finder finder, String description, Rect rect});

List<_FixedBox> _fixedHeightBoxes(WidgetTester tester) {
  final boxes = <_FixedBox>[];

  void collect(Finder finder, String Function(Widget) describe) {
    for (final element in finder.evaluate()) {
      final byWidget = find.byWidget(element.widget);
      // A widget appearing more than once cannot be measured by identity.
      if (byWidget.evaluate().length != 1) continue;
      final rect = tester.getRect(byWidget);
      if (rect.height <= 0 || !rect.height.isFinite) continue;
      boxes.add((
        finder: byWidget,
        description: describe(element.widget),
        rect: rect,
      ));
    }
  }

  collect(
    find.byWidgetPredicate((w) => w is SizedBox && w.height != null),
    (w) => 'SizedBox(height: ${(w as SizedBox).height})',
  );
  collect(
    find.byWidgetPredicate(
      (w) => w is Container && w.constraints?.hasTightHeight == true,
    ),
    (w) => 'Container(height: ${(w as Container).constraints!.maxHeight})',
  );
  collect(
    find.byWidgetPredicate((w) => w is NavigationBar && w.height != null),
    (w) => 'NavigationBar(height: ${(w as NavigationBar).height})',
  );
  // An AppBar pins itself to kToolbarHeight (56dp) unless told otherwise, and
  // that height does not grow with the text scale. A long title at 2.0x is
  // exactly the shape that gets cut off without reporting anything.
  collect(
    find.byType(AppBar),
    (w) => 'AppBar(toolbarHeight: ${(w as AppBar).toolbarHeight ?? 56})',
  );

  return boxes;
}

/// Fails if any text is taller than a fixed-height box it sits inside.
void expectNoTextClippedByFixedHeight(
  WidgetTester tester, {
  required String context,
}) {
  final problems = <String>[];

  for (final box in _fixedHeightBoxes(tester)) {
    final texts = find.descendant(
      of: box.finder,
      matching: find.byType(Text),
      skipOffstage: true,
    );

    for (final element in texts.evaluate()) {
      final widget = element.widget as Text;
      final label = widget.data ?? widget.textSpan?.toPlainText() ?? '';
      if (label.isEmpty) continue;

      final byWidget = find.byWidget(widget);
      if (byWidget.evaluate().length != 1) continue;

      final rect = tester.getRect(byWidget);
      if (rect.height <= 0) continue;

      final overTop = box.rect.top - rect.top;
      final overBottom = rect.bottom - box.rect.bottom;
      final worst = overTop > overBottom ? overTop : overBottom;

      // Half a pixel of slack: rects land on subpixel boundaries at some
      // scale factors, and a rounding difference is not a clipped label.
      if (worst > 0.5) {
        problems.add(
          '$context: "$label" needs ${worst.toStringAsFixed(1)}dp more than '
          'its ${box.description} allows '
          '(text ${rect.top.toStringAsFixed(1)}–${rect.bottom.toStringAsFixed(1)}, '
          'box ${box.rect.top.toStringAsFixed(1)}–${box.rect.bottom.toStringAsFixed(1)})',
        );
      }
    }
  }

  expect(
    problems,
    isEmpty,
    reason:
        'Text is being cut off by a box that pins its height. This does not '
        'raise an overflow error — the text just does not render.\n  '
        '${problems.join('\n  ')}',
  );
}
