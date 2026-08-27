import 'package:flutter/material.dart';

import '../../../../../core/models/zoning_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';

/// Step 3 — what the applicant intends to do with the lot.
///
/// This is the substance of a locational clearance: the Zoning Officer is
/// deciding whether the proposed use is permitted in the zone the lot sits in,
/// not whether the paperwork is tidy.
class Step3ProposedUse extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final ZoningPermitDraft draft;
  final VoidCallback onChanged;

  const Step3ProposedUse({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step3ProposedUse> createState() => _Step3ProposedUseState();
}

class _Step3ProposedUseState extends State<Step3ProposedUse> {
  ZoningProposedUse get _use => widget.draft.proposedUse;

  late final _proposedUse = TextEditingController(text: _use.proposedUse);
  late final _projectDescription = TextEditingController(
    text: _use.projectDescription,
  );
  late final _existingUse = TextEditingController(text: _use.existingUse);
  late final _floorArea = TextEditingController(text: _use.floorArea);
  late final _estimatedProjectCost = TextEditingController(
    text: _use.estimatedProjectCost,
  );

  @override
  void dispose() {
    for (final controller in [
      _proposedUse,
      _projectDescription,
      _existingUse,
      _floorArea,
      _estimatedProjectCost,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: FormScrollScaffold(
        centerVertically: false,
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _proposedUse,
                label: 'Proposed Use *',
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'Proposed Use'),
                onChanged: (v) {
                  _use.proposedUse = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _projectDescription,
                label: 'Project Description *',
                maxLines: 3,
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'Project Description'),
                onChanged: (v) {
                  _use.projectDescription = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _existingUse,
                label: 'Present Use of the Lot',
                onChanged: (v) {
                  _use.existingUse = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _floorArea,
                label: 'Proposed Floor Area (sq m)',
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  _use.floorArea = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _estimatedProjectCost,
                label: 'Estimated Project Cost',
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  _use.estimatedProjectCost = v;
                  widget.onChanged();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
