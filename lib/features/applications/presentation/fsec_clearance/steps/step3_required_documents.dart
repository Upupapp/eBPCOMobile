import 'package:flutter/material.dart';

import '../../../../../core/models/document_model.dart';
import '../../../../../core/models/fsec_permit_model.dart';
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
  final FsecPermitDraft draft;
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
  FSECRequiredDocuments get _documents => widget.draft.requiredDocuments;

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
                    label: 'Three (3) complete sets of proposed plans',
                    isRequired: true,
                    statusLabel:
                        'Architectural, Civil/Structural, Electrical, Mechanical, Plumbing, Electronics, Sanitary and Fire Protection',
                    getDocument: () => _documents.planSetUpload,
                    setDocument: (d) => _documents.planSetUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Cost Estimate, signed, sealed and notarised',
                    isRequired: true,
                    getDocument: () => _documents.costEstimateUpload,
                    setDocument: (d) => _documents.costEstimateUpload = d,
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
                    label: 'Fire Safety Compliance Report (FSCR)',
                    isRequired: false,
                    statusLabel: 'Only if necessary',
                    getDocument: () =>
                        _documents.fireSafetyComplianceReportUpload,
                    setDocument: (d) =>
                        _documents.fireSafetyComplianceReportUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Fire Safety Clearance for Hot Work Operations',
                    isRequired: false,
                    statusLabel: 'Only if required',
                    getDocument: () => _documents.hotWorksClearanceUpload,
                    setDocument: (d) => _documents.hotWorksClearanceUpload = d,
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
