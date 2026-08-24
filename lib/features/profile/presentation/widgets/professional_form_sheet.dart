import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/professional_model.dart';
import '../../../../core/providers/professionals_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/text_fields/app_text_field.dart';

/// Adds or edits a design professional.
Future<void> showProfessionalFormSheet(
  BuildContext context, {
  ProfessionalModel? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _ProfessionalForm(existing: existing),
    ),
  );
}

class _ProfessionalForm extends StatefulWidget {
  final ProfessionalModel? existing;

  const _ProfessionalForm({this.existing});

  @override
  State<_ProfessionalForm> createState() => _ProfessionalFormState();
}

class _ProfessionalFormState extends State<_ProfessionalForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _prcNumber;
  late final TextEditingController _ptrNumber;
  late final TextEditingController _ptrPlace;

  late ProfessionalDiscipline _discipline;
  DateTime? _prcValidity;
  DateTime? _ptrIssued;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.fullName ?? '');
    _prcNumber = TextEditingController(text: existing?.prcNumber ?? '');
    _ptrNumber = TextEditingController(text: existing?.ptrNumber ?? '');
    _ptrPlace = TextEditingController(text: existing?.ptrPlaceIssued ?? '');
    _discipline = existing?.discipline ?? ProfessionalDiscipline.architect;
    _prcValidity = existing?.prcValidityDate;
    _ptrIssued = existing?.ptrDateIssued;
  }

  @override
  void dispose() {
    _name.dispose();
    _prcNumber.dispose();
    _ptrNumber.dispose();
    _ptrPlace.dispose();
    super.dispose();
  }

  bool get _isComplete =>
      _name.text.trim().isNotEmpty &&
      _prcNumber.text.trim().isNotEmpty &&
      _ptrNumber.text.trim().isNotEmpty &&
      _ptrPlace.text.trim().isNotEmpty &&
      _prcValidity != null &&
      _ptrIssued != null;

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      // Wide enough for a PRC valid three years out and a PTR issued years
      // ago; narrower bounds would reject legitimate real-world dates.
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    // The picker can outlive this step; setState on a defunct State throws.
    if (!mounted) return;
    if (picked != null) setState(() => onPicked(picked));
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_prcValidity == null || _ptrIssued == null) return;

    final provider = context.read<ProfessionalsProvider>();
    provider.saveProfessional(
      ProfessionalModel(
        id: widget.existing?.id ?? provider.newId('pro'),
        fullName: _name.text.trim(),
        discipline: _discipline,
        prcNumber: _prcNumber.text.trim(),
        prcValidityDate: _prcValidity!,
        ptrNumber: _ptrNumber.text.trim(),
        ptrDateIssued: _ptrIssued!,
        ptrPlaceIssued: _ptrPlace.text.trim(),
        // Credential images are attached from the wizards that need them, so
        // adding someone here never demands documents up front.
        prcIdImage: widget.existing?.prcIdImage,
        ptrImage: widget.existing?.ptrImage,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');

    return SafeArea(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusPill,
                    ),
                  ),
                ),
              ),
              Text(
                widget.existing == null
                    ? 'Add a professional'
                    : 'Edit professional',
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                controller: _name,
                label: 'Full name *',
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.required(v, fieldLabel: 'name'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<ProfessionalDiscipline>(
                initialValue: _discipline,
                // Without isExpanded the field sizes to its widest item, and
                // "Professional Electronics Engineer" is wider than a 360dp
                // phone. Ellipsis rather than wrap, so the field stays one
                // line tall in a form that is already long.
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Discipline *'),
                items: [
                  for (final discipline in ProfessionalDiscipline.values)
                    DropdownMenuItem(
                      value: discipline,
                      child: Text(
                        discipline.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _discipline = value ?? _discipline),
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _prcNumber,
                label: 'PRC number *',
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'PRC number'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              _DateField(
                label: 'PRC valid until *',
                value: _prcValidity,
                format: format,
                onTap: () => _pickDate(
                  current: _prcValidity,
                  onPicked: (d) => _prcValidity = d,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _ptrNumber,
                label: 'PTR number *',
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'PTR number'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              _DateField(
                label: 'PTR date issued *',
                value: _ptrIssued,
                format: format,
                onTap: () => _pickDate(
                  current: _ptrIssued,
                  onPicked: (d) => _ptrIssued = d,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _ptrPlace,
                label: 'PTR place issued *',
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'PTR place issued'),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Save',
                onPressed: _isComplete ? _save : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat format;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.format,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(
          value == null ? 'Select a date' : format.format(value!),
          style: value == null ? AppTypography.helper : AppTypography.body,
        ),
      ),
    );
  }
}
