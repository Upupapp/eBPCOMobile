import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/building_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/alerts/app_alert.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/uploads/document_upload_tile.dart';
import '../widgets/mock_upload.dart';

/// Step 8 — Document Upload. Requirements are organized into expandable
/// categories (Official Forms, Property Documents, Plans, Clearances) so
/// the ~30-item official checklist doesn't overwhelm a single scrolling
/// list. Nothing is uploaded to a server — [createMockDocument] simulates
/// the attachment the same way the rest of the app does.
class Step8Documents extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BuildingPermitDraft draft;
  final VoidCallback onChanged;

  const Step8Documents({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step8Documents> createState() => _Step8DocumentsState();
}

class _Step8DocumentsState extends State<Step8Documents> {
  void _upload(BuildingPermitDocumentSlot slot) {
    setState(() => slot.document = createMockDocument(slot.label));
    widget.onChanged();
  }

  void _remove(BuildingPermitDocumentSlot slot) {
    setState(() => slot.document = null);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final missing = widget.draft.missingRequiredDocuments;

    return Form(
      key: widget.formKey,
      child: FormScrollScaffold(
        centerVertically: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (missing.isNotEmpty)
              AppAlert(
                variant: AppAlertVariant.warning,
                title:
                    '${missing.length} required document${missing.length == 1 ? '' : 's'} missing',
                message:
                    'You must upload every "Required" document before you can '
                    'continue: ${missing.map((s) => s.label).join(', ')}.',
              )
            else
              const AppAlert(
                variant: AppAlertVariant.success,
                title: 'All required documents are uploaded',
                message:
                    'You can still review or replace any attachment below.',
              ),
            const SizedBox(height: AppSpacing.lg),
            ...widget.draft.documentCategories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _DocumentCategorySection(
                  category: category,
                  onUpload: _upload,
                  onRemove: _remove,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const AppAlert(
              variant: AppAlertVariant.info,
              message:
                  'Plans, specifications, and applicable permits must be signed '
                  'and sealed by the corresponding licensed professionals before '
                  'submission.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCategorySection extends StatelessWidget {
  final BuildingPermitDocumentCategory category;
  final ValueChanged<BuildingPermitDocumentSlot> onUpload;
  final ValueChanged<BuildingPermitDocumentSlot> onRemove;

  const _DocumentCategorySection({
    required this.category,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final uploadedCount = category.slots
        .where((slot) => slot.document != null)
        .length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        title: Text(category.title, style: AppTypography.cardTitle),
        subtitle: Text(
          '$uploadedCount of ${category.slots.length} uploaded',
          style: AppTypography.helper,
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textMuted,
        children: [
          for (final slot in category.slots) ...[
            DocumentUploadTile(
              label: slot.label,
              // Only genuinely optional items get the "(optional)" label
              // suffix — "required when applicable" is communicated via
              // statusLabel instead, so the two don't contradict.
              isRequired: slot.requirement != DocumentRequirement.optional,
              statusLabel: slot.requirement.label,
              allowReplace: true,
              document: slot.document,
              onUpload: () => onUpload(slot),
              onRemove: () => onRemove(slot),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
