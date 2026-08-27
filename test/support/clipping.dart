import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds text that is being cut off rather than laid out.
///
/// This exists because of a defect no overflow test could see. The bottom
/// navigation bar pinned itself to `height: 88`, and at 2.0x text scale
/// "Applications" wrapped to a second line and ran 4dp past the bottom of the
/// bar — on every primary screen at once. Six render tests at three scales
/// passed while it happened, because nothing overflowed a `Flex`: the label
/// simply extended beyond the box meant to contain it and was cut off in the
/// paint.
///
/// `expect(tester.takeException(), isNull)` cannot catch that. Only comparing
/// the text's rectangle against its container's can.
///
/// Two shapes are checked, and they differ in which axes matter.

/// Something that can cut a child off, and the rectangle it cuts to.
typedef _Clipper = ({
  Finder finder,
  String description,
  Rect rect,
  bool heightOnly,
});

/// Boxes that pin their height.
///
/// **Height only, deliberately.** A fixed-height box holding a horizontally
/// scrolling list is normal and correct — the application list's segment strip
/// is one — and its content is meant to run off the sides. Content *taller*
/// than the box it is pinned inside is never correct, because no amount of
/// scrolling reveals it.
///
/// Boxes with no text inside are skipped, which is what keeps this quiet: the
/// hundreds of `SizedBox(height: 8)` spacers hold nothing and never report.
List<_Clipper> _fixedHeightBoxes(WidgetTester tester) {
  final boxes = <_Clipper>[];

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
        heightOnly: true,
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
  // that height does not grow with the text scale. Measured at 2.0x: Material
  // keeps the title to one line and ellipsises sideways, so it is 37dp inside
  // 56dp. Not a risk today, covered so it stays that way.
  collect(
    find.byType(AppBar),
    (w) => 'AppBar(toolbarHeight: ${(w as AppBar).toolbarHeight ?? 56})',
  );

  return boxes;
}

/// Widgets that clip their children outright, on both axes.
///
/// Unlike a fixed-height box, these cut sideways too, so width counts. A
/// `Stack` is included only when its `clipBehavior` actually clips — which is
/// the default, and is easy to forget when positioning a badge near an edge.
List<_Clipper> _clippers(WidgetTester tester) {
  final clippers = <_Clipper>[];

  void collect(Finder finder, String Function(Widget) describe) {
    for (final element in finder.evaluate()) {
      if (_isScrollMachinery(element)) continue;
      final byWidget = find.byWidget(element.widget);
      if (byWidget.evaluate().length != 1) continue;
      final rect = tester.getRect(byWidget);
      if (rect.isEmpty || !rect.width.isFinite || !rect.height.isFinite) {
        continue;
      }
      clippers.add((
        finder: byWidget,
        description: describe(element.widget),
        rect: rect,
        heightOnly: false,
      ));
    }
  }

  collect(find.byType(ClipRect), (_) => 'ClipRect');
  collect(find.byType(ClipRRect), (_) => 'ClipRRect');
  collect(find.byType(ClipPath), (_) => 'ClipPath');
  collect(find.byType(ClipOval), (_) => 'ClipOval');
  collect(
    find.byWidgetPredicate((w) => w is Stack && w.clipBehavior != Clip.none),
    (w) => 'Stack(clipBehavior: ${(w as Stack).clipBehavior})',
  );

  return clippers;
}

/// Whether this clip belongs to a scroll view rather than to the app.
///
/// `StretchingOverscrollIndicator` — the Android overscroll effect Flutter
/// inserts inside every `Scrollable` — is built from a `ClipRect` around the
/// whole viewport. It is the clip that makes scrolling work, so everything
/// below the fold sits outside it, legitimately. Left in, it reported every
/// off-screen label on every scrolling screen: hundreds of findings, none of
/// them real, which would have buried anything that was.
///
/// Excluding the indicator rather than "anything inside a `Scrollable`" keeps
/// the check useful: almost all of this app's content is inside a scroll view,
/// and an author-written `ClipRRect` in a list is exactly the kind of thing
/// worth catching.
bool _isScrollMachinery(Element clipper) {
  var depth = 0;
  var machinery = false;
  clipper.visitAncestorElements((ancestor) {
    final name = ancestor.widget.runtimeType.toString();
    if (name.contains('OverscrollIndicator')) {
      machinery = true;
      return false;
    }
    return ++depth < 4;
  });
  return machinery;
}

/// Whether a scrollable sits between [text] and [clipper].
///
/// If one does, the clipping is the scrolling — content outside the viewport
/// is meant to be cut off, and scrolling reveals it. Flagging that would bury
/// the real findings in noise.
bool _scrollsWithin(Element text, Element clipper) {
  var found = false;
  text.visitAncestorElements((ancestor) {
    if (identical(ancestor, clipper)) return false;
    if (ancestor.widget is Scrollable || ancestor.widget is ScrollView) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

/// Fails if any text is cut off by an ancestor that constrains or clips it.
void expectNoClippedText(WidgetTester tester, {required String context}) {
  final problems = <String>[];

  for (final clipper in [..._fixedHeightBoxes(tester), ..._clippers(tester)]) {
    final texts = find.descendant(
      of: clipper.finder,
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

      if (_scrollsWithin(element, clipper.finder.evaluate().single)) continue;

      // Half a pixel of slack: rects land on subpixel boundaries at some
      // scale factors, and a rounding difference is not a clipped label.
      var worst = 0.0;
      var axis = '';
      void consider(double amount, String which) {
        if (amount > worst) {
          worst = amount;
          axis = which;
        }
      }

      consider(clipper.rect.top - rect.top, 'above the top');
      consider(rect.bottom - clipper.rect.bottom, 'below the bottom');
      if (!clipper.heightOnly) {
        consider(clipper.rect.left - rect.left, 'past the left edge');
        consider(rect.right - clipper.rect.right, 'past the right edge');
      }

      if (worst > 0.5) {
        problems.add(
          '$context: "$label" extends ${worst.toStringAsFixed(1)}dp $axis '
          'of its ${clipper.description}',
        );
      }
    }
  }

  expect(
    problems,
    isEmpty,
    reason:
        'Text is being cut off by an ancestor that constrains or clips it. '
        'This raises no overflow error — the text simply does not render.\n  '
        '${problems.join('\n  ')}',
  );
}
