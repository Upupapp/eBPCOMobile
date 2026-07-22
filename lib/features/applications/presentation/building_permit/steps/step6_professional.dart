import 'package:flutter/material.dart';

import '../../../../../core/models/building_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/alerts/app_alert.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_dropdown.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';
import '../../../../../shared/widgets/uploads/document_upload_tile.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/mock_upload.dart';

/// Step 6 — Architect or Civil Engineer in charge. The official form
/// requires a licensed professional as full-time inspector/supervisor of
/// the construction work; no electronic signature is captured here, only
/// an upload placeholder for the signed-and-sealed document.
class Step6Professional extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BuildingPermitDraft draft;
  final VoidCallback onChanged;

  const Step6Professional({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step6Professional> createState() => _Step6ProfessionalState();
}

class _Step6ProfessionalState extends State<Step6Professional> {
  late final TextEditingController _fullName;
  late final TextEditingController _address;
  late final TextEditingController _prcNumber;
  late final TextEditingController _ptrNumber;
  late final TextEditingController _ptrPlaceIssued;
  late final TextEditingController _tin;
  late final TextEditingController _contactNumber;

  ProfessionalDetails get _professional => widget.draft.professional;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: _professional.fullName);
    _address = TextEditingController(text: _professional.address);
    _prcNumber = TextEditingController(text: _professional.prcNumber);
    _ptrNumber = TextEditingController(text: _professional.ptrNumber);
    _ptrPlaceIssued = TextEditingController(text: _professional.ptrPlaceIssued);
    _tin = TextEditingController(text: _professional.tin);
    _contactNumber = TextEditingController(text: _professional.contactNumber);
  }

  @override
  void dispose() {
    _fullName.dispose();
    _address.dispose();
    _prcNumber.dispose();
    _ptrNumber.dispose();
    _ptrPlaceIssued.dispose();
    _tin.dispose();
    _contactNumber.dispose();
    super.dispose();
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
            const AppAlert(
              variant: AppAlertVariant.info,
              message:
                  'The official form requires a licensed Architect or Civil '
                  'Engineer acting as the full-time inspector and supervisor '
                  'of construction works.',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _fullName,
              label: 'Full Name',
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.required(
                v,
                fieldLabel: "Professional's full name",
              ),
              onChanged: (v) {
                _professional.fullName = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<ProfessionType>(
              value: _professional.profession,
              label: 'Profession',
              items: ProfessionType.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                  .toList(),
              validator: (v) =>
                  v == null ? 'Please select a profession.' : null,
              onChanged: (v) {
                setState(() => _professional.profession = v);
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _address,
              label: 'Address',
              validator: (v) => Validators.required(v, fieldLabel: 'Address'),
              onChanged: (v) {
                _professional.address = v;
                widget.onChanged();
              },
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Professional Credentials', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _prcNumber,
              label: 'PRC Number',
              validator: (v) =>
                  Validators.required(v, fieldLabel: 'PRC number'),
              onChanged: (v) {
                _professional.prcNumber = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DatePickerField(
              label: 'PRC Validity Date',
              value: _professional.prcValidityDate,
              validator: (v) =>
                  v == null ? 'Please select the PRC validity date.' : null,
              onChanged: (v) {
                setState(() => _professional.prcValidityDate = v);
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _ptrNumber,
              label: 'PTR Number',
              validator: (v) =>
                  Validators.required(v, fieldLabel: 'PTR number'),
              onChanged: (v) {
                _professional.ptrNumber = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DatePickerField(
              label: 'PTR Date Issued',
              value: _professional.ptrDateIssued,
              validator: (v) =>
                  v == null ? 'Please select the PTR date issued.' : null,
              onChanged: (v) {
                setState(() => _professional.ptrDateIssued = v);
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _ptrPlaceIssued,
              label: 'PTR Place Issued',
              validator: (v) =>
                  Validators.required(v, fieldLabel: 'PTR place issued'),
              onChanged: (v) {
                _professional.ptrPlaceIssued = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _tin,
              label: 'TIN',
              hint: 'Optional',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                _professional.tin = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _contactNumber,
              label: 'Contact Number',
              keyboardType: TextInputType.phone,
              validator: Validators.philippineMobile,
              onChanged: (v) {
                _professional.contactNumber = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DatePickerField(
              label: 'Date Signed',
              value: _professional.dateSigned,
              validator: (v) =>
                  v == null ? 'Please select the date signed.' : null,
              onChanged: (v) {
                setState(() => _professional.dateSigned = v);
                widget.onChanged();
              },
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Uploads', style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text(
              'Upload the form signed and sealed by the licensed professional. '
              'A real electronic signature is not required in this prototype.',
              style: AppTypography.helper,
            ),
            const SizedBox(height: AppSpacing.md),
            DocumentUploadTile(
              label: 'PRC ID',
              allowReplace: true,
              document: _professional.prcIdUpload,
              onUpload: () {
                setState(
                  () =>
                      _professional.prcIdUpload = createMockDocument('PRC ID'),
                );
                widget.onChanged();
              },
              onRemove: () {
                setState(() => _professional.prcIdUpload = null);
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DocumentUploadTile(
              label: 'Current PTR',
              allowReplace: true,
              document: _professional.ptrUpload,
              onUpload: () {
                setState(
                  () => _professional.ptrUpload = createMockDocument(
                    'Current PTR',
                  ),
                );
                widget.onChanged();
              },
              onRemove: () {
                setState(() => _professional.ptrUpload = null);
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DocumentUploadTile(
              label: 'Signed and Sealed Professional Certification',
              statusLabel: 'Signed and sealed document upload',
              allowReplace: true,
              document: _professional.signedSealedFormUpload,
              onUpload: () {
                setState(
                  () => _professional.signedSealedFormUpload =
                      createMockDocument('Signed and Sealed Certification'),
                );
                widget.onChanged();
              },
              onRemove: () {
                setState(() => _professional.signedSealedFormUpload = null);
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
