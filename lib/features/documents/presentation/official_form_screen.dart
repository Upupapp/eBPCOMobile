import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/contract/permit_forms.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/documents/pdf_file_view.dart';
import '../../../shared/widgets/states/error_state.dart';
import '../../../shared/widgets/states/loading_view.dart';

/// Materialises a bundled asset onto disk and returns its path.
///
/// `PDFView` reads a file, not an asset, so the bundle has to be spilled into
/// the cache directory first. Written once per file and reused: the forms
/// never change between releases, so re-copying six megabytes every time
/// somebody opens one would be waste the applicant pays for in battery.
typedef OfficialFormResolver = Future<String> Function(String assetPath);

Future<String> _defaultResolver(String assetPath) async {
  final dir = await getApplicationCacheDirectory();
  final target = File('${dir.path}/${assetPath.split('/').last}');
  if (await target.exists() && await target.length() > 0) return target.path;
  final data = await rootBundle.load(assetPath);
  await target.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  return target.path;
}

/// Test seam. `path_provider` and the asset bundle are both platform channels
/// with no answer under `flutter test`, so the resolver is swapped rather than
/// the screen being left uncovered.
@visibleForTesting
OfficialFormResolver? debugOfficialFormResolver;

/// One blank official application form or checklist, read in the app.
///
/// The point is offline preparation. An applicant sitting with an engineer,
/// or filling the paper form the night before, should be able to see exactly
/// what the counter will hand them — the same PDF the admin portal serves,
/// bundled rather than fetched.
class OfficialFormScreen extends StatefulWidget {
  /// The admin's exact permit-type string.
  final String permitType;

  /// True to open the OBO documentary-requirements checklist instead of the
  /// application form.
  final bool checklist;

  const OfficialFormScreen({
    super.key,
    required this.permitType,
    this.checklist = false,
  });

  @override
  State<OfficialFormScreen> createState() => _OfficialFormScreenState();
}

class _OfficialFormScreenState extends State<OfficialFormScreen> {
  PermitForm? _form;
  String? _path;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final form = widget.checklist
        ? permitChecklistForLabel(widget.permitType)
        : permitFormForLabel(widget.permitType);
    if (form == null) {
      // No document for this type. Reported as such rather than as a broken
      // viewer — the applicant has done nothing wrong and there is nothing to
      // retry.
      setState(() {
        _loading = false;
        _form = null;
      });
      return;
    }
    try {
      final resolver = debugOfficialFormResolver ?? _defaultResolver;
      final path = await resolver(form.assetPath);
      if (!mounted) return;
      setState(() {
        _form = form;
        _path = path;
        _loading = false;
      });
    } catch (_) {
      // A packaging or storage fault, not the applicant's doing. Say so, and
      // do not leave a spinner running for ever.
      if (!mounted) return;
      setState(() {
        _form = form;
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = _form;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.checklist ? 'Requirements checklist' : 'Official form',
        ),
      ),
      body: SafeArea(child: _body(form)),
    );
  }

  Widget _body(PermitForm? form) {
    if (_loading) return const LoadingView();

    if (form == null) {
      return ErrorState(
        icon: Icons.description_outlined,
        title: widget.checklist
            ? 'No checklist for this permit'
            : 'No form for this permit',
        message: widget.checklist
            ? 'The Office of the Building Official publishes its documentary '
                  'requirements checklist for building permits and the '
                  'Certificate of Occupancy only. Your permit\'s requirements '
                  'are listed in the application itself.'
            : 'The office has not published a blank application form for '
                  '${widget.permitType}. You can still file through this app, '
                  'and the requirements are listed before you start.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(form.title, style: AppTypography.cardTitle),
              const SizedBox(height: 2),
              Text(form.office.label, style: AppTypography.bodyMuted),
              if (!form.isOfficialCastillaForm) ...[
                const SizedBox(height: AppSpacing.md),
                _ReferenceOnlyNotice(permitType: widget.permitType),
              ],
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.screenPaddingHorizontal,
              0,
              AppConstants.screenPaddingHorizontal,
              AppConstants.screenPaddingHorizontal,
            ),
            child: _failed || _path == null
                ? const ErrorState(
                    icon: Icons.error_outline,
                    title: 'Form could not be opened',
                    message:
                        'This form is part of the app and should always be '
                        'available. Ask the Office of the Building Official '
                        'for a printed copy, and report this if it keeps '
                        'happening.',
                  )
                : PdfFileView(
                    filePath: _path!,
                    onFailure: const ErrorState(
                      icon: Icons.error_outline,
                      title: 'Form could not be displayed',
                      message:
                          'The file is present but could not be rendered on '
                          'this device. A printed copy is available at the '
                          'office.',
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Says plainly that this is a stand-in.
///
/// The admin records the same fact in a source comment, where no applicant
/// will ever read it. Someone who takes a generic template to the counter
/// expecting it to be accepted has been misled by the app, so the label is not
/// optional.
class _ReferenceOnlyNotice extends StatelessWidget {
  final String permitType;

  const _ReferenceOnlyNotice({required this.permitType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reference only — not the official form',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            'The Municipality of Castilla has not published its own blank '
            'form for $permitType. This template shows what is normally '
            'asked for, so you can prepare — but ask the office for the form '
            'they accept before filling one in by hand.',
            style: AppTypography.helper,
          ),
        ],
      ),
    );
  }
}
