import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/constants/app_colors.dart';
import 'package:ebpco_user_app/core/constants/app_constants.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/shared/widgets/alerts/app_alert.dart';
import 'package:ebpco_user_app/shared/widgets/badges/status_badge.dart';
import 'package:ebpco_user_app/shared/widgets/buttons/primary_button.dart';
import 'package:ebpco_user_app/shared/widgets/buttons/secondary_button.dart';
import 'package:ebpco_user_app/shared/widgets/cards/app_card.dart';
import 'package:ebpco_user_app/shared/widgets/cards/tracking_card.dart';
import 'package:ebpco_user_app/shared/widgets/chips/app_chip.dart';
import 'package:ebpco_user_app/shared/widgets/layout/expandable_section.dart';
import 'package:ebpco_user_app/shared/widgets/layout/section_header.dart';
import 'package:ebpco_user_app/shared/widgets/states/empty_state.dart';
import 'package:ebpco_user_app/shared/widgets/states/error_state.dart';
import 'package:ebpco_user_app/shared/widgets/states/stale_data_banner.dart';
import 'package:ebpco_user_app/shared/widgets/text_fields/app_dropdown.dart';
import 'package:ebpco_user_app/shared/widgets/text_fields/app_text_field.dart';
import 'package:ebpco_user_app/shared/widgets/uploads/document_upload_tile.dart';

/// The shared widgets compose all 67 screens, so testing them at 200% text
/// scale covers far more surface than the same effort spent screen by screen.
///
/// The strings are deliberately the longest real ones in the app rather than
/// "Hello": a widget that survives "OK" and bursts on "Signed and Sealed
/// Electrical Specifications" has not been tested.

const _longLabel = 'Signed and Sealed Electrical Specifications';
const _longStatus = 'Payment Under Verification';
const _longTitle = 'Certificate of Occupancy — Addition / Extension';

DocumentModel _document() => DocumentModel(
  id: 'doc-1',
  label: _longLabel,
  fileName: 'signed_and_sealed_electrical_specifications.pdf',
  uploadedAt: DateTime(2026, 8, 1),
  fileSizeBytes: 248000,
);

/// Every shared widget, with its most demanding realistic content.
Map<String, Widget> _widgets() => {
  'PrimaryButton': PrimaryButton(
    label: 'Submit proof of payment',
    icon: Icons.upload_file_outlined,
    onPressed: () {},
  ),
  'SecondaryButton': SecondaryButton(
    label: 'View the full requirements',
    onPressed: () {},
  ),
  'StatusBadge': const StatusBadge(
    label: _longStatus,
    color: AppColors.statusPending,
    backgroundColor: AppColors.statusPendingBg,
  ),
  'AppChip': AppChip(label: _longStatus, selected: true, onSelected: (_) {}),
  'AppAlert': const AppAlert(
    variant: AppAlertVariant.info,
    message:
        'Turning a category off stops its push notifications. The update is '
        'still recorded here in the app, so nothing is lost.',
  ),
  'EmptyState': const EmptyState(
    icon: Icons.folder_open_outlined,
    title: 'Nothing needs you right now',
    message:
        'When the office asks for a correction or issues an Order of Payment, '
        'it will appear here.',
  ),
  'ErrorState': ErrorState(
    title: 'Could not load your applications',
    message: 'The office’s system did not respond in time. Please try again.',
    onRetry: () {},
  ),
  'StaleDataBanner': StaleDataBanner(
    lastLoadedAt: DateTime(2026, 8, 18, 14, 32),
    onRetry: () {},
  ),
  'SectionHeader': SectionHeader(
    title: 'Application Summary',
    actionLabel: 'See All',
    onActionTap: () {},
  ),
  'AppCard': const AppCard(child: Text(_longTitle)),
  'TrackingCard': TrackingCard(
    trackingId: 'E-BPCO-2026-000145',
    title: "Juan's General Merchandise, Inc.",
    subtitle: _longTitle,
    statusLabel: _longStatus,
    statusColor: AppColors.statusPending,
    statusBackgroundColor: AppColors.statusPendingBg,
    progress: 0.4,
    footerText: 'The Treasurer’s Office is verifying your payment.',
    actionLabel: 'View Details',
    onAction: () {},
  ),
  'DocumentUploadTile (empty)': DocumentUploadTile(
    label: _longLabel,
    onUpload: () {},
  ),
  'DocumentUploadTile (filled)': DocumentUploadTile(
    label: _longLabel,
    document: _document(),
    allowReplace: true,
    onUpload: () {},
    onRemove: () {},
  ),
  'ExpandableSection': ExpandableSection(
    title: 'Professional Documents and Signed Plans',
    initiallyExpanded: true,
    children: [const Text(_longLabel)],
  ),
  'AppTextField': AppTextField(
    controller: TextEditingController(text: 'Juan Dela Cruz'),
    label: 'Total Estimated Construction Cost *',
    onChanged: (_) {},
  ),
  'AppDropdown': AppDropdown<String>(
    label: 'Discipline *',
    value: 'Professional Electronics Engineer',
    items: const [
      DropdownMenuItem(
        value: 'Professional Electronics Engineer',
        child: Text('Professional Electronics Engineer'),
      ),
    ],
    onChanged: (_) {},
  ),
};

Widget _host(Widget child, {required double textScale}) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(
    backgroundColor: AppColors.background,
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      // Scrollable so vertical growth is legal; only horizontal overflow —
      // which no amount of scrolling fixes — should fail these.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
        child: child,
      ),
    ),
  ),
);

Future<void> _pumpAt(
  WidgetTester tester,
  Widget child, {
  required double textScale,
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_host(child, textScale: textScale));
  await tester.pumpAndSettle();
}

void main() {
  group('at 100% on a 360dp phone', () {
    _widgets().forEach((name, widget) {
      testWidgets(name, (tester) async {
        await _pumpAt(tester, widget, textScale: 1.0);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('at 200% text scale on a 360dp phone', () {
    _widgets().forEach((name, widget) {
      testWidgets(name, (tester) async {
        await _pumpAt(tester, widget, textScale: 2.0);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('at 320dp, the narrowest phone still in use', () {
    // An iPhone SE 1st generation and several budget Android handsets are
    // 320dp wide. They run iOS 15 and current Android, so they are inside the
    // supported set, not legacy.
    _widgets().forEach((name, widget) {
      testWidgets(name, (tester) async {
        await _pumpAt(tester, widget, textScale: 1.0, width: 320);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('tap targets meet the 48dp floor', () {
    testWidgets('interactive shared widgets', (tester) async {
      await _pumpAt(
        tester,
        Column(
          children: [
            PrimaryButton(label: 'Submit', onPressed: () {}),
            const SizedBox(height: 8),
            SecondaryButton(label: 'Back', onPressed: () {}),
            const SizedBox(height: 8),
            SectionHeader(
              title: 'X',
              actionLabel: 'See All',
              onActionTap: () {},
            ),
            const SizedBox(height: 8),
            DocumentUploadTile(label: 'PRC ID', onUpload: () {}),
          ],
        ),
        textScale: 1.0,
      );

      for (final type in [ElevatedButton, OutlinedButton, TextButton]) {
        for (final element in find.byType(type).evaluate()) {
          final size = tester.getSize(find.byWidget(element.widget));
          expect(
            size.height,
            greaterThanOrEqualTo(AppConstants.minTouchTarget - 0.5),
            reason: '$type is only ${size.height}dp tall',
          );
        }
      }
    });
  });
}
