import 'package:flutter/material.dart';

import '../../../../../core/models/zoning_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';

/// Step 2 — the lot itself. The Zoning Officer decides against a specific
/// parcel, so the title and tax-declaration references matter as much as the
/// street address.
class Step2SiteLocation extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final ZoningPermitDraft draft;
  final VoidCallback onChanged;

  const Step2SiteLocation({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step2SiteLocation> createState() => _Step2SiteLocationState();
}

class _Step2SiteLocationState extends State<Step2SiteLocation> {
  ZoningSiteLocation get _site => widget.draft.siteLocation;

  late final _lotNumber = TextEditingController(text: _site.lotNumber);
  late final _blockNumber = TextEditingController(text: _site.blockNumber);
  late final _tctNumber = TextEditingController(text: _site.tctNumber);
  late final _taxDeclarationNumber = TextEditingController(
    text: _site.taxDeclarationNumber,
  );
  late final _street = TextEditingController(text: _site.street);
  late final _barangay = TextEditingController(text: _site.barangay);
  late final _city = TextEditingController(text: _site.city);
  late final _lotArea = TextEditingController(text: _site.lotArea);

  @override
  void dispose() {
    for (final controller in [
      _lotNumber,
      _blockNumber,
      _tctNumber,
      _taxDeclarationNumber,
      _street,
      _barangay,
      _city,
      _lotArea,
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
                controller: _lotNumber,
                label: 'Lot Number *',
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'Lot Number'),
                onChanged: (v) {
                  _site.lotNumber = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _blockNumber,
                label: 'Block Number',
                onChanged: (v) {
                  _site.blockNumber = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _tctNumber,
                label: 'TCT / OCT Number',
                onChanged: (v) {
                  _site.tctNumber = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _taxDeclarationNumber,
                label: 'Tax Declaration Number',
                onChanged: (v) {
                  _site.taxDeclarationNumber = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _street,
                label: 'Street *',
                validator: (v) => Validators.required(v, fieldLabel: 'Street'),
                onChanged: (v) {
                  _site.street = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _barangay,
                label: 'Barangay *',
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'Barangay'),
                onChanged: (v) {
                  _site.barangay = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _city,
                label: 'City / Municipality *',
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'City / Municipality'),
                onChanged: (v) {
                  _site.city = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _lotArea,
                label: 'Lot Area (sq m) *',
                keyboardType: TextInputType.number,
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'Lot Area (sq m)'),
                onChanged: (v) {
                  _site.lotArea = v;
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
