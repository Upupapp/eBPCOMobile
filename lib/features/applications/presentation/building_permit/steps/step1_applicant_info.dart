import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../core/models/building_permit_model.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_dropdown.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';

const _formsOfOwnership = [
  'Individual / Sole Owner',
  'Corporation',
  'Partnership',
  'Cooperative',
  'Government',
  'Others',
];

/// Step 1 — Applicant and Ownership. Prefills owner name/contact from the
/// mock signed-in profile when those draft fields are still empty, but
/// every field stays editable.
class Step1ApplicantInfo extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BuildingPermitDraft draft;
  final VoidCallback onChanged;

  const Step1ApplicantInfo({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step1ApplicantInfo> createState() => _Step1ApplicantInfoState();
}

class _Step1ApplicantInfoState extends State<Step1ApplicantInfo> {
  late final TextEditingController _lastName;
  late final TextEditingController _firstName;
  late final TextEditingController _middleInitial;
  late final TextEditingController _tin;
  late final TextEditingController _contactNumber;
  late final TextEditingController _enterpriseName;
  late final TextEditingController _houseNumber;
  late final TextEditingController _street;
  late final TextEditingController _barangay;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _zipCode;

  ApplicantOwnershipDetails get _applicant => widget.draft.applicant;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();

    _lastName = TextEditingController(text: _applicant.lastName);
    _firstName = TextEditingController(text: _applicant.firstName);
    _middleInitial = TextEditingController(text: _applicant.middleInitial);
    _tin = TextEditingController(text: _applicant.tin);
    _contactNumber = TextEditingController(text: _applicant.contactNumber);
    _enterpriseName = TextEditingController(text: _applicant.enterpriseName);
    _houseNumber = TextEditingController(text: _applicant.houseNumber);
    _street = TextEditingController(text: _applicant.street);
    _barangay = TextEditingController(text: _applicant.barangay);
    _city = TextEditingController(text: _applicant.city);
    _province = TextEditingController(text: _applicant.province);
    _zipCode = TextEditingController(text: _applicant.zipCode);
  }

  void _prefillFromProfile() {
    if (_applicant.lastName.isNotEmpty || _applicant.firstName.isNotEmpty) {
      return;
    }
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    _applicant.lastName = user.lastName;
    _applicant.firstName = user.firstName;
    _applicant.middleInitial = user.middleName.isNotEmpty
        ? user.middleName.substring(0, 1).toUpperCase()
        : '';
    _applicant.contactNumber = user.mobileNumber;
  }

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _middleInitial.dispose();
    _tin.dispose();
    _contactNumber.dispose();
    _enterpriseName.dispose();
    _houseNumber.dispose();
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
            Text('Owner or Applicant', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _lastName,
              label: 'Last Name',
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.required(v, fieldLabel: 'Last name'),
              onChanged: (v) {
                _applicant.lastName = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _firstName,
              label: 'First Name',
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  Validators.required(v, fieldLabel: 'First name'),
              onChanged: (v) {
                _applicant.firstName = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _middleInitial,
              label: 'Middle Initial',
              hint: 'Optional',
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(2)],
              onChanged: (v) {
                _applicant.middleInitial = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _tin,
              label: 'TIN',
              hint: 'Optional — Tax Identification Number',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                _applicant.tin = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _contactNumber,
              label: 'Telephone or Mobile Number',
              keyboardType: TextInputType.phone,
              validator: Validators.philippineMobile,
              onChanged: (v) {
                _applicant.contactNumber = v;
                widget.onChanged();
              },
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Ownership', style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text(
              'Tell us if this construction is owned by a business or organization instead of an individual.',
              style: AppTypography.helper,
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Is the construction owned by an enterprise?'),
              value: _applicant.isOwnedByEnterprise,
              onChanged: (v) {
                setState(() => _applicant.isOwnedByEnterprise = v);
                widget.onChanged();
              },
            ),
            if (_applicant.isOwnedByEnterprise) ...[
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _enterpriseName,
                label: 'Enterprise Name',
                validator: (v) => _applicant.isOwnedByEnterprise
                    ? Validators.required(v, fieldLabel: 'Enterprise name')
                    : null,
                onChanged: (v) {
                  _applicant.enterpriseName = v;
                  widget.onChanged();
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppDropdown<String>(
              value: _applicant.formOfOwnership.isEmpty
                  ? null
                  : _applicant.formOfOwnership,
              label: 'Form of Ownership',
              items: _formsOfOwnership
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              validator: (v) =>
                  Validators.required(v, fieldLabel: 'Form of ownership'),
              onChanged: (v) {
                setState(() => _applicant.formOfOwnership = v ?? '');
                widget.onChanged();
              },
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Applicant Address', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _houseNumber,
              label: 'House or Building Number',
              onChanged: (v) {
                _applicant.houseNumber = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _street,
              label: 'Street',
              validator: (v) => Validators.required(v, fieldLabel: 'Street'),
              onChanged: (v) {
                _applicant.street = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _barangay,
              label: 'Barangay',
              validator: (v) => Validators.required(v, fieldLabel: 'Barangay'),
              onChanged: (v) {
                _applicant.barangay = v;
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
                _applicant.city = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _province,
              label: 'Province',
              validator: (v) => Validators.required(v, fieldLabel: 'Province'),
              onChanged: (v) {
                _applicant.province = v;
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
                _applicant.zipCode = v;
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
