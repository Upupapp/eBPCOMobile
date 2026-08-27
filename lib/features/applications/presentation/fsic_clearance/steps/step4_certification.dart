import 'package:flutter/material.dart';

import '../../../../../core/models/fsic_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';

/// Step 4 — certification and submission.
class Step4Certification extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final FsicPermitDraft draft;
  final VoidCallback onChanged;

  const Step4Certification({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step4Certification> createState() => _Step4CertificationState();
}

class _Step4CertificationState extends State<Step4Certification> {
  FSICCertification get _certification => widget.draft.certification;

  late final _submittedBy = TextEditingController(
    text: _certification.submittedByName,
  );

  @override
  void dispose() {
    _submittedBy.dispose();
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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _submittedBy,
                    label: 'Submitted By (Full Name) *',
                    validator: (v) =>
                        Validators.required(v, fieldLabel: 'Your name'),
                    onChanged: (v) {
                      _certification.submittedByName = v;
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _certification.certifiesTrueAndCorrect,
                    onChanged: (value) {
                      setState(
                        () => _certification.certifiesTrueAndCorrect =
                            value ?? false,
                      );
                      widget.onChanged();
                    },
                    title: Text(
                      'I certify that the information and documents submitted '
                      'are true and correct.',
                      style: AppTypography.body,
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _certification.acceptsFireSafetyInspection,
                    onChanged: (value) {
                      setState(
                        () => _certification.acceptsFireSafetyInspection =
                            value ?? false,
                      );
                      widget.onChanged();
                    },
                    title: Text(
                      'I understand the BFP will inspect the completed building.',
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This clearance is valid for twelve (12) months from issuance. '
              'It is issued by the Bureau of Fire Protection, and its fee is '
              'collected by the Bureau — not at the Building Office cashier.',
              style: AppTypography.helper,
            ),
          ],
        ),
      ),
    );
  }
}
