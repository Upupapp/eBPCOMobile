import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/document_model.dart';
import '../../../core/theme/app_typography.dart';
import '../avatars/app_avatar.dart';
import '../cards/app_card.dart';

/// A single requirement/attachment row used by the New Application wizard's
/// document checklist and the payment flow's proof-of-payment step. No real
/// file picker is used — [onUpload] fabricates a mock [DocumentModel].
class DocumentUploadTile extends StatelessWidget {
  final String label;
  final bool isRequired;
  final DocumentModel? document;
  final VoidCallback onUpload;
  final VoidCallback? onRemove;

  const DocumentUploadTile({
    super.key,
    required this.label,
    this.isRequired = true,
    this.document,
    required this.onUpload,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = document != null;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            size: 40,
            icon: uploaded ? Icons.check_circle : Icons.description_outlined,
            iconSize: 20,
            backgroundColor: uploaded
                ? AppColors.statusApprovedBg
                : AppColors.surfaceMuted,
            foregroundColor: uploaded
                ? AppColors.statusApproved
                : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRequired ? label : '$label (optional)',
                  style: AppTypography.bodyStrong,
                ),
                const SizedBox(height: 2),
                Text(
                  uploaded ? document!.fileName : 'Not yet uploaded',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (uploaded)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.textMuted,
              tooltip: 'Remove attachment',
            )
          else
            OutlinedButton(onPressed: onUpload, child: const Text('Upload')),
        ],
      ),
    );
  }
}
