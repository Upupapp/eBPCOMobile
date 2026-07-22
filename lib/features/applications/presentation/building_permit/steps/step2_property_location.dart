import 'package:flutter/material.dart';

import '../../../../../core/models/building_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';

/// Step 2 — Construction/Property Location. Explains unfamiliar legal
/// terms (TCT/OCT, Tax Declaration) in plain language instead of assuming
/// the applicant already knows them.
class Step2PropertyLocation extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BuildingPermitDraft draft;
  final VoidCallback onChanged;

  const Step2PropertyLocation({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step2PropertyLocation> createState() => _Step2PropertyLocationState();
}

class _Step2PropertyLocationState extends State<Step2PropertyLocation> {
  late final TextEditingController _lotNumber;
  late final TextEditingController _blockNumber;
  late final TextEditingController _tctOrOct;
  late final TextEditingController _taxDeclaration;
  late final TextEditingController _street;
  late final TextEditingController _barangay;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _zipCode;

  PropertyLocationDetails get _location => widget.draft.location;

  @override
  void initState() {
    super.initState();
    _lotNumber = TextEditingController(text: _location.lotNumber);
    _blockNumber = TextEditingController(text: _location.blockNumber);
    _tctOrOct = TextEditingController(text: _location.tctOrOctNumber);
    _taxDeclaration = TextEditingController(
      text: _location.taxDeclarationNumber,
    );
    _street = TextEditingController(text: _location.street);
    _barangay = TextEditingController(text: _location.barangay);
    _city = TextEditingController(text: _location.city);
    _province = TextEditingController(text: _location.province);
    _zipCode = TextEditingController(text: _location.zipCode);
  }

  @override
  void dispose() {
    _lotNumber.dispose();
    _blockNumber.dispose();
    _tctOrOct.dispose();
    _taxDeclaration.dispose();
    _street.dispose();
    _barangay.dispose();
    _city.dispose();
    _province.dispose();
    _zipCode.dispose();
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
            Text('Property References', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _lotNumber,
              label: 'Lot Number',
              validator: (v) =>
                  Validators.required(v, fieldLabel: 'Lot number'),
              onChanged: (v) {
                _location.lotNumber = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _blockNumber,
              label: 'Block Number',
              hint: 'Optional',
              onChanged: (v) {
                _location.blockNumber = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _tctOrOct,
              label: 'TCT or OCT Number',
              hint: 'Transfer or Original Certificate of Title',
              validator: (v) =>
                  Validators.required(v, fieldLabel: 'TCT or OCT number'),
              onChanged: (v) {
                _location.tctOrOctNumber = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: 4),
            Text(
              'A TCT (Transfer Certificate of Title) or OCT (Original Certificate '
              'of Title) is the official document proving who owns this property. '
              "It's usually found on your land title.",
              style: AppTypography.helper,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _taxDeclaration,
              label: 'Tax Declaration Number',
              validator: (v) =>
                  Validators.required(v, fieldLabel: 'Tax declaration number'),
              onChanged: (v) {
                _location.taxDeclarationNumber = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: 4),
            Text(
              'The Tax Declaration is the record your city or municipal '
              'assessor keeps for real property tax purposes. You can find '
              'this number on your latest property tax receipt.',
              style: AppTypography.helper,
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Construction Site Address', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _street,
              label: 'Street',
              validator: (v) => Validators.required(v, fieldLabel: 'Street'),
              onChanged: (v) {
                _location.street = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _barangay,
              label: 'Barangay',
              validator: (v) => Validators.required(v, fieldLabel: 'Barangay'),
              onChanged: (v) {
                _location.barangay = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _city,
              label: 'City or Municipality',
              validator: (v) =>
                  Validators.required(v, fieldLabel: 'City or municipality'),
              onChanged: (v) {
                _location.city = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _province,
              label: 'Province',
              validator: (v) => Validators.required(v, fieldLabel: 'Province'),
              onChanged: (v) {
                _location.province = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _zipCode,
              label: 'ZIP Code',
              keyboardType: TextInputType.number,
              validator: Validators.postalCode,
              onChanged: (v) {
                _location.zipCode = v;
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
