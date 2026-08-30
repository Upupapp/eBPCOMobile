import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every field a model declares is either filled by the parser that builds it,
/// or exempted here with a reason.
///
/// **This gate exists because the same defect was found four times by hand.**
/// `application_dto.dart` read four of a document's thirteen fields, dropping
/// the whole per-document review layer. It filled seven of an assessment's
/// eleven, dropping every payment made against it. It knew four payment states
/// of five, so a partially-paid application could not load at all. The
/// notification parser dropped `payload`, which is what every message body is
/// templated from, so each one arrived generic. The profile parser filled four
/// of fourteen fields, so a signed-in applicant saw a blank record.
///
/// Each was found by writing this diff by hand, reading the result, and then
/// throwing the script away. That is luck, repeated. This is the gate.
///
/// **What it cannot see**, stated plainly because a source scan that oversells
/// itself is worse than none: it matches constructor invocations textually, so
/// a field assembled through a helper, a spread, or `copyWith` reads as
/// unfilled. That is why the exemption list exists and why every entry carries
/// a reason rather than a name alone.

/// Fields a parser is right not to fill. Each says why.
const Map<String, Map<String, String>> _exempt = {
  'ApplicationModel': {
    'lineage':
        'TAB 14 renewal / amendment. The server accepts renewsPermitNumber on '
        'its WRITE controllers and does not return it on the read payload, so '
        'there is no field to read. Inventing a key would produce a parser '
        'that silently never fires. M-44, backend lane.',
    'statusHistory':
        'The older coarse status list, superseded by `timeline`, which the '
        'parser does fill. Rendered only as a fallback for records predating '
        'lifecycle tracking, and a live server has none of those.',
  },
  'DocumentModel': {
    'fileSizeBytes':
        'An upload-time concern. The detail payload describes a document the '
        'office already holds, not a file being sent.',
    'filePath':
        'The path of a real file on THIS device, set when the applicant picks '
        'one. A server cannot know it.',
  },
  'PaymentAssessmentModel': {
    'paidOn':
        'Write-only, and asymmetrically so. The contract REQUIRES `paidOn` on '
        'PaymentProof — the applicant must say when they paid — and its '
        'PaymentState response does not return it, so there is no field to '
        'read back. The office therefore cannot show an applicant the date '
        'they themselves reported. Filed for the contract lane in M-47; '
        'inventing a key here would produce a parser that never fires.',
  },
  'GeneratedPermit': {
    'localFilePath':
        'Set when the applicant downloads their permit for offline use. '
        'Device-local by definition.',
  },
  'NotificationEvent': {
    'dedupeKey':
        'Identifies a condition this app derived for ITSELF. A server-sent '
        'notification has no such key, and inventing one would let a derived '
        'notice dedupe against a real one.',
    'pushSuppressed':
        'What THIS device decided about delivery, from quiet hours and the '
        'applicant\'s muted categories. Not the server\'s to state.',
  },
};

/// The files that turn JSON into models.
const _parsers = [
  'lib/core/api/application_dto.dart',
  'lib/core/repositories/http_notifications_repository.dart',
  'lib/core/repositories/http_auth_repository.dart',
  'lib/core/repositories/http_business_repository.dart',
  'lib/core/repositories/document_repository.dart',
];

/// The body of `class <name>`, bounded by the next top-level declaration.
///
/// Bounded rather than "rest of file" because an earlier hand-run of this diff
/// matched `SavedDocumentModel`'s fields against `DocumentModel` and reported
/// eight phantom omissions.
String? _classBody(String source, String name) {
  final start = RegExp(
    r'^(?:abstract\s+)?class\s+' + name + r'\b',
    multiLine: true,
  ).firstMatch(source);
  if (start == null) return null;
  final next = RegExp(r'^(?:abstract\s+)?class\s+\w+', multiLine: true)
      .allMatches(source)
      .map((m) => m.start)
      .firstWhere((s) => s > start.start, orElse: () => source.length);
  return source.substring(start.start, next);
}

/// The named parameters of `name`'s primary constructor.
Set<String> _declaredFields(String body, String name) {
  final ctor = RegExp(
    '(?:const\\s+)?$name\\(\\{(.*?)\\}\\)',
    dotAll: true,
  ).firstMatch(body);
  if (ctor == null) return {};
  return RegExp(
    r'(?:this\.|required\s+this\.|required\s+[\w<>?, ]+\s+)([a-zA-Z_]\w*)\s*[,=}]',
  ).allMatches(ctor.group(1)!).map((m) => m.group(1)!).toSet();
}

/// The named arguments every `name(` invocation in [source] sets.
Set<String> _filledFields(String source, String name) {
  final filled = <String>{};
  for (final call in RegExp(r'\b' + name + r'\(').allMatches(source)) {
    var depth = 1;
    var i = call.end;
    while (i < source.length && depth > 0) {
      if (source[i] == '(') depth++;
      if (source[i] == ')') depth--;
      i++;
    }
    filled.addAll(
      RegExp(
        r'(?:^|[\s,(\[])([a-zA-Z_]\w*)\s*:',
      ).allMatches(source.substring(call.end, i - 1)).map((m) => m.group(1)!),
    );
  }
  return filled;
}

void main() {
  final modelSources = {
    for (final file in Directory(
      'lib/core/models',
    ).listSync()..sort((a, b) => a.path.compareTo(b.path)))
      if (file is File && file.path.endsWith('.dart'))
        file.path: file.readAsStringSync(),
  };

  /// Every model class, mapped to the fields its constructor declares.
  final declared = <String, Set<String>>{};
  for (final source in modelSources.values) {
    for (final m in RegExp(
      r'^class\s+(\w+)',
      multiLine: true,
    ).allMatches(source)) {
      final name = m.group(1)!;
      final body = _classBody(source, name);
      if (body == null) continue;
      final fields = _declaredFields(body, name);
      if (fields.isNotEmpty) declared.putIfAbsent(name, () => fields);
    }
  }

  test('the scan found models at all', () {
    // A scan that matched nothing would pass every assertion below.
    expect(declared.length, greaterThan(20));
    expect(declared['DocumentModel'], contains('reviewReason'));
    expect(
      declared['DocumentModel'],
      isNot(contains('category')),
      reason: 'that is SavedDocumentModel — the class bounds are wrong',
    );
  });

  for (final path in _parsers) {
    final source = File(path).readAsStringSync();
    final name = path.split('/').last;

    test('$name fills every field of every model it builds', () {
      final complaints = <String>[];

      for (final entry in declared.entries) {
        final model = entry.key;
        if (!RegExp(r'\b' + model + r'\(').hasMatch(source)) continue;

        final missing =
            entry.value
                .difference(_filledFields(source, model))
                .where((f) => !(_exempt[model]?.containsKey(f) ?? false))
                .toList()
              ..sort();

        if (missing.isNotEmpty) {
          complaints.add('$model drops ${missing.join(', ')}');
        }
      }

      expect(
        complaints,
        isEmpty,
        reason:
            'These fields are declared on the model and never set by this '
            'parser, so they can only ever be populated by a mock:\n  '
            '${complaints.join('\n  ')}\n'
            'Either parse them, or add them to _exempt in this file WITH THE '
            'REASON. An exemption with no reason is how the last five of these '
            'survived.',
      );
    });
  }

  test('every exemption names a model and a field that still exist', () {
    // An exemption for a field that has been deleted or renamed is a silent
    // hole: it would go on excusing a name nothing declares any more.
    for (final entry in _exempt.entries) {
      final fields = declared[entry.key];
      expect(
        fields,
        isNotNull,
        reason: '${entry.key} is exempted but not found',
      );
      for (final field in entry.value.keys) {
        expect(
          fields,
          contains(field),
          reason: '${entry.key}.$field is exempted but no longer declared',
        );
      }
    }
  });

  test('every exemption carries a real reason, not a placeholder', () {
    for (final entry in _exempt.entries) {
      entry.value.forEach((field, reason) {
        expect(
          reason.trim().length,
          greaterThan(40),
          reason: '${entry.key}.$field needs a reason somebody can act on',
        );
      });
    }
  });
}
