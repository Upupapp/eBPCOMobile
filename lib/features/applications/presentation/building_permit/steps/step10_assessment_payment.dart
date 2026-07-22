import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/building_permit_model.dart';
import '../../../../../core/models/payment_assessment_model.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/alerts/app_alert.dart';
import '../../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../../shared/widgets/uploads/document_upload_tile.dart';
import '../widgets/mock_upload.dart';
import '../widgets/selection_tile.dart';

const _feeRows = [
  'Filing Fee',
  'Processing Fee',
  'Locational or Zoning of Land Use',
  'Line and Grade or Geodetic',
  'Fencing',
  'Architectural',
  'Civil or Structural',
  'Electrical',
  'Mechanical',
  'Sanitary',
  'Plumbing',
  'Electronics',
  'Interior',
  'Fire Code Construction Tax',
  'Surcharges',
  'Penalties',
];

/// Step 10 — Assessment and Payment. The app has no real fee schedule, so
/// every row is a placeholder pending assessment by the Office of the
/// Building Official; the only real action here is picking an intended
/// payment method — actual payment stays disabled until assessment.
class Step10AssessmentPayment extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BuildingPermitDraft draft;
  final VoidCallback onChanged;

  const Step10AssessmentPayment({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<Step10AssessmentPayment> createState() =>
      _Step10AssessmentPaymentState();
}

class _Step10AssessmentPaymentState extends State<Step10AssessmentPayment> {
  void _selectMethod(PaymentMethod method) {
    setState(() => widget.draft.paymentMethod = method);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Form(
      key: widget.formKey,
      child: FormScrollScaffold(
        centerVertically: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Estimated Fees', style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text(
              'Final fees will be determined after the Office of the Building '
              'Official evaluates your application and submitted documents.',
              style: AppTypography.helper,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final fee in _feeRows) ...[
                    Text(fee, style: AppTypography.bodyStrong),
                    const SizedBox(height: 2),
                    Text(
                      'Basis: To be assessed by the Office of the Building Official',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 2),
                    Text('Amount Due: Pending', style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount', style: AppTypography.cardTitle),
                      Text(
                        'Pending Assessment',
                        style: AppTypography.bodyStrong,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const AppAlert(
              variant: AppAlertVariant.info,
              message:
                  'Final fees will be determined after the Office of the '
                  'Building Official evaluates your application and submitted '
                  'documents. Do not invent or assume official prices.',
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Choose Payment Method', style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text(
              'This records your intended payment method for when assessment '
              'is complete. This prototype does not process real payments.',
              style: AppTypography.helper,
            ),
            const SizedBox(height: AppSpacing.md),
            SelectionTile(
              title: 'Pay Onsite',
              subtitle: 'Pay at the designated office after assessment.',
              selected: draft.paymentMethod == PaymentMethod.onsite,
              onTap: () => _selectMethod(PaymentMethod.onsite),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectionTile(
              title: 'Bank Transfer',
              subtitle: 'Transfer to the office\'s designated bank account.',
              selected: draft.paymentMethod == PaymentMethod.bankTransfer,
              onTap: () => _selectMethod(PaymentMethod.bankTransfer),
            ),

            if (draft.paymentMethod == PaymentMethod.onsite) ...[
              const SizedBox(height: AppSpacing.lg),
              const AppAlert(
                variant: AppAlertVariant.info,
                title: 'Onsite Payment Instructions',
                message:
                    'Once your application has been assessed, you may pay '
                    'directly at the Office of the Building Official counter. '
                    'Your payment status will show as Pending until then.',
              ),
            ],
            if (draft.paymentMethod == PaymentMethod.bankTransfer) ...[
              const SizedBox(height: AppSpacing.lg),
              const AppAlert(
                variant: AppAlertVariant.info,
                title: 'Bank Transfer Details (Prototype)',
                message:
                    'Account Name: eBPCO Business Permits\n'
                    'Account Number: 1234-5678-90\n'
                    'Bank: BPI\n\n'
                    'These details are for this frontend prototype only — no '
                    'real transaction will be processed.',
              ),
              const SizedBox(height: AppSpacing.md),
              DocumentUploadTile(
                label: 'Proof of Payment',
                isRequired: false,
                statusLabel:
                    'Optional for now — add once assessment is complete',
                allowReplace: true,
                document: draft.paymentProof,
                onUpload: () {
                  setState(
                    () => draft.paymentProof = createMockDocument(
                      'Proof of Payment',
                      extension: 'jpg',
                    ),
                  );
                  widget.onChanged();
                },
                onRemove: () {
                  setState(() => draft.paymentProof = null);
                  widget.onChanged();
                },
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            const AppAlert(
              variant: AppAlertVariant.warning,
              title: 'Payment is not yet available',
              message:
                  'Payment will become available after the application has '
                  'been assessed. Use "Submit Application for Assessment" '
                  'below to send this application to the Office of the '
                  'Building Official.',
            ),
          ],
        ),
      ),
    );
  }
}
