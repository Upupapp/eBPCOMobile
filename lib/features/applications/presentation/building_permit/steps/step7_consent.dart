import 'package:flutter/material.dart';

import '../../../../../core/models/building_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';
import '../../../../../shared/widgets/uploads/document_upload_tile.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/labeled_checkbox.dart';
import '../widgets/mock_upload.dart';
import '../widgets/selection_tile.dart';

/// Step 7 — Consent and Authorization. Progressive disclosure: the
/// representative section and its uploads only appear when the applicant
/// is not the registered lot owner.
class Step7Consent extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BuildingPermitDraft draft;
  final VoidCallback onChanged;

  const Step7Consent({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step7Consent> createState() => _Step7ConsentState();
}

class _Step7ConsentState extends State<Step7Consent> {
  late final TextEditingController _repFullName;
  late final TextEditingController _repAddress;
  late final TextEditingController _repCtcNumber;
  late final TextEditingController _repCtcPlaceIssued;
  late final TextEditingController _repContactNumber;
  late final TextEditingController _relationship;
  late final TextEditingController _authorizationType;
  late final TextEditingController _applicantCtcNumber;
  late final TextEditingController _applicantCtcPlaceIssued;

  ConsentDetails get _consent => widget.draft.consent;

  @override
  void initState() {
    super.initState();
    _repFullName = TextEditingController(text: _consent.representativeFullName);
    _repAddress = TextEditingController(text: _consent.representativeAddress);
    _repCtcNumber = TextEditingController(
      text: _consent.representativeCtcNumber,
    );
    _repCtcPlaceIssued = TextEditingController(
      text: _consent.representativeCtcPlaceIssued,
    );
    _repContactNumber = TextEditingController(
      text: _consent.representativeContactNumber,
    );
    _relationship = TextEditingController(
      text: _consent.relationshipToApplicant,
    );
    _authorizationType = TextEditingController(
      text: _consent.authorizationType,
    );
    _applicantCtcNumber = TextEditingController(
      text: _consent.applicantCtcNumber,
    );
    _applicantCtcPlaceIssued = TextEditingController(
      text: _consent.applicantCtcPlaceIssued,
    );
  }

  @override
  void dispose() {
    _repFullName.dispose();
    _repAddress.dispose();
    _repCtcNumber.dispose();
    _repCtcPlaceIssued.dispose();
    _repContactNumber.dispose();
    _relationship.dispose();
    _authorizationType.dispose();
    _applicantCtcNumber.dispose();
    _applicantCtcPlaceIssued.dispose();
    super.dispose();
  }

  void _setIsOwner(bool value) {
    setState(() => _consent.isRegisteredOwner = value);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final answered = _consent.isRegisteredOwner != null;
    final isRepresentative = _consent.isRegisteredOwner == false;

    return Form(
      key: widget.formKey,
      child: FormScrollScaffold(
        centerVertically: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Are you the registered lot owner?',
              style: AppTypography.cardTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectionTile(
              title: 'Yes, I am the registered lot owner',
              selected: _consent.isRegisteredOwner == true,
              onTap: () => _setIsOwner(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectionTile(
              title: 'No, I am filing through a representative',
              selected: _consent.isRegisteredOwner == false,
              onTap: () => _setIsOwner(false),
            ),

            if (isRepresentative) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Lot Owner or Authorized Representative',
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _repFullName,
                label: 'Full Name',
                textCapitalization: TextCapitalization.words,
                validator: (v) => isRepresentative
                    ? Validators.required(
                        v,
                        fieldLabel: "Representative's name",
                      )
                    : null,
                onChanged: (v) {
                  _consent.representativeFullName = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _repAddress,
                label: 'Address',
                validator: (v) => isRepresentative
                    ? Validators.required(v, fieldLabel: 'Address')
                    : null,
                onChanged: (v) {
                  _consent.representativeAddress = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _repCtcNumber,
                label: 'CTC Number',
                hint: 'Community Tax Certificate (Cedula)',
                validator: (v) => isRepresentative
                    ? Validators.required(v, fieldLabel: 'CTC number')
                    : null,
                onChanged: (v) {
                  _consent.representativeCtcNumber = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DatePickerField(
                label: 'CTC Date Issued',
                value: _consent.representativeCtcDateIssued,
                validator: (v) => isRepresentative && v == null
                    ? 'Please select the CTC date issued.'
                    : null,
                onChanged: (v) {
                  setState(() => _consent.representativeCtcDateIssued = v);
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _repCtcPlaceIssued,
                label: 'CTC Place Issued',
                validator: (v) => isRepresentative
                    ? Validators.required(v, fieldLabel: 'CTC place issued')
                    : null,
                onChanged: (v) {
                  _consent.representativeCtcPlaceIssued = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _repContactNumber,
                label: 'Contact Number',
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    isRepresentative ? Validators.philippineMobile(v) : null,
                onChanged: (v) {
                  _consent.representativeContactNumber = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _relationship,
                label: 'Relationship to Applicant',
                validator: (v) => isRepresentative
                    ? Validators.required(
                        v,
                        fieldLabel: 'Relationship to applicant',
                      )
                    : null,
                onChanged: (v) {
                  _consent.relationshipToApplicant = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _authorizationType,
                label: 'Authorization Type',
                hint: 'e.g. Special Power of Attorney',
                validator: (v) => isRepresentative
                    ? Validators.required(v, fieldLabel: 'Authorization type')
                    : null,
                onChanged: (v) {
                  _consent.authorizationType = v;
                  widget.onChanged();
                },
              ),

              const SizedBox(height: AppSpacing.xl),
              Text('Uploads', style: AppTypography.cardTitle),
              const SizedBox(height: AppSpacing.md),
              DocumentUploadTile(
                label: "Owner's Valid Government ID",
                allowReplace: true,
                document: _consent.ownerValidIdUpload,
                onUpload: () {
                  setState(
                    () => _consent.ownerValidIdUpload = createMockDocument(
                      "Owner's Valid Government ID",
                    ),
                  );
                  widget.onChanged();
                },
                onRemove: () {
                  setState(() => _consent.ownerValidIdUpload = null);
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              DocumentUploadTile(
                label: "Applicant's Valid Government ID",
                allowReplace: true,
                document: _consent.applicantValidIdUpload,
                onUpload: () {
                  setState(
                    () => _consent.applicantValidIdUpload = createMockDocument(
                      "Applicant's Valid Government ID",
                    ),
                  );
                  widget.onChanged();
                },
                onRemove: () {
                  setState(() => _consent.applicantValidIdUpload = null);
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              DocumentUploadTile(
                label: 'Authorization Letter or Special Power of Attorney',
                allowReplace: true,
                document: _consent.authorizationLetterUpload,
                onUpload: () {
                  setState(
                    () => _consent.authorizationLetterUpload =
                        createMockDocument('Authorization Letter or SPA'),
                  );
                  widget.onChanged();
                },
                onRemove: () {
                  setState(() => _consent.authorizationLetterUpload = null);
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              DocumentUploadTile(
                label: 'Proof of Ownership or Consent',
                isRequired: false,
                allowReplace: true,
                document: _consent.proofOfOwnershipUpload,
                onUpload: () {
                  setState(
                    () => _consent.proofOfOwnershipUpload = createMockDocument(
                      'Proof of Ownership or Consent',
                    ),
                  );
                  widget.onChanged();
                },
                onRemove: () {
                  setState(() => _consent.proofOfOwnershipUpload = null);
                  widget.onChanged();
                },
              ),
            ],

            if (answered) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('Applicant Confirmation', style: AppTypography.cardTitle),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _applicantCtcNumber,
                label: 'Applicant CTC Number',
                onChanged: (v) {
                  _consent.applicantCtcNumber = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DatePickerField(
                label: 'Date Issued',
                value: _consent.applicantCtcDateIssued,
                onChanged: (v) {
                  setState(() => _consent.applicantCtcDateIssued = v);
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _applicantCtcPlaceIssued,
                label: 'Place Issued',
                onChanged: (v) {
                  _consent.applicantCtcPlaceIssued = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledCheckbox(
                value: _consent.declarationConfirmed,
                label:
                    'I confirm that the information provided is complete and accurate.',
                onChanged: (v) {
                  setState(() => _consent.declarationConfirmed = v);
                  widget.onChanged();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
