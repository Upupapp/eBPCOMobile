import 'package:flutter/material.dart';

import '../../../../../core/models/document_model.dart';
import '../../../../../core/models/zoning_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/uploads/document_upload_tile.dart';
import '../../../../documents/presentation/widgets/attach_document_sheet.dart';

/// Step 4 — the sixteen documents FM-MPD-12 asks for.
///
/// Taken from the requirements catalog rather than composed here, so this step
/// and the office's own checklist cannot drift apart. Thirteen are required;
/// the three conditional ones say what the condition is, because presenting an
/// optional document as mandatory costs the applicant a trip they did not owe.
class Step4RequiredDocuments extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final ZoningPermitDraft draft;
  final VoidCallback onChanged;

  const Step4RequiredDocuments({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step4RequiredDocuments> createState() => _Step4RequiredDocumentsState();
}

class _Step4RequiredDocumentsState extends State<Step4RequiredDocuments> {
  ZoningRequiredDocuments get _documents => widget.draft.requiredDocuments;

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
              'The Municipal Planning and Development Office reviews these. '
              'Accepted formats: PDF, JPG, JPEG, PNG.',
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
                    label: 'Proof of Ownership',
                    isRequired: true,
                    getDocument: () => _documents.proofOfOwnershipUpload,
                    setDocument: (d) => _documents.proofOfOwnershipUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Tax Declaration / Certificate of Title (COT) / OCT',
                    isRequired: true,
                    getDocument: () => _documents.taxDeclarationUpload,
                    setDocument: (d) => _documents.taxDeclarationUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Land Tax Receipt (Current Year)',
                    isRequired: true,
                    getDocument: () => _documents.landTaxReceiptUpload,
                    setDocument: (d) => _documents.landTaxReceiptUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Cedula (Photocopy)',
                    isRequired: true,
                    getDocument: () => _documents.cedulaUpload,
                    setDocument: (d) => _documents.cedulaUpload = d,
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
                        'Notarized Letter Request addressed to the Zoning Administrator',
                    isRequired: true,
                    getDocument: () => _documents.letterRequestUpload,
                    setDocument: (d) => _documents.letterRequestUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Site Development Plan',
                    isRequired: true,
                    getDocument: () => _documents.siteDevelopmentPlanUpload,
                    setDocument: (d) =>
                        _documents.siteDevelopmentPlanUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Vicinity Map',
                    isRequired: true,
                    getDocument: () => _documents.vicinityMapUpload,
                    setDocument: (d) => _documents.vicinityMapUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Sketch Plan of the House',
                    isRequired: true,
                    getDocument: () => _documents.sketchPlanUpload,
                    setDocument: (d) => _documents.sketchPlanUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Bill of Materials',
                    isRequired: true,
                    getDocument: () => _documents.billOfMaterialsUpload,
                    setDocument: (d) => _documents.billOfMaterialsUpload = d,
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
                    label: 'Barangay Building Clearance',
                    isRequired: true,
                    getDocument: () =>
                        _documents.barangayBuildingClearanceUpload,
                    setDocument: (d) =>
                        _documents.barangayBuildingClearanceUpload = d,
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
                    label: 'DPWH Clearance',
                    isRequired: false,
                    statusLabel: 'Only if applicable',
                    getDocument: () => _documents.dpwhClearanceUpload,
                    setDocument: (d) => _documents.dpwhClearanceUpload = d,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _uploadTile(
                    label: 'Environmental Compliance Certificate (ECC)',
                    isRequired: false,
                    statusLabel: 'Only if applicable',
                    getDocument: () =>
                        _documents.environmentalComplianceCertificateUpload,
                    setDocument: (d) =>
                        _documents.environmentalComplianceCertificateUpload = d,
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
