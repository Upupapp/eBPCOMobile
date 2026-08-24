import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/document_model.dart';
import '../../../../core/models/payment_assessment_model.dart';
import '../../../../core/providers/applications_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/text_fields/app_text_field.dart';
import '../../../../shared/widgets/uploads/document_upload_tile.dart';
import '../../../documents/presentation/widgets/attach_document_sheet.dart';

/// Collects what the Treasurer's Office needs to verify a payment: the
/// channel used, the reference number, and an image of the receipt or deposit
/// slip.
///
/// Both the reference and the attachment are required. A submission with only
/// one of them cannot be verified, so accepting it would leave the applicant
/// believing they had paid while their application sat still.
Future<void> showProofOfPaymentSheet(
  BuildContext context, {
  required String applicationId,
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
      child: _ProofOfPaymentForm(applicationId: applicationId),
    ),
  );
}

class _ProofOfPaymentForm extends StatefulWidget {
  final String applicationId;

  const _ProofOfPaymentForm({required this.applicationId});

  @override
  State<_ProofOfPaymentForm> createState() => _ProofOfPaymentFormState();
}

class _ProofOfPaymentFormState extends State<_ProofOfPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _reference = TextEditingController();
  PaymentMethod _method = PaymentMethod.bankTransfer;
  DocumentModel? _proof;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _reference.text.trim().isNotEmpty && _proof != null;

  Future<void> _attach() async {
    final result = await showAttachDocumentOptions(
      context,
      label: 'Proof of payment',
    );
    if (result == null) return;
    // The picker can outlive this step; setState on a defunct State throws.
    if (!mounted) return;
    setState(() => _proof = result);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_proof == null) return;

    context.read<ApplicationsProvider>().submitProofOfPayment(
      widget.applicationId,
      method: _method,
      referenceNumber: _reference.text.trim(),
      proof: _proof!,
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Proof of payment submitted. The Treasurer’s Office will verify it.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Proof of payment', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'The Treasurer’s Office verifies your payment against these '
                'details.',
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('How you paid', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              RadioGroup<PaymentMethod>(
                groupValue: _method,
                onChanged: (value) =>
                    setState(() => _method = value ?? _method),
                child: Column(
                  children: [
                    for (final method in PaymentMethod.values)
                      RadioListTile<PaymentMethod>(
                        value: method,
                        title: Text(method.label, style: AppTypography.body),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _reference,
                label: _method == PaymentMethod.bankTransfer
                    ? 'Bank reference number *'
                    : 'Official receipt number *',
                validator: (value) => Validators.required(
                  value,
                  fieldLabel: 'reference number',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),

              DocumentUploadTile(
                label: _method == PaymentMethod.bankTransfer
                    ? 'Deposit slip or transfer screenshot'
                    : 'Photo of your official receipt',
                isRequired: true,
                document: _proof,
                onUpload: _attach,
                allowReplace: true,
                onRemove: () => setState(() => _proof = null),
              ),
              const SizedBox(height: AppSpacing.lg),

              PrimaryButton(
                label: 'Submit for verification',
                onPressed: _canSubmit ? _submit : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
