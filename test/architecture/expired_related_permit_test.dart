import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/features/applications/presentation/widgets/related_permit_notice.dart';

/// An expired Building Permit is not the same wait as a pending one.
///
/// Eleven wizard steps offer Approved / Pending / Expired for the Building
/// Permit an ancillary permit attaches to. They required a number for
/// Approved and treated the other two identically, under a hint reading
/// "Optional while pending approval" — untrue of an expired permit. Not one of
/// them mentioned `expired` anywhere.
///
/// A pending permit is expected to be approved and the ancillary permit issues
/// after it. An expired one will not become approved by waiting.
void main() {
  test('every wizard with an expired state says what it means', () {
    // Keyed on the enum the wizard actually uses, not on the file name.
    // Architectural declares its own `RelatedBuildingPermitStatus` — same
    // name, different values (pendingIssuance / issued) and no expired state
    // at all — so it is excluded by measurement rather than by a hardcoded
    // exception that would rot.
    final modelsWithExpired = <String>{};
    for (final file in Directory(
      'lib/core/models',
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      final match = RegExp(
        r'enum RelatedBuildingPermitStatus\s*\{(.*?)\}',
        dotAll: true,
      ).firstMatch(source);
      if (match == null) continue;
      if (match.group(1)!.contains('expired')) {
        modelsWithExpired.add(file.uri.pathSegments.last);
      }
    }

    expect(
      modelsWithExpired.length,
      greaterThanOrEqualTo(10),
      reason:
          'found ${modelsWithExpired.length} models with an expired state; '
          'there were 10 when this was written, so a smaller number means the '
          'scan stopped matching and this gate is passing over nothing',
    );

    final offenders = <String>[];
    var checked = 0;
    for (final file
        in Directory('lib/features/applications/presentation')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      if (!source.contains('AppDropdown<RelatedBuildingPermitStatus>')) {
        continue;
      }
      // Which model does this step import?
      final usesExpiredModel = modelsWithExpired.any(
        (model) => source.contains(model),
      );
      if (!usesExpiredModel) continue;
      checked++;
      if (!source.contains('RelatedPermitNotice')) offenders.add(file.path);
    }

    expect(checked, greaterThanOrEqualTo(10));
    expect(
      offenders,
      isEmpty,
      reason:
          'these steps offer Expired and say nothing about what it means for '
          'the filing. Add RelatedPermitNotice',
    );
  });

  testWidgets('the notice names the consequence and allows filing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RelatedPermitNotice(isExpired: true)),
      ),
    );

    expect(
      find.textContaining('will not be approved by waiting'),
      findsOneWidget,
    );
    expect(
      find.textContaining('You can still file now'),
      findsOneWidget,
      reason: 'the office decides what it accepts; this names the consequence',
    );
  });

  testWidgets('a pending or approved permit gets no notice', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RelatedPermitNotice(isExpired: false)),
      ),
    );

    expect(find.textContaining('renewed'), findsNothing);
    expect(find.byType(Icon), findsNothing);
  });
}
