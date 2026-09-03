import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/saved_document_model.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/avatars/app_avatar.dart';
import '../../../../shared/widgets/cards/app_card.dart';

enum DocumentCardAction {
  preview,
  rename,
  changeCategory,
  setExpiry,
  useForApplication,
  viewInfo,
  remove,
}

final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

String formatFileSize(int bytes) {
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// One document row in the My Documents list, following the app's
/// existing rounded-card design. Tapping the card previews/selects the
/// document (behavior owned by the caller); the three-dot menu exposes
/// every other management action.
class DocumentCard extends StatelessWidget {
  final SavedDocumentModel document;
  final VoidCallback onTap;
  final ValueChanged<DocumentCardAction> onAction;
  final bool showUseForApplication;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onAction,
    this.showUseForApplication = true,
  });

  IconData get _fileIcon => document.fileType.isImage
      ? Icons.image_outlined
      : Icons.picture_as_pdf_outlined;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            size: 44,
            icon: _fileIcon,
            iconSize: 22,
            backgroundColor: AppColors.surfaceMuted,
            foregroundColor: AppColors.secondaryBlue,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: AppTypography.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  document.category.label,
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    Text(
                      formatFileSize(document.fileSizeBytes),
                      style: AppTypography.caption,
                    ),
                    Text(
                      'Imported ${_dateFormat.format(document.dateImported)}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                if (document.isTimeBound) ...[
                  const SizedBox(height: 4),
                  _ExpiryChip(document: document),
                ],
              ],
            ),
          ),
          PopupMenuButton<DocumentCardAction>(
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
            onSelected: onAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: DocumentCardAction.preview,
                child: Text('Preview'),
              ),
              const PopupMenuItem(
                value: DocumentCardAction.rename,
                child: Text('Rename'),
              ),
              PopupMenuItem(
                value: DocumentCardAction.setExpiry,
                child: Text(
                  document.isTimeBound
                      ? 'Change expiry date'
                      : 'Set expiry date',
                ),
              ),
              const PopupMenuItem(
                value: DocumentCardAction.changeCategory,
                child: Text('Change Category'),
              ),
              if (showUseForApplication)
                const PopupMenuItem(
                  value: DocumentCardAction.useForApplication,
                  child: Text('Use for Application'),
                ),
              const PopupMenuItem(
                value: DocumentCardAction.viewInfo,
                child: Text('View File Information'),
              ),
              const PopupMenuItem(
                value: DocumentCardAction.remove,
                child: Text(
                  'Remove from My Documents',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Expiry state, shown on the card rather than only in the detail sheet.
///
/// An expired barangay clearance or a stale Certified True Copy gets an
/// application returned, and the cost of that lands on the applicant in
/// weeks. It is worth a line on the row they are about to attach from.
class _ExpiryChip extends StatelessWidget {
  final SavedDocumentModel document;

  const _ExpiryChip({required this.document});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = document.daysUntilExpiry(now)!;
    final expired = document.isExpired(now);
    final soon = document.needsAttention(now);

    final tone = expired
        ? AppColors.statusRejected
        : soon
        ? AppColors.statusPending
        : AppColors.textSecondary;

    final label = expired
        ? 'Expired ${_dateFormat.format(document.expiryDate!)}'
        : days == 0
        ? 'Expires today'
        : soon
        ? 'Expires in \$days days'
        : 'Valid to ${_dateFormat.format(document.expiryDate!)}';

    return Semantics(
      label: expired ? '\$label. This document will not be accepted.' : label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expired ? Icons.error_outline : Icons.schedule_outlined,
            size: 13,
            color: tone,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: tone,
                fontWeight: soon ? FontWeight.w600 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
