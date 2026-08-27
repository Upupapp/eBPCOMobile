import 'package:flutter/material.dart';

import '../../../../../core/models/fsec_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';

/// Step 2 — the building this clearance concerns.
///
/// Occupancy type is the field that matters most: the Fire Code's requirements
/// turn on how the building will be used, so the BFP evaluates against it.
class Step2ProjectDetails extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final FsecPermitDraft draft;
  final VoidCallback onChanged;

  const Step2ProjectDetails({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step2ProjectDetails> createState() => _Step2ProjectDetailsState();
}

class _Step2ProjectDetailsState extends State<Step2ProjectDetails> {
  FSECProjectDetails get _project => widget.draft.project;

  late final _projectName = TextEditingController(text: _project.projectName);
  late final _projectAddress = TextEditingController(
    text: _project.projectAddress,
  );
  late final _occupancyType = TextEditingController(
    text: _project.occupancyType,
  );
  late final _totalFloorArea = TextEditingController(
    text: _project.totalFloorArea,
  );
  late final _numberOfStoreys = TextEditingController(
    text: _project.numberOfStoreys,
  );
  late final _relatedBuildingPermitNumber = TextEditingController(
    text: _project.relatedBuildingPermitNumber,
  );

  @override
  void dispose() {
    for (final controller in [
      _projectName,
      _projectAddress,
      _occupancyType,
      _totalFloorArea,
      _numberOfStoreys,
      _relatedBuildingPermitNumber,
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
                controller: _projectName,
                label: 'Project Name *',
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'Project Name'),
                onChanged: (v) {
                  _project.projectName = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _projectAddress,
                label: 'Project Address *',
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'Project Address'),
                onChanged: (v) {
                  _project.projectAddress = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _occupancyType,
                label: 'Occupancy Type *',
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'Occupancy Type'),
                onChanged: (v) {
                  _project.occupancyType = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _totalFloorArea,
                label: 'Total Floor Area (sq m)',
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  _project.totalFloorArea = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _numberOfStoreys,
                label: 'Number of Storeys',
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  _project.numberOfStoreys = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _relatedBuildingPermitNumber,
                label: 'Related Building Permit Number',
                onChanged: (v) {
                  _project.relatedBuildingPermitNumber = v;
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
