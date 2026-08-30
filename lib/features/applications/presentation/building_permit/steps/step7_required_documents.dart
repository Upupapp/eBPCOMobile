import 'package:flutter/material.dart';

import '../../../../../core/models/building_permit_model.dart';
import '../../../../../core/models/document_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/layout/expandable_section.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/uploads/document_file_preview_screen.dart';
import '../../../../../shared/widgets/uploads/document_upload_tile.dart';
import '../../../../documents/presentation/widgets/attach_document_sheet.dart';

/// Step 7 — Required Documents: the full document-checklist annex from the
/// Unified Application Form, grouped into the four official categories.
/// Each category is an [ExpandableSection] so the long checklist stays
/// scannable instead of one uninterrupted list of uploads.
class Step7RequiredDocuments extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BuildingPermitDraft draft;
  final VoidCallback onChanged;

  const Step7RequiredDocuments({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step7RequiredDocuments> createState() => _Step7RequiredDocumentsState();
}

class _Step7RequiredDocumentsState extends State<Step7RequiredDocuments> {
  RequiredDocuments get _documents => widget.draft.requiredDocuments;

  Widget _uploadTile({
    required String label,
    required DocumentModel? Function() getDocument,
    required void Function(DocumentModel?) setDocument,
    bool isRequired = true,
    String? statusLabel,
  }) {
    final document = getDocument();
    return DocumentUploadTile(
      label: label,
      isRequired: isRequired,
      statusLabel: statusLabel,
      document: document,
      allowReplace: true,
      onUpload: () async {
        final result = await showAttachDocumentOptions(context, label: label);
        if (result == null) return;
        // The picker can outlive this step; setState on a defunct State throws.
        if (!mounted) return;
        setState(() => setDocument(result));
        widget.onChanged();
      },
      onPreview: document == null
          ? null
          : () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => DocumentFilePreviewScreen(document: document),
              ),
            ),
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
              'Upload clear copies of every document below. Accepted '
              'formats: PDF, JPG, JPEG, PNG.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            ExpandableSection(
              title: 'Property Documents',
              initiallyExpanded: true,
              children: [
                _uploadTile(
                  label: 'Signed Unified Application Form',
                  getDocument: () => _documents.unifiedApplicationFormUpload,
                  setDocument: (d) =>
                      _documents.unifiedApplicationFormUpload = d,
                ),
                // The checklist's first line, with its own alternatives. The
                // app demanded a title specifically, so an applicant building
                // on leased land or land taken by deed could not file at all.
                _uploadTile(
                  label: 'Proof of ownership',
                  statusLabel:
                      'Required — Certified True Copy of the OCT/TCT, or a '
                      'deed of sale, deed of donation, lease contract or '
                      'assignment of rights',
                  getDocument: () => _documents.landTitleUpload,
                  setDocument: (d) => _documents.landTitleUpload = d,
                ),
                _uploadTile(
                  label: 'Valid ID of Applicant and Owner of Lot',
                  getDocument: () =>
                      _documents.validIdOfApplicantAndOwnerUpload,
                  setDocument: (d) =>
                      _documents.validIdOfApplicantAndOwnerUpload = d,
                ),
                _uploadTile(
                  label: 'Tax Declaration',
                  isRequired: false,
                  statusLabel:
                      'Optional — or use it as your proof of ownership',
                  getDocument: () => _documents.taxDeclarationUpload,
                  setDocument: (d) => _documents.taxDeclarationUpload = d,
                ),
                _uploadTile(
                  label: 'Real Property Tax Receipt',
                  isRequired: false,
                  statusLabel: 'Optional — not on the office’s checklist',
                  getDocument: () => _documents.realPropertyTaxReceiptUpload,
                  setDocument: (d) =>
                      _documents.realPropertyTaxReceiptUpload = d,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ExpandableSection(
              title: 'Technical Documents',
              children: [
                _uploadTile(
                  label: 'Plans',
                  getDocument: () => _documents.plansUpload,
                  setDocument: (d) => _documents.plansUpload = d,
                ),
                _uploadTile(
                  label: 'Specifications',
                  getDocument: () => _documents.specificationsUpload,
                  setDocument: (d) => _documents.specificationsUpload = d,
                ),
                _uploadTile(
                  label: 'Survey Plan',
                  getDocument: () => _documents.surveyPlanUpload,
                  setDocument: (d) => _documents.surveyPlanUpload = d,
                ),
                _uploadTile(
                  label: 'Cost Estimate',
                  getDocument: () => _documents.costEstimateUpload,
                  setDocument: (d) => _documents.costEstimateUpload = d,
                ),
                _uploadTile(
                  label: 'Structural Design and Analysis',
                  getDocument: () =>
                      _documents.structuralDesignAndAnalysisUpload,
                  setDocument: (d) =>
                      _documents.structuralDesignAndAnalysisUpload = d,
                ),
                _uploadTile(
                  label: 'Soil Analysis / Plate Load Test',
                  getDocument: () => _documents.soilAnalysisUpload,
                  setDocument: (d) => _documents.soilAnalysisUpload = d,
                ),
                _uploadTile(
                  label: 'Bill of Materials',
                  isRequired: false,
                  statusLabel: 'Optional — not on the office’s checklist',
                  getDocument: () => _documents.billOfMaterialsUpload,
                  setDocument: (d) => _documents.billOfMaterialsUpload = d,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ExpandableSection(
              title: 'Professional Documents',
              children: [
                _uploadTile(
                  label: 'PRC ID',
                  getDocument: () => _documents.prcIdChecklistUpload,
                  setDocument: (d) => _documents.prcIdChecklistUpload = d,
                ),
                _uploadTile(
                  label: 'PTR',
                  getDocument: () => _documents.ptrChecklistUpload,
                  setDocument: (d) => _documents.ptrChecklistUpload = d,
                ),
                _uploadTile(
                  label: 'Signed Forms',
                  getDocument: () => _documents.signedFormsUpload,
                  setDocument: (d) => _documents.signedFormsUpload = d,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ExpandableSection(
              title: 'Government Clearances',
              children: [
                _uploadTile(
                  label: 'Barangay Clearance',
                  isRequired: false,
                  statusLabel: 'Optional — not on the office’s checklist',
                  getDocument: () => _documents.barangayClearanceUpload,
                  setDocument: (d) => _documents.barangayClearanceUpload = d,
                ),
                _uploadTile(
                  label: 'Zoning Clearance',
                  getDocument: () => _documents.zoningClearanceUpload,
                  setDocument: (d) => _documents.zoningClearanceUpload = d,
                ),
                _uploadTile(
                  label: 'Construction Safety and Health Program (DOLE)',
                  getDocument: () => _documents.constructionSafetyProgramUpload,
                  setDocument: (d) =>
                      _documents.constructionSafetyProgramUpload = d,
                ),
                _uploadTile(
                  label: 'Road Clearance (DPWH / PEO)',
                  getDocument: () => _documents.roadClearanceUpload,
                  setDocument: (d) => _documents.roadClearanceUpload = d,
                ),
                _uploadTile(
                  label: 'Fire-Related Requirements',
                  getDocument: () => _documents.fireRelatedRequirementsUpload,
                  setDocument: (d) =>
                      _documents.fireRelatedRequirementsUpload = d,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
