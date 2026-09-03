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
import '../../../applications/presentation/building_permit/widgets/date_picker_field.dart';
import '../../../documents/presentation/widgets/attach_document_sheet.dart';

/// Collects what the Treasurer's Office needs to verify a payment: the
/// channel used, the reference number, and an image of the receipt or deposit
/// slip.
///
/// The reference, the date and the attachment are all required. A submission
/// missing any of them cannot be verified, so accepting it would leave the
/// applicant believing they had paid while their application sat still.
///
/// The date was added 30 August 2026. The contract makes `paidOn` a REQUIRED
/// field of `PaymentProof` and the app had no field for it anywhere — so this
/// was never a matter of adding a key to a request body; it needed a question
/// added to the flow. M-47.
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
  DateTime? _paidOn;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_sending &&
      _reference.text.trim().isNotEmpty &&
      _proof != null &&
      _paidOn != null;

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

  /// Sends the receipt and the payment, and says so only once they are sent.
  ///
  /// This was synchronous and called `submitProofOfPayment`, which uploaded
  /// nothing and reported nothing — it changed the payment on the device and
  /// cleared the citizen's reminders. The sheet then popped and announced
  /// "Proof of payment submitted. The Treasurer's Office will verify it."
  ///
  /// A citizen who had genuinely paid at the bank therefore sent their receipt
  /// nowhere, had every reminder that would have told them removed, and waited
  /// on an office holding no record of the payment.
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final paidOn = _paidOn;
    if (_proof == null || paidOn == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _sending = true);
    try {
      await context.read<ApplicationsProvider>().attachPayment(
        widget.applicationId,
        method: _method,
        referenceNumber: _reference.text.trim(),
        proof: _proof!,
        paidOn: paidOn,
      );
    } catch (_) {
      // The sheet stays open with the receipt and the reference still in it.
      // Losing those to a dismissed sheet would make the citizen photograph a
      // receipt they have already put away.
      if (mounted) setState(() => _sending = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not send your proof of payment. Check your connection and '
            'try again — the office has not received it yet.',
          ),
        ),
      );
      return;
    }
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Proof of payment submitted. The Treasurer’s Office will verify it.',
        ),
      ),
    );
  }

  bool _sending = false;

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
                validator: (value) =>
                    Validators.required(value, fieldLabel: 'reference number'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),

              // The Treasurer's Office reconciles against the bank's date, not
              // the date we were told, so this is the day the money moved.
              // Bounded to the past: nobody has paid tomorrow.
              DatePickerField(
                label: 'Date paid *',
                value: _paidOn,
                firstDate: DateTime(DateTime.now().year - 2),
                lastDate: DateTime.now(),
                validator: (value) =>
                    value == null ? 'Enter the date you paid.' : null,
                onChanged: (value) => setState(() => _paidOn = value),
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
