import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/building_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/badges/status_badge.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../widgets/labeled_checkbox.dart';

enum _SectionStatus { complete, needsAttention, missingDocument }

extension on _SectionStatus {
  String get label {
    switch (this) {
      case _SectionStatus.complete:
        return 'Complete';
      case _SectionStatus.needsAttention:
        return 'Needs Attention';
      case _SectionStatus.missingDocument:
        return 'Missing Document';
    }
  }

  Color get color {
    switch (this) {
      case _SectionStatus.complete:
        return AppColors.statusApproved;
      case _SectionStatus.needsAttention:
        return AppColors.statusPending;
      case _SectionStatus.missingDocument:
        return AppColors.statusRejected;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _SectionStatus.complete:
        return AppColors.statusApprovedBg;
      case _SectionStatus.needsAttention:
        return AppColors.statusPendingBg;
      case _SectionStatus.missingDocument:
        return AppColors.statusRejectedBg;
    }
  }
}

/// Step 9 — Review Application. Summarizes every prior step with an Edit
/// action that returns to that step without clearing any entered data
/// (the draft object is shared by reference across all steps).
class Step9Review extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BuildingPermitDraft draft;
  final VoidCallback onChanged;
  final ValueChanged<int> onEditStep;

  const Step9Review({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
    required this.onEditStep,
  });

  @override
  State<Step9Review> createState() => _Step9ReviewState();
}

class _Step9ReviewState extends State<Step9Review> {
  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
  );

  BuildingPermitDraft get _draft => widget.draft;

  String _fmtDate(DateTime? date) =>
      date == null ? 'Not set' : _dateFormat.format(date);

  String _orNotProvided(String value) =>
      value.trim().isEmpty ? 'Not provided' : value;

  @override
  Widget build(BuildContext context) {
    final applicant = _draft.applicant;
    final location = _draft.location;
    final project = _draft.project;
    final professional = _draft.professional;
    final consent = _draft.consent;

    final applicantComplete =
        applicant.lastName.isNotEmpty &&
        applicant.firstName.isNotEmpty &&
        applicant.contactNumber.isNotEmpty &&
        applicant.street.isNotEmpty &&
        applicant.barangay.isNotEmpty &&
        applicant.city.isNotEmpty &&
        applicant.province.isNotEmpty &&
        applicant.zipCode.isNotEmpty &&
        applicant.formOfOwnership.isNotEmpty;

    final locationComplete =
        location.lotNumber.isNotEmpty &&
        location.tctOrOctNumber.isNotEmpty &&
        location.taxDeclarationNumber.isNotEmpty &&
        location.street.isNotEmpty &&
        location.barangay.isNotEmpty &&
        location.city.isNotEmpty &&
        location.province.isNotEmpty &&
        location.zipCode.isNotEmpty;

    final scopeComplete =
        _draft.scopeOfWork.isNotEmpty &&
        (!_draft.scopeOfWork.contains(ScopeOfWorkOption.others) ||
            _draft.scopeOfWorkOtherDetail.trim().isNotEmpty);

    final occupancyComplete =
        _draft.occupancyGroup != null &&
        (_draft.occupancyGroup != OccupancyGroup.others ||
            _draft.occupancyOtherDetail.trim().isNotEmpty);

    final projectComplete =
        project.totalFloorArea.isNotEmpty &&
        project.lotArea.isNotEmpty &&
        project.estimatedCost.isNotEmpty &&
        project.proposedConstructionDate != null &&
        project.expectedCompletionDate != null;

    final professionalComplete =
        professional.fullName.isNotEmpty &&
        professional.profession != null &&
        professional.prcNumber.isNotEmpty &&
        professional.ptrNumber.isNotEmpty &&
        professional.prcIdUpload != null &&
        professional.ptrUpload != null &&
        professional.signedSealedFormUpload != null;

    final consentComplete =
        consent.isRegisteredOwner != null &&
        consent.declarationConfirmed &&
        (consent.isRegisteredOwner == true ||
            (consent.representativeFullName.isNotEmpty &&
                consent.ownerValidIdUpload != null &&
                consent.applicantValidIdUpload != null &&
                consent.authorizationLetterUpload != null));

    final missingDocuments = _draft.missingRequiredDocuments;
    final totalDocuments = _draft.documentCategories.fold<int>(
      0,
      (sum, c) => sum + c.slots.length,
    );
    final uploadedDocuments = _draft.documentCategories.fold<int>(
      0,
      (sum, c) => sum + c.slots.where((s) => s.document != null).length,
    );

    return Form(
      key: widget.formKey,
      child: FormScrollScaffold(
        centerVertically: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReviewSection(
              title: 'Applicant Information',
              status: applicantComplete
                  ? _SectionStatus.complete
                  : _SectionStatus.needsAttention,
              onEdit: () => widget.onEditStep(0),
              rows: [
                _ReviewRow(
                  'Name',
                  _orNotProvided(
                    '${applicant.firstName} ${applicant.middleInitial} ${applicant.lastName}'
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim(),
                  ),
                ),
                _ReviewRow(
                  'Contact Number',
                  _orNotProvided(applicant.contactNumber),
                ),
                _ReviewRow(
                  'Enterprise',
                  applicant.isOwnedByEnterprise
                      ? _orNotProvided(applicant.enterpriseName)
                      : 'Not applicable',
                ),
                _ReviewRow(
                  'Form of Ownership',
                  _orNotProvided(applicant.formOfOwnership),
                ),
                _ReviewRow(
                  'Address',
                  _orNotProvided(
                    [
                      applicant.houseNumber,
                      applicant.street,
                      applicant.barangay,
                      applicant.city,
                      applicant.province,
                      applicant.zipCode,
                    ].where((s) => s.trim().isNotEmpty).join(', '),
                  ),
                ),
              ],
            ),
            _ReviewSection(
              title: 'Property Location',
              status: locationComplete
                  ? _SectionStatus.complete
                  : _SectionStatus.needsAttention,
              onEdit: () => widget.onEditStep(1),
              rows: [
                _ReviewRow(
                  'Lot / Block Number',
                  '${_orNotProvided(location.lotNumber)} / ${location.blockNumber.isEmpty ? '—' : location.blockNumber}',
                ),
                _ReviewRow(
                  'TCT / OCT Number',
                  _orNotProvided(location.tctOrOctNumber),
                ),
                _ReviewRow(
                  'Tax Declaration Number',
                  _orNotProvided(location.taxDeclarationNumber),
                ),
                _ReviewRow(
                  'Site Address',
                  _orNotProvided(
                    [
                      location.street,
                      location.barangay,
                      location.city,
                      location.province,
                      location.zipCode,
                    ].where((s) => s.trim().isNotEmpty).join(', '),
                  ),
                ),
              ],
            ),
            _ReviewSection(
              title: 'Scope of Work',
              status: scopeComplete
                  ? _SectionStatus.complete
                  : _SectionStatus.needsAttention,
              onEdit: () => widget.onEditStep(2),
              rows: [
                _ReviewRow(
                  'Selected',
                  _draft.scopeOfWork.isEmpty
                      ? 'Not provided'
                      : _draft.scopeOfWork.map((s) => s.label).join(', '),
                ),
                if (_draft.scopeOfWork.contains(ScopeOfWorkOption.others))
                  _ReviewRow(
                    'Other Details',
                    _orNotProvided(_draft.scopeOfWorkOtherDetail),
                  ),
              ],
            ),
            _ReviewSection(
              title: 'Building Use',
              status: occupancyComplete
                  ? _SectionStatus.complete
                  : _SectionStatus.needsAttention,
              onEdit: () => widget.onEditStep(3),
              rows: [
                _ReviewRow(
                  'Classification',
                  _draft.occupancyGroup?.label ?? 'Not provided',
                ),
                if (_draft.occupancyGroup == OccupancyGroup.others)
                  _ReviewRow(
                    'Other Details',
                    _orNotProvided(_draft.occupancyOtherDetail),
                  ),
                _ReviewRow(
                  'Occupancy Classification',
                  _orNotProvided(_draft.occupancyClassification),
                ),
                _ReviewRow(
                  'Number of Units',
                  _orNotProvided(_draft.numberOfUnits),
                ),
              ],
            ),
            _ReviewSection(
              title: 'Project Details',
              status: projectComplete
                  ? _SectionStatus.complete
                  : _SectionStatus.needsAttention,
              onEdit: () => widget.onEditStep(4),
              rows: [
                _ReviewRow(
                  'Total Floor Area',
                  project.totalFloorArea.isEmpty
                      ? 'Not provided'
                      : '${project.totalFloorArea} sq. m',
                ),
                _ReviewRow(
                  'Lot Area',
                  project.lotArea.isEmpty
                      ? 'Not provided'
                      : '${project.lotArea} sq. m',
                ),
                _ReviewRow(
                  'Estimated Construction Cost',
                  project.estimatedCost.isEmpty
                      ? 'Not provided'
                      : '${_currencyFormat.format(double.tryParse(project.estimatedCost) ?? 0)} (estimate)',
                ),
                _ReviewRow(
                  'Proposed Construction Date',
                  _fmtDate(project.proposedConstructionDate),
                ),
                _ReviewRow(
                  'Expected Completion Date',
                  _fmtDate(project.expectedCompletionDate),
                ),
              ],
            ),
            _ReviewSection(
              title: 'Professional Information',
              status: professionalComplete
                  ? _SectionStatus.complete
                  : _SectionStatus.needsAttention,
              onEdit: () => widget.onEditStep(5),
              rows: [
                _ReviewRow('Name', _orNotProvided(professional.fullName)),
                _ReviewRow(
                  'Profession',
                  professional.profession?.label ?? 'Not provided',
                ),
                _ReviewRow(
                  'PRC Number',
                  _orNotProvided(professional.prcNumber),
                ),
                _ReviewRow(
                  'PTR Number',
                  _orNotProvided(professional.ptrNumber),
                ),
                _ReviewRow(
                  'Uploads',
                  '${[professional.prcIdUpload, professional.ptrUpload, professional.signedSealedFormUpload].where((d) => d != null).length} of 3 attached',
                ),
              ],
            ),
            _ReviewSection(
              title: 'Consent and Authorization',
              status: consentComplete
                  ? _SectionStatus.complete
                  : _SectionStatus.needsAttention,
              onEdit: () => widget.onEditStep(6),
              rows: [
                _ReviewRow(
                  'Registered Lot Owner',
                  consent.isRegisteredOwner == null
                      ? 'Not answered'
                      : (consent.isRegisteredOwner!
                            ? 'Yes'
                            : 'No — filing via representative'),
                ),
                if (consent.isRegisteredOwner == false)
                  _ReviewRow(
                    'Representative',
                    _orNotProvided(consent.representativeFullName),
                  ),
                _ReviewRow(
                  'Declaration Confirmed',
                  consent.declarationConfirmed ? 'Yes' : 'No',
                ),
              ],
            ),
            _ReviewSection(
              title: 'Uploaded Documents',
              status: missingDocuments.isEmpty
                  ? _SectionStatus.complete
                  : _SectionStatus.missingDocument,
              onEdit: () => widget.onEditStep(7),
              rows: [
                _ReviewRow(
                  'Uploaded',
                  '$uploadedDocuments of $totalDocuments documents',
                ),
                _ReviewRow(
                  'Missing Required',
                  missingDocuments.isEmpty
                      ? 'None'
                      : missingDocuments.map((d) => d.label).join(', '),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            Text('Declarations', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.xs),
            LabeledCheckbox(
              value: _draft.declareTrueAndCorrect,
              label:
                  'I certify that the information provided is true and correct.',
              onChanged: (v) {
                setState(() => _draft.declareTrueAndCorrect = v);
                widget.onChanged();
              },
            ),
            LabeledCheckbox(
              value: _draft.declareUnderstandDelay,
              label:
                  'I understand that incomplete or inaccurate information may delay the application.',
              onChanged: (v) {
                setState(() => _draft.declareUnderstandDelay = v);
                widget.onChanged();
              },
            ),
            LabeledCheckbox(
              value: _draft.declareSignedSealed,
              label:
                  'I confirm that applicable plans and documents are signed and sealed by licensed professionals.',
              onChanged: (v) {
                setState(() => _draft.declareSignedSealed = v);
                widget.onChanged();
              },
            ),
            LabeledCheckbox(
              value: _draft.declareDataPrivacy,
              label:
                  'I agree to the Data Privacy notice and application terms.',
              onChanged: (v) {
                setState(() => _draft.declareDataPrivacy = v);
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow {
  final String label;
  final String value;
  const _ReviewRow(this.label, this.value);
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final _SectionStatus status;
  final VoidCallback onEdit;
  final List<_ReviewRow> rows;

  const _ReviewSection({
    required this.title,
    required this.status,
    required this.onEdit,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTypography.cardTitle)),
              StatusBadge(
                label: status.label,
                color: status.color,
                backgroundColor: status.backgroundColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.label, style: AppTypography.caption),
                  Text(row.value, style: AppTypography.body),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
            ),
          ),
        ],
      ),
    );
  }
}
