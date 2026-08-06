import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/scanned_page_draft.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'mock_document_page.dart';

/// Multi-page scanning UI: a filmstrip of captured pages plus the controls
/// (Add Page / Delete Page / Reorder / Continue) needed to manage them.
/// The widget and its callbacks are shaped so a real multi-page session is
/// a data change, not a UI rewrite.
class PageThumbnailStrip extends StatelessWidget {
  final List<ScannedPageDraft> pages;
  final String? selectedPageId;
  final ValueChanged<String> onSelectPage;
  final VoidCallback onAddPage;
  final VoidCallback onDeleteSelectedPage;
  final VoidCallback onReorderTap;
  final VoidCallback onContinue;

  /// False while a crop/rotate/other page-mutating operation is in
  /// flight — disables every action here so the user can't add, delete,
  /// reorder, or continue past a page whose image is still being
  /// rewritten on a background isolate.
  final bool enabled;

  const PageThumbnailStrip({
    super.key,
    required this.pages,
    required this.selectedPageId,
    required this.onSelectPage,
    required this.onAddPage,
    required this.onDeleteSelectedPage,
    required this.onReorderTap,
    required this.onContinue,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pages (${pages.length})', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pages.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == pages.length) {
                return _AddPageTile(onTap: enabled ? onAddPage : null);
              }
              final page = pages[index];
              final selected = page.id == selectedPageId;
              return _PageThumbnail(
                pageNumber: index + 1,
                selected: selected,
                imagePath: page.imagePath,
                onTap: enabled ? () => onSelectPage(page.id) : null,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            TextButton.icon(
              onPressed: enabled && pages.length > 1
                  ? onDeleteSelectedPage
                  : null,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete Page'),
            ),
            TextButton.icon(
              onPressed: enabled ? onReorderTap : null,
              icon: const Icon(Icons.reorder, size: 18),
              label: const Text('Reorder'),
            ),
            TextButton.icon(
              onPressed: enabled ? onContinue : null,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Continue'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PageThumbnail extends StatelessWidget {
  final int pageNumber;
  final bool selected;
  final String? imagePath;
  final VoidCallback? onTap;

  const _PageThumbnail({
    required this.pageNumber,
    required this.selected,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page $pageNumber',
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        child: Container(
          width: 76,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusXs,
                ),
                child: imagePath == null
                    ? const MockDocumentPage()
                    : Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const MockDocumentPage(),
                      ),
              ),
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusPill,
                    ),
                  ),
                  child: Text(
                    '$pageNumber',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textOnPrimary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPageTile extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddPageTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Add Page',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        child: Container(
          width: 76,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.add, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
