import 'package:flutter/material.dart';

import '../../../../../core/models/zoning_permit_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/text_fields/app_text_field.dart';

/// Step 5 — certification and submission.
///
/// The ocular inspection acknowledgement is not boilerplate: FM-MPD-12's own
/// procedure is an ocular site inspection and a project evaluation report by
/// the Zoning Officer, so someone will visit the lot. An applicant who does
/// not expect that is an applicant who is not there when it happens.
class Step5Certification extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final ZoningPermitDraft draft;
  final VoidCallback onChanged;

  const Step5Certification({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step5Certification> createState() => _Step5CertificationState();
}

class _Step5CertificationState extends State<Step5Certification> {
  ZoningCertification get _certification => widget.draft.certification;

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
                    value: _certification.acceptsOcularInspection,
                    onChanged: (value) {
                      setState(
                        () => _certification.acceptsOcularInspection =
                            value ?? false,
                      );
                      widget.onChanged();
                    },
                    title: Text(
                      'I understand the Zoning Officer will carry out an '
                      'ocular inspection of the site.',
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'A Locational Clearance is valid for twelve (12) months from '
              'issuance. It is issued by the Municipal Planning and '
              'Development Office, not the Office of the Building Official.',
              style: AppTypography.helper,
            ),
          ],
        ),
      ),
    );
  }
}
