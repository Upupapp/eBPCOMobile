import 'package:flutter/material.dart';

import '../../../../../core/models/building_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';
import '../widgets/date_picker_field.dart';

String? _requiredPositiveNumber(String? value, {required String fieldLabel}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldLabel is required.';
  }
  final parsed = double.tryParse(value.trim());
  if (parsed == null) {
    return 'Enter a valid number.';
  }
  if (parsed <= 0) {
    return '$fieldLabel must be greater than zero.';
  }
  return null;
}

/// Step 5 — Project Details: size, cost estimate, and schedule. All
/// figures are clearly labeled as estimates, matching the official form's
/// "estimated cost" language.
class Step5ProjectDetails extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BuildingPermitDraft draft;
  final VoidCallback onChanged;

  const Step5ProjectDetails({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step5ProjectDetails> createState() => _Step5ProjectDetailsState();
}

class _Step5ProjectDetailsState extends State<Step5ProjectDetails> {
  late final TextEditingController _floorArea;
  late final TextEditingController _lotArea;
  late final TextEditingController _cost;

  ProjectDetails get _project => widget.draft.project;

  @override
  void initState() {
    super.initState();
    _floorArea = TextEditingController(text: _project.totalFloorArea);
    _lotArea = TextEditingController(text: _project.lotArea);
    _cost = TextEditingController(text: _project.estimatedCost);
  }

  @override
  void dispose() {
    _floorArea.dispose();
    _lotArea.dispose();
    _cost.dispose();
    super.dispose();
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
            Text('Size', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _floorArea,
              label: 'Total Floor Area',
              hint: 'In square meters',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Align(widthFactor: 1, child: Text('sq. m')),
              ),
              validator: (v) =>
                  _requiredPositiveNumber(v, fieldLabel: 'Total floor area'),
              onChanged: (v) {
                _project.totalFloorArea = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _lotArea,
              label: 'Lot Area',
              hint: 'In square meters',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Align(widthFactor: 1, child: Text('sq. m')),
              ),
              validator: (v) =>
                  _requiredPositiveNumber(v, fieldLabel: 'Lot area'),
              onChanged: (v) {
                _project.lotArea = v;
                widget.onChanged();
              },
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Cost Estimate', style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text(
              'This is your best estimate — the Office of the Building '
              'Official will confirm the final assessed cost.',
              style: AppTypography.helper,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _cost,
              label: 'Total Estimated Construction Cost',
              hint: 'e.g. 850000',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Align(widthFactor: 1, child: Text('₱')),
              ),
              validator: (v) => _requiredPositiveNumber(
                v,
                fieldLabel: 'Total estimated construction cost',
              ),
              onChanged: (v) {
                _project.estimatedCost = v;
                widget.onChanged();
              },
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Construction Schedule', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.md),
            DatePickerField(
              label: 'Proposed Date of Construction',
              value: _project.proposedConstructionDate,
              validator: (v) => v == null
                  ? 'Please select the proposed construction date.'
                  : null,
              onChanged: (v) {
                setState(() => _project.proposedConstructionDate = v);
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DatePickerField(
              label: 'Expected Date of Completion',
              value: _project.expectedCompletionDate,
              validator: (v) => v == null
                  ? 'Please select the expected completion date.'
                  : null,
              onChanged: (v) {
                setState(() => _project.expectedCompletionDate = v);
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
