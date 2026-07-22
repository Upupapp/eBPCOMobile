import 'package:flutter/material.dart';

import '../../../../../core/models/building_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/alerts/app_alert.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';
import '../widgets/selection_tile.dart';

/// Step 3 — Scope of Work. Multiple options may apply, so this is a
/// multi-select checklist (matching the official form) preselected from
/// the project type chosen on the Applications tab where a direct mapping
/// exists.
class Step3ScopeOfWork extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BuildingPermitDraft draft;
  final VoidCallback onChanged;

  const Step3ScopeOfWork({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step3ScopeOfWork> createState() => _Step3ScopeOfWorkState();
}

class _Step3ScopeOfWorkState extends State<Step3ScopeOfWork> {
  late final TextEditingController _otherDetail;

  @override
  void initState() {
    super.initState();
    _preselectFromProjectScope();
    _otherDetail = TextEditingController(
      text: widget.draft.scopeOfWorkOtherDetail,
    );
  }

  void _preselectFromProjectScope() {
    if (widget.draft.scopeOfWork.isNotEmpty) return;
    final mapped = mapProjectScopeToScopeOfWork(widget.draft.projectScope);
    if (mapped != null) {
      widget.draft.scopeOfWork.add(mapped);
    }
  }

  @override
  void dispose() {
    _otherDetail.dispose();
    super.dispose();
  }

  void _toggle(ScopeOfWorkOption option) {
    setState(() {
      if (widget.draft.scopeOfWork.contains(option)) {
        widget.draft.scopeOfWork.remove(option);
      } else {
        widget.draft.scopeOfWork.add(option);
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isDemolition =
        widget.draft.projectScope == BuildingPermitProjectScope.demolition;

    return Form(
      key: widget.formKey,
      child: FormScrollScaffold(
        centerVertically: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.draft.projectScope != null) ...[
              AppAlert(
                variant: AppAlertVariant.info,
                title: 'Project selected from Applications',
                message: isDemolition
                    ? 'You started this application from "Demolition." The '
                          'official checklist does not have a matching item, so '
                          'please select the closest applicable scope below or '
                          'choose "Others" and describe the demolition work.'
                    : '${widget.draft.projectScope!.label} has been matched to '
                          '"${mapProjectScopeToScopeOfWork(widget.draft.projectScope)?.label}" '
                          'below. You may adjust this selection.',
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text('Select all that apply', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            ...ScopeOfWorkOption.values.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SelectionTile(
                  title: option.label,
                  multiSelect: true,
                  selected: widget.draft.scopeOfWork.contains(option),
                  onTap: () => _toggle(option),
                ),
              ),
            ),
            if (widget.draft.scopeOfWork.contains(
              ScopeOfWorkOption.others,
            )) ...[
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _otherDetail,
                label: 'Specify Scope of Work',
                onChanged: (v) {
                  widget.draft.scopeOfWorkOtherDetail = v;
                  widget.onChanged();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
