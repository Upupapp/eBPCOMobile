import 'package:flutter/material.dart';

import '../../../../../core/models/building_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';
import '../widgets/selection_tile.dart';

/// Step 4 — Use or Character of Occupancy. Single-select classification
/// with short plain-language descriptions so applicants don't need to know
/// the National Building Code group letters by heart.
class Step4BuildingUse extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BuildingPermitDraft draft;
  final VoidCallback onChanged;

  const Step4BuildingUse({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step4BuildingUse> createState() => _Step4BuildingUseState();
}

class _Step4BuildingUseState extends State<Step4BuildingUse> {
  late final TextEditingController _otherDetail;
  late final TextEditingController _classification;
  late final TextEditingController _numberOfUnits;

  @override
  void initState() {
    super.initState();
    _otherDetail = TextEditingController(
      text: widget.draft.occupancyOtherDetail,
    );
    _classification = TextEditingController(
      text: widget.draft.occupancyClassification,
    );
    _numberOfUnits = TextEditingController(text: widget.draft.numberOfUnits);
  }

  @override
  void dispose() {
    _otherDetail.dispose();
    _classification.dispose();
    _numberOfUnits.dispose();
    super.dispose();
  }

  void _select(OccupancyGroup group) {
    setState(() => widget.draft.occupancyGroup = group);
    widget.onChanged();
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
            Text('Choose one classification', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            ...OccupancyGroup.values.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SelectionTile(
                  title: group.label,
                  subtitle: group.description,
                  selected: widget.draft.occupancyGroup == group,
                  onTap: () => _select(group),
                ),
              ),
            ),
            if (widget.draft.occupancyGroup == OccupancyGroup.others) ...[
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _otherDetail,
                label: 'Specify Occupancy Use',
                onChanged: (v) {
                  widget.draft.occupancyOtherDetail = v;
                  widget.onChanged();
                },
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              controller: _classification,
              label: 'Occupancy Classification',
              hint: 'Optional — e.g. Single Detached, Retail Store',
              onChanged: (v) {
                widget.draft.occupancyClassification = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _numberOfUnits,
              label: 'Number of Units',
              hint: 'Optional',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                widget.draft.numberOfUnits = v;
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
