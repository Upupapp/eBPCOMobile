import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/upload_progress.dart';
import 'package:ebpco_user_app/shared/widgets/states/upload_progress_sheet.dart';

/// What a citizen sees while a filing's attachments go to the office.
///
/// **It used to be a spinner and nothing else** — for as long as the upload
/// took, which on rural data and a twenty-megabyte plan set is minutes. The
/// reasonable thing to do with a screen that gives no sign of life is close
/// the app, and that loses the filing.

void main() {
  group('the fraction spans the whole filing, not one file', () {
    test('a per-file bar resetting 24 times would read as no progress', () {
      // Document 1 of 4, half sent → an eighth of the submission.
      const p = UploadProgress(
        index: 0,
        total: 4,
        label: 'Land Title',
        sentBytes: 50,
        totalBytes: 100,
      );
      expect(p.fraction, closeTo(0.125, 0.001));
    });

    test('a document not yet started sits at its own boundary', () {
      const p = UploadProgress(index: 2, total: 4, label: 'Survey Plan');
      expect(p.fraction, closeTo(0.5, 0.001));
    });

    test('it never exceeds one, whatever the transport reports', () {
      // Bytes handed to a socket can overshoot a computed content length.
      const p = UploadProgress(
        index: 3,
        total: 4,
        label: 'Plans',
        sentBytes: 300,
        totalBytes: 100,
      );
      expect(p.fraction, 1.0);
    });

    test('and an empty filing is complete rather than dividing by zero', () {
      const p = UploadProgress(index: 0, total: 0, label: '');
      expect(p.fraction, 1.0);
    });
  });

  test('the position counts from one, as a person would', () {
    const p = UploadProgress(index: 2, total: 24, label: 'Land Title');
    expect(p.position, 'Sending 3 of 24');
  });

  testWidgets('the sheet names the document, not its number', (tester) async {
    // Someone watching an upload stall wants to know which of their files it
    // is — "document 3" tells them nothing they can act on.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UploadProgressSheet(
            progress: UploadProgress(
              index: 2,
              total: 24,
              label: 'Land Title',
              sentBytes: 1024,
              totalBytes: 4096,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Sending 3 of 24'), findsOneWidget);
    expect(find.textContaining('Land Title'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      find.textContaining('Keep this screen open'),
      findsOneWidget,
      reason:
          'the instruction is the point — a citizen who closes the app during '
          'the slowest part loses the filing',
    );
  });

  testWidgets('the bar reflects the filing, not the file', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UploadProgressSheet(
            progress: UploadProgress(index: 1, total: 4, label: 'Survey Plan'),
          ),
        ),
      ),
    );
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.25, 0.001));
  });
}
