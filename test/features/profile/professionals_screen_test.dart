import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/professional_model.dart';
import 'package:ebpco_user_app/core/providers/professionals_provider.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/widgets/mock_upload.dart';
import 'package:ebpco_user_app/features/documents/presentation/widgets/attach_document_sheet.dart';
import 'package:ebpco_user_app/features/profile/presentation/professionals_screen.dart';

final _now = DateTime(2026, 8, 18);

ProfessionalModel _professional({
  String id = 'pro-1',
  String name = 'Arch. Maria Santos',
  DateTime? prcValidity,
  DateTime? ptrIssued,
  DocumentModel? prcId,
  DocumentModel? ptr,
}) => ProfessionalModel(
  id: id,
  fullName: name,
  discipline: ProfessionalDiscipline.architect,
  prcNumber: 'PRC-0001',
  prcValidityDate: prcValidity ?? DateTime(2027, 6, 1),
  ptrNumber: 'PTR-0001',
  ptrDateIssued: ptrIssued ?? DateTime(2026, 1, 10),
  ptrPlaceIssued: 'Quezon City',
  prcIdImage: prcId,
  ptrImage: ptr,
);

DocumentModel _document() => DocumentModel(
  id: 'doc-1',
  label: 'Attachment',
  fileName: 'attachment.pdf',
  uploadedAt: DateTime(2026, 8, 1),
);

Widget _wrap(ProfessionalsProvider provider) => ChangeNotifierProvider.value(
  value: provider,
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    home: const ProfessionalsScreen(),
  ),
);

ProfessionalsProvider _provider({
  List<ProfessionalModel>? professionals,
  List<AuthorizedRepresentative>? representatives,
}) => ProfessionalsProvider(
  professionals: professionals,
  representatives: representatives,
  clock: () => _now,
);

/// Opens a date field's picker and accepts today.
Future<void> _pickDate(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _tall(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugAttachDocumentOverride = (context, {required label}) async =>
        createMockDocument(label);
  });
  tearDown(() => debugAttachDocumentOverride = null);

  group('empty state', () {
    testWidgets('explains what each list is for rather than sharing one', (
      tester,
    ) async {
      await _tall(tester);
      await tester.pumpWidget(_wrap(_provider()));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Add the architect or engineer'),
        findsOneWidget,
      );
      expect(find.textContaining('only if someone else will'), findsOneWidget);
    });
  });

  group('credential warnings', () {
    testWidgets('a current licence is shown without alarm', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap(
          _provider(
            professionals: [
              _professional(prcId: _document(), ptr: _document()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Arch. Maria Santos'), findsOneWidget);
      expect(find.text('Architect'), findsOneWidget);
      expect(find.textContaining('has expired'), findsNothing);
      expect(find.textContaining('PRC expires in'), findsNothing);
    });

    testWidgets('a licence lapsing inside 60 days warns with the count', (
      tester,
    ) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap(
          _provider(
            professionals: [
              _professional(
                prcValidity: DateTime(2026, 10, 1),
                prcId: _document(),
                ptr: _document(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('PRC expires in 44 days. Renew before your next filing.'),
        findsOneWidget,
      );
    });

    testWidgets('an expired licence says what it costs the applicant', (
      tester,
    ) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap(
          _provider(
            professionals: [
              _professional(
                prcValidity: DateTime(2026, 5, 1),
                prcId: _document(),
                ptr: _document(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Plans signed and sealed under it will be returned',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a previous-year PTR is flagged as stale', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap(
          _provider(
            professionals: [
              _professional(
                ptrIssued: DateTime(2025, 1, 10),
                prcId: _document(),
                ptr: _document(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('from a previous year'), findsOneWidget);
    });

    testWidgets('missing credential images are noted without blocking', (
      tester,
    ) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap(_provider(professionals: [_professional()])),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('are not attached yet'), findsOneWidget);
      // Still listed and usable — the record is worth keeping either way.
      expect(find.text('Arch. Maria Santos'), findsOneWidget);
    });
  });

  group('representatives', () {
    testWidgets('one missing both documents is reported as unable to act', (
      tester,
    ) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap(
          _provider(
            representatives: const [
              AuthorizedRepresentative(
                id: 'rep-1',
                fullName: 'Pedro Santos',
                relationship: 'Brother',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Needs a notarised Special Power of Attorney and a valid ID.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a complete one is marked ready, with the counter caveat', (
      tester,
    ) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap(
          _provider(
            representatives: [
              AuthorizedRepresentative(
                id: 'rep-1',
                fullName: 'Pedro Santos',
                relationship: 'Brother',
                specialPowerOfAttorney: _document(),
                validId: _document(),
                authorizedUntil: DateTime(2026, 12, 31),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ready to act'), findsOneWidget);
      // Electronic copies do not replace the notarised original at the
      // counter, and the screen says so.
      expect(
        find.textContaining('bring the original notarised'),
        findsOneWidget,
      );
    });
  });

  group('adding a professional', () {
    testWidgets('save stays disabled until every required field is set', (
      tester,
    ) async {
      // A real phone viewport. The form overflowed here until the discipline
      // dropdown was given isExpanded — testing it at a comfortable width
      // would have hidden that.
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final provider = _provider();
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add a professional'));
      await tester.pumpAndSettle();

      ElevatedButton save() => tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save'),
      );
      expect(save().onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name *'),
        'Engr. Jose Cruz',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'PRC number *'),
        'PRC-9001',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'PTR number *'),
        'PTR-9001',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'PTR place issued *'),
        'Pasig City',
      );
      await tester.pumpAndSettle();

      // Text alone is not enough — both dates are required.
      expect(
        save().onPressed,
        isNull,
        reason: 'a professional without licence dates cannot be checked',
      );

      await _pickDate(tester, 'PRC valid until *');
      expect(save().onPressed, isNull);

      await _pickDate(tester, 'PTR date issued *');
      expect(save().onPressed, isNotNull);

      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Nothing overflowed on the way through.
      expect(tester.takeException(), isNull);

      expect(provider.professionals, hasLength(1));
      expect(provider.professionals.single.fullName, 'Engr. Jose Cruz');
      expect(find.text('Engr. Jose Cruz'), findsOneWidget);
    });
  });

  group('provider', () {
    test('surfaces whoever needs attention, soonest first', () {
      final provider = _provider(
        professionals: [
          _professional(
            id: 'a',
            name: 'Fine',
            prcValidity: DateTime(2028, 1, 1),
          ),
          _professional(
            id: 'b',
            name: 'Expired',
            prcValidity: DateTime(2026, 5, 1),
          ),
          _professional(
            id: 'c',
            name: 'Due soon',
            prcValidity: DateTime(2026, 10, 1),
          ),
        ],
      );

      expect(
        provider.professionalsNeedingAttention.map((p) => p.fullName).toList(),
        ['Expired', 'Due soon'],
      );
    });

    test('saving an existing id updates rather than duplicating', () {
      final provider = _provider(professionals: [_professional()]);

      provider.saveProfessional(_professional(name: 'Arch. M. Santos'));

      expect(provider.professionals, hasLength(1));
      expect(provider.professionals.single.fullName, 'Arch. M. Santos');
    });

    test('blocked representatives are listed separately', () {
      final provider = _provider(
        representatives: [
          const AuthorizedRepresentative(
            id: 'rep-1',
            fullName: 'Incomplete',
            relationship: 'Brother',
          ),
          AuthorizedRepresentative(
            id: 'rep-2',
            fullName: 'Ready',
            relationship: 'Spouse',
            specialPowerOfAttorney: _document(),
            validId: _document(),
          ),
        ],
      );

      expect(provider.representativesBlocked.map((r) => r.fullName).toList(), [
        'Incomplete',
      ]);
    });
  });
}
