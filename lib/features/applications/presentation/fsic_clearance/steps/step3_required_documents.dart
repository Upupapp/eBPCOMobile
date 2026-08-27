import 'package:flutter/material.dart';

import '../../../../../core/models/document_model.dart';
import '../../../../../core/models/fsic_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/uploads/document_upload_tile.dart';
import '../../../../documents/presentation/widgets/attach_document_sheet.dart';

/// Step 3 — what the BFP asks for.
///
/// Taken from the requirements catalog rather than composed here, so this step
/// and the Bureau's own checklist cannot drift apart. The conditional ones say
/// what the condition is, because presenting an optional document as mandatory
/// costs the applicant a trip they did not owe.
class Step3RequiredDocuments extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final FsicPermitDraft draft;
  final VoidCallback onChanged;

  const Step3RequiredDocuments({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step3RequiredDocuments> createState() => _Step3RequiredDocumentsState();
}

class _Step3RequiredDocumentsState extends State<Step3RequiredDocuments> {
  FSICRequiredDocuments get _documents => widget.draft.requiredDocuments;

  Widget _uploadTile({
    required String label,
    required DocumentModel? Function() getDocument,
    required void Function(DocumentModel?) setDocument,
    String? statusLabel,
    bool isRequired = true,
  }) {
    return DocumentUploadTile(
      label: label,
      isRequired: isRequired,
      statusLabel: statusLabel,
      document: getDocument(),
      allowReplace: true,
      onUpload: () async {
        final picked = await showAttachDocumentOptions(context, label: label);
        // The picker can outlive this step; setState on a defunct State throws.
        if (picked == null || !mounted) return;
        setState(() => setDocument(picked));
        widget.onChanged();
      },
      onRemove: () {
        setState(() => setDocument(null));
        widget.onChanged();
      },
    );
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
            Text(
              'The Bureau of Fire Protection reviews these — not the Building '
              'Office. Accepted formats: PDF, JPG, JPEG, PNG.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _uploadTile(
                    label: 'Land Title or Tax Declaration of the property',
                    isRequired: true,
                    getDocument: () => _documents.landTitleUpload,
                    setDocument: (d) => _documents.landTitleUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Barangay Clearance',
                    isRequired: true,
                    getDocument: () => _documents.barangayClearanceUpload,
                    setDocument: (d) => _documents.barangayClearanceUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Locational Clearance / Zoning Certification',
                    isRequired: true,
                    getDocument: () => _documents.locationalClearanceUpload,
                    setDocument: (d) =>
                        _documents.locationalClearanceUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Valid Government-Issued ID of Applicant/Owner',
                    isRequired: true,
                    getDocument: () => _documents.validGovernmentIdUpload,
                    setDocument: (d) => _documents.validGovernmentIdUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label:
                        'Endorsement from the Office of the Building Official',
                    isRequired: true,
                    getDocument: () => _documents.oboEndorsementUpload,
                    setDocument: (d) => _documents.oboEndorsementUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Certificate of Completion',
                    isRequired: true,
                    getDocument: () => _documents.completionCertificateUpload,
                    setDocument: (d) =>
                        _documents.completionCertificateUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label:
                        'Certified True Copy of the Occupancy Assessment Fee',
                    isRequired: true,
                    getDocument: () => _documents.assessmentCopyUpload,
                    setDocument: (d) => _documents.assessmentCopyUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: "Owner's Written Consent",
                    isRequired: false,
                    statusLabel: 'Only if you are not the registered lot owner',
                    getDocument: () => _documents.ownerWrittenConsentUpload,
                    setDocument: (d) =>
                        _documents.ownerWrittenConsentUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'As-Built Plan',
                    isRequired: false,
                    statusLabel: 'Only if necessary',
                    getDocument: () => _documents.asBuiltPlanUpload,
                    setDocument: (d) => _documents.asBuiltPlanUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label:
                        'Fire Safety Compliance and Commissioning Report (FSCCR)',
                    isRequired: false,
                    statusLabel: 'Only if necessary',
                    getDocument: () => _documents.commissioningReportUpload,
                    setDocument: (d) =>
                        _documents.commissioningReportUpload = d,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
