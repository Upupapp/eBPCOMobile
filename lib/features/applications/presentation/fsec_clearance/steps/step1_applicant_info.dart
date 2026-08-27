import 'package:flutter/material.dart';

import '../../../../../core/models/fsec_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';

/// Step 1 — who is applying.
class Step1ApplicantInfo extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final FsecPermitDraft draft;
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
  FSECApplicantInfo get _applicant => widget.draft.applicant;

  late final _firstName = TextEditingController(text: _applicant.firstName);
  late final _middleName = TextEditingController(text: _applicant.middleName);
  late final _lastName = TextEditingController(text: _applicant.lastName);
  late final _enterprise = TextEditingController(
    text: _applicant.enterpriseName,
  );
  late final _contact = TextEditingController(text: _applicant.contactNumber);
  late final _email = TextEditingController(text: _applicant.emailAddress);
  late final _address = TextEditingController(text: _applicant.address);

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _middleName,
      _lastName,
      _enterprise,
      _contact,
      _email,
      _address,
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
                controller: _firstName,
                label: 'First Name *',
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'First name'),
                onChanged: (v) {
                  _applicant.firstName = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _middleName,
                label: 'Middle Name',
                onChanged: (v) {
                  _applicant.middleName = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _lastName,
                label: 'Last Name *',
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'Last name'),
                onChanged: (v) {
                  _applicant.lastName = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _enterprise,
                label: 'Enterprise / Firm Name',
                onChanged: (v) {
                  _applicant.enterpriseName = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _contact,
                label: 'Contact Number *',
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'Contact number'),
                onChanged: (v) {
                  _applicant.contactNumber = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _email,
                label: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) {
                  _applicant.emailAddress = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _address,
                label: 'Address *',
                validator: (v) => Validators.required(v, fieldLabel: 'Address'),
                onChanged: (v) {
                  _applicant.address = v;
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
