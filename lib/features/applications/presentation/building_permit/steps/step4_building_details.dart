import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/models/building_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';
import '../widgets/date_picker_field.dart';

/// Step 4 — Building Details: occupancy, floor/lot area, estimated cost,
/// and proposed construction schedule.
class Step4BuildingDetails extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BuildingPermitDraft draft;
  final VoidCallback onChanged;

  const Step4BuildingDetails({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step4BuildingDetails> createState() => _Step4BuildingDetailsState();
}

class _Step4BuildingDetailsState extends State<Step4BuildingDetails> {
  late final TextEditingController _occupancyClassification;
  late final TextEditingController _numberOfUnits;
  late final TextEditingController _numberOfStorey;
  late final TextEditingController _totalFloorArea;
  late final TextEditingController _lotArea;
  late final TextEditingController _estimatedCost;

  /// The five cost components and the equipment line, in the order the form
  /// prints them. Built as a list rather than six near-identical widgets
  /// because six copies of one field is six chances for one of them to be
  /// wired to the wrong model property.
  late final List<_CostPart> _costParts;

  BuildingDetails get _details => widget.draft.buildingDetails;

  @override
  void initState() {
    super.initState();
    _occupancyClassification = TextEditingController(
      text: _details.occupancyClassification,
    );
    _numberOfUnits = TextEditingController(text: _details.numberOfUnits);
    _numberOfStorey = TextEditingController(text: _details.numberOfStorey);
    _totalFloorArea = TextEditingController(text: _details.totalFloorArea);
    _lotArea = TextEditingController(text: _details.lotArea);
    _costParts = [
      _CostPart(
        'Cost — Building',
        _details.estimatedCostBuilding,
        (v) => _details.estimatedCostBuilding = v,
      ),
      _CostPart(
        'Cost — Electrical',
        _details.estimatedCostElectrical,
        (v) => _details.estimatedCostElectrical = v,
      ),
      _CostPart(
        'Cost — Mechanical',
        _details.estimatedCostMechanical,
        (v) => _details.estimatedCostMechanical = v,
      ),
      _CostPart(
        'Cost — Electronics',
        _details.estimatedCostElectronics,
        (v) => _details.estimatedCostElectronics = v,
      ),
      _CostPart(
        'Cost — Plumbing',
        _details.estimatedCostPlumbing,
        (v) => _details.estimatedCostPlumbing = v,
      ),
      _CostPart(
        'Cost of Equipment Installed',
        _details.costOfEquipmentInstalled,
        (v) => _details.costOfEquipmentInstalled = v,
      ),
    ];
    _estimatedCost = TextEditingController(
      text: _details.estimatedConstructionCost,
    );
  }

  @override
  void dispose() {
    _occupancyClassification.dispose();
    _numberOfUnits.dispose();
    _numberOfStorey.dispose();
    _totalFloorArea.dispose();
    _lotArea.dispose();
    _estimatedCost.dispose();
    for (final part in _costParts) {
      part.controller.dispose();
    }
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
            Text('Occupancy Details', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _occupancyClassification,
                    label: 'Occupancy Classification *',
                    hint: 'Example: Single Detached Residential Building',
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => Validators.required(
                      v,
                      fieldLabel: 'Occupancy classification',
                    ),
                    onChanged: (v) {
                      _details.occupancyClassification = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _numberOfUnits,
                    label: 'Number of Units *',
                    hint: 'Enter the total number of units in the building',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => Validators.positiveWholeNumber(
                      v,
                      fieldLabel: 'Number of units',
                    ),
                    onChanged: (v) {
                      _details.numberOfUnits = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // The form asks for this beside Number of Units, Total Floor
                  // Area and Lot Area — all three of which this step already
                  // had. Storey count drives occupancy and structural review
                  // under PD 1096.
                  AppTextField(
                    controller: _numberOfStorey,
                    label: 'Number of Storeys *',
                    hint: 'How many floors the building has',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => Validators.positiveWholeNumber(
                      v,
                      fieldLabel: 'Number of storeys',
                    ),
                    onChanged: (v) {
                      _details.numberOfStorey = v;
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Area Details', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _totalFloorArea,
                    label: 'Total Floor Area *',
                    hint: 'e.g. 120.5',
                    suffixIcon: const _UnitSuffix('sq m'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (v) => Validators.positiveDecimal(
                      v,
                      fieldLabel: 'Total floor area',
                    ),
                    onChanged: (v) {
                      _details.totalFloorArea = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _lotArea,
                    label: 'Lot Area *',
                    hint: 'e.g. 200',
                    suffixIcon: const _UnitSuffix('sq m'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (v) =>
                        Validators.positiveDecimal(v, fieldLabel: 'Lot area'),
                    onChanged: (v) {
                      _details.lotArea = v;
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Cost and Schedule', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _estimatedCost,
                    label: 'Total Estimated Construction Cost *',
                    hint: 'e.g. 1500000',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 4),
                      child: Center(
                        widthFactor: 1,
                        child: Text('₱', style: AppTypography.body),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (v) => Validators.positiveDecimal(
                      v,
                      fieldLabel: 'Estimated construction cost',
                    ),
                    onChanged: (v) {
                      _details.estimatedConstructionCost = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // The five components the form breaks the total into, and
                  // the equipment line beside them. Added 31 August 2026: the
                  // app asked for one figure and the form asks for six, and
                  // building permit fees are assessed from the components, so
                  // a total alone is materially less than the office needs.
                  //
                  // All optional. A simple residential permit may have nothing
                  // to put against electronics or mechanical, and demanding a
                  // zero would be asking the applicant to answer a question
                  // the form does not press.
                  for (final part in _costParts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppTextField(
                        controller: part.controller,
                        label: part.label,
                        hint: 'Optional',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 4),
                          child: Center(
                            widthFactor: 1,
                            child: Text('₱', style: AppTypography.body),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        onChanged: (v) {
                          part.onChanged(v);
                          widget.onChanged();
                        },
                      ),
                    ),
                  Text(
                    'This amount is an estimate and may be used as part of '
                    'the permit assessment.',
                    style: AppTypography.helper,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DatePickerField(
                    label: 'Proposed Date of Construction *',
                    value: _details.proposedConstructionDate,
                    validator: (_) => _details.proposedConstructionDate == null
                        ? 'Please select a proposed construction date.'
                        : null,
                    onChanged: (date) {
                      setState(() => _details.proposedConstructionDate = date);
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DatePickerField(
                    label: 'Expected Date of Completion *',
                    value: _details.expectedCompletionDate,
                    validator: (_) {
                      final proposed = _details.proposedConstructionDate;
                      final expected = _details.expectedCompletionDate;
                      if (expected == null) {
                        return 'Please select an expected completion date.';
                      }
                      if (proposed != null && !expected.isAfter(proposed)) {
                        return 'Completion date must be after the proposed '
                            'construction date.';
                      }
                      return null;
                    },
                    onChanged: (date) {
                      setState(() => _details.expectedCompletionDate = date);
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row of the form's cost block: its label, its controller and where the
/// value goes.
class _CostPart {
  _CostPart(this.label, String initial, this.onChanged)
    : controller = TextEditingController(text: initial);

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
}

class _UnitSuffix extends StatelessWidget {
  final String unit;

  const _UnitSuffix(this.unit);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        widthFactor: 1,
        child: Text(unit, style: AppTypography.helper),
      ),
    );
  }
}
