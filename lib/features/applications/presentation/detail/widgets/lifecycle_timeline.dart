import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/application_detail.dart';
import '../../../../../core/models/lifecycle_status.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// The whole road, not just the distance travelled.
///
/// Steps the application has passed are rendered solid with their timestamp
/// and acting office; steps still ahead are rendered greyed. Showing the
/// remaining steps is the point — an applicant who can see that Fire Safety
/// and Final Approval are still to come understands their position in a way
/// that a bare "Under Review" never conveys.
///
/// Revision loops are rendered as a branch off the step that issued them
/// rather than as another entry in the sequence, so a returned application
/// does not appear to have travelled backwards or to have visited evaluation
/// twice.
class LifecycleTimeline extends StatelessWidget {
  final List<TimelineEntry> entries;
  final ApplicationLifecycleStatus currentStatus;

  const LifecycleTimeline({
    super.key,
    required this.entries,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final reached = <ApplicationLifecycleStatus, TimelineEntry>{};
    final revisions = <TimelineEntry>[];

    for (final entry in entries) {
      if (entry.status == ApplicationLifecycleStatus.revisionRequired) {
        revisions.add(entry);
        continue;
      }
      // Keep the latest occurrence, so a status revisited after a revision
      // loop shows the most recent visit rather than duplicating the row.
      final existing = reached[entry.status];
      if (existing == null || entry.occurredAt.isAfter(existing.occurredAt)) {
        reached[entry.status] = entry;
      }
    }

    final isTerminalExit =
        currentStatus == ApplicationLifecycleStatus.rejected ||
        currentStatus == ApplicationLifecycleStatus.cancelled ||
        currentStatus == ApplicationLifecycleStatus.expired;

    final steps = <Widget>[];
    for (var i = 0; i < lifecycleSequence.length; i++) {
      final status = lifecycleSequence[i];
      // Draft is an authoring state, not a processing step — showing it on a
      // filed application's timeline just adds noise.
      if (status == ApplicationLifecycleStatus.draft) continue;

      final entry = reached[status];
      final isCurrent = status == currentStatus;
      steps.add(
        _TimelineStep(
          status: status,
          entry: entry,
          isReached: entry != null,
          isCurrent: isCurrent,
          isLast: i == lifecycleSequence.length - 1,
          // A revision issued at this step branches off it.
          revisions: revisions
              .where((r) => _branchesFrom(r, status, reached))
              .toList(),
        ),
      );
    }

    if (isTerminalExit) {
      steps.add(
        _TimelineStep(
          status: currentStatus,
          entry: entries
              .where((e) => e.status == currentStatus)
              .cast<TimelineEntry?>()
              .lastOrNull,
          isReached: true,
          isCurrent: true,
          isLast: true,
          revisions: const [],
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: steps);
  }

  /// A revision belongs to the last non-revision step recorded before it.
  bool _branchesFrom(
    TimelineEntry revision,
    ApplicationLifecycleStatus status,
    Map<ApplicationLifecycleStatus, TimelineEntry> reached,
  ) {
    ApplicationLifecycleStatus? owner;
    DateTime? ownerAt;
    reached.forEach((candidate, entry) {
      if (entry.occurredAt.isAfter(revision.occurredAt)) return;
      if (ownerAt == null || entry.occurredAt.isAfter(ownerAt!)) {
        owner = candidate;
        ownerAt = entry.occurredAt;
      }
    });
    return owner == status;
  }
}

class _TimelineStep extends StatelessWidget {
  final ApplicationLifecycleStatus status;
  final TimelineEntry? entry;
  final bool isReached;
  final bool isCurrent;
  final bool isLast;
  final List<TimelineEntry> revisions;

  const _TimelineStep({
    required this.status,
    required this.entry,
    required this.isReached,
    required this.isCurrent,
    required this.isLast,
    required this.revisions,
  });

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy · h:mm a');
    final isExit =
        status == ApplicationLifecycleStatus.rejected ||
        status == ApplicationLifecycleStatus.cancelled ||
        status == ApplicationLifecycleStatus.expired;

    final markerColor = isExit && isReached
        ? AppColors.statusRejected
        : isCurrent
        ? AppColors.primary
        : isReached
        ? AppColors.statusApproved
        : AppColors.border;

    final labelColor = isReached
        ? AppColors.textPrimary
        : AppColors.textMuted;

    return Semantics(
      label:
          '${status.adminLabel}. '
          '${isCurrent ? 'Current step. ' : isReached ? 'Completed. ' : 'Not yet reached. '}'
          '${entry?.office ?? ''}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: isReached ? markerColor : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: markerColor, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isReached ? markerColor : AppColors.border,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.adminLabel,
                      style:
                          (isCurrent
                                  ? AppTypography.cardTitle
                                  : AppTypography.body)
                              .copyWith(color: labelColor),
                    ),
                    if (entry != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        format.format(entry!.occurredAt),
                        style: AppTypography.helper,
                      ),
                      if (entry!.office != null)
                        Text(entry!.office!, style: AppTypography.helper),
                    ] else if (!isReached)
                      Text('Not yet reached', style: AppTypography.helper),
                    for (final revision in revisions)
                      _RevisionBranch(entry: revision),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A returned-for-revision event, drawn as a branch off its originating step.
class _RevisionBranch extends StatelessWidget {
  final TimelineEntry entry;

  const _RevisionBranch({required this.entry});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: AppColors.statusPending, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.replay,
                size: 14,
                color: AppColors.statusPending,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Returned for revision',
                style: AppTypography.helper.copyWith(
                  color: AppColors.statusPending,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(format.format(entry.occurredAt), style: AppTypography.helper),
          if (entry.remarks != null) ...[
            const SizedBox(height: AppSpacing.xs),
            // Verbatim. An evaluator's remark is the applicant's instruction
            // set, so it is never summarised or hidden behind a "more" link.
            Text(entry.remarks!, style: AppTypography.body),
          ],
        ],
      ),
    );
  }
}
