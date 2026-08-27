import 'package:flutter/material.dart';

import '../../../../../core/models/document_model.dart';
import '../../../../../core/models/fencing_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';
import '../../../../../shared/widgets/uploads/document_upload_tile.dart';
import '../../../../documents/presentation/widgets/attach_document_sheet.dart';

/// Step 3 — Construction Location. Also has no province field, matching
/// the official form's field list for this permit.
class Step3ConstructionLocation extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final FencingPermitDraft draft;
  final VoidCallback onChanged;

  const Step3ConstructionLocation({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step3ConstructionLocation> createState() =>
      _Step3ConstructionLocationState();
}

class _Step3ConstructionLocationState extends State<Step3ConstructionLocation> {
  late final TextEditingController _lotNumber;
  late final TextEditingController _blockNumber;
  late final TextEditingController _tctNumber;
  late final TextEditingController _taxDeclarationNumber;
  late final TextEditingController _street;
  late final TextEditingController _barangay;
  late final TextEditingController _city;

  FencingConstructionLocation get _location =>
      widget.draft.constructionLocation;

  @override
  void initState() {
    super.initState();
    _lotNumber = TextEditingController(text: _location.lotNumber);
    _blockNumber = TextEditingController(text: _location.blockNumber);
    _tctNumber = TextEditingController(text: _location.tctNumber);
    _taxDeclarationNumber = TextEditingController(
      text: _location.taxDeclarationNumber,
    );
    _street = TextEditingController(text: _location.street);
    _barangay = TextEditingController(text: _location.barangay);
    _city = TextEditingController(text: _location.city);
  }

  @override
  void dispose() {
    _lotNumber.dispose();
    _blockNumber.dispose();
    _tctNumber.dispose();
    _taxDeclarationNumber.dispose();
    _street.dispose();
    _barangay.dispose();
    _city.dispose();
    super.dispose();
  }

  void _handleUseSameAddressToggled(bool value) {
    setState(() {
      widget.draft.useApplicantAddressForConstructionLocation = value;
      if (value) {
        widget.draft.copyApplicantAddressToConstructionLocation();
        _street.text = _location.street;
        _barangay.text = _location.barangay;
        _city.text = _location.city;
      }
    });
    widget.onChanged();
  }

  /// Opens the document chooser and stores what comes back.
  ///
  /// The picker can outlive this step, so the mounted check is not optional —
  /// see the same guard on every other upload handler in the app.
  Future<void> _pickDocument(
    String label,
    void Function(DocumentModel?) assign,
  ) async {
    final picked = await showAttachDocumentOptions(context, label: label);
    if (picked == null) return;
    if (!mounted) return;
    setState(() => assign(picked));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: FormScrollScaffold(
        centerVertically: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Construction Location', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Construction location is the same as my address.',
                    ),
                    value:
                        widget.draft.useApplicantAddressForConstructionLocation,
                    onChanged: _handleUseSameAddressToggled,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _lotNumber,
                    label: 'Lot Number *',
                    validator: (v) =>
                        Validators.required(v, fieldLabel: 'Lot number'),
                    onChanged: (v) {
                      _location.lotNumber = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _blockNumber,
                    label: 'Block Number',
                    hint: 'Optional',
                    onChanged: (v) {
                      _location.blockNumber = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _tctNumber,
                    label: 'TCT Number',
                    hint: 'Transfer Certificate of Title.',
                    onChanged: (v) {
                      _location.tctNumber = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _taxDeclarationNumber,
                    label: 'Tax Declaration Number',
                    hint: 'Found on your property tax declaration.',
                    onChanged: (v) {
                      _location.taxDeclarationNumber = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _street,
                    label: 'Street *',
                    validator: (v) =>
                        Validators.required(v, fieldLabel: 'Street'),
                    onChanged: (v) {
                      _location.street = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _barangay,
                    label: 'Barangay *',
                    validator: (v) =>
                        Validators.required(v, fieldLabel: 'Barangay'),
                    onChanged: (v) {
                      _location.barangay = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _city,
                    label: 'City / Municipality *',
                    validator: (v) => Validators.required(
                      v,
                      fieldLabel: 'City or municipality',
                    ),
                    onChanged: (v) {
                      _location.city = v;
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Site and ownership documents. Reconciled against the
            // requirements catalog on 27 Aug 2026 — none of these had a slot
            // anywhere in this wizard.
            Text(
              'Site and Ownership Documents',
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            DocumentUploadTile(
              label: 'Land Title or Tax Declaration',
              document: _location.landTitleOrTaxDeclarationUpload,
              onUpload: () => _pickDocument(
                'Land Title or Tax Declaration',
                (d) => _location.landTitleOrTaxDeclarationUpload = d,
              ),
              onRemove: () => setState(() {
                _location.landTitleOrTaxDeclarationUpload = null;
                widget.onChanged();
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            DocumentUploadTile(
              label: 'Barangay Clearance',
              document: _location.barangayClearanceUpload,
              onUpload: () => _pickDocument(
                'Barangay Clearance',
                (d) => _location.barangayClearanceUpload = d,
              ),
              onRemove: () => setState(() {
                _location.barangayClearanceUpload = null;
                widget.onChanged();
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            DocumentUploadTile(
              label: 'Locational Clearance / Zoning Certification',
              document: _location.locationalClearanceUpload,
              onUpload: () => _pickDocument(
                'Locational Clearance / Zoning Certification',
                (d) => _location.locationalClearanceUpload = d,
              ),
              onRemove: () => setState(() {
                _location.locationalClearanceUpload = null;
                widget.onChanged();
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            DocumentUploadTile(
              label: 'Valid Government-Issued ID',
              document: _location.validGovernmentIdUpload,
              onUpload: () => _pickDocument(
                'Valid Government-Issued ID',
                (d) => _location.validGovernmentIdUpload = d,
              ),
              onRemove: () => setState(() {
                _location.validGovernmentIdUpload = null;
                widget.onChanged();
              }),
            ),
          ],
        ),
      ),
    );
  }
}
