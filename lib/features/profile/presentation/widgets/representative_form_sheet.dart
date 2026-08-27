import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/document_model.dart';
import '../../../../core/models/professional_model.dart';
import '../../../../core/providers/professionals_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/text_fields/app_text_field.dart';
import '../../../../shared/widgets/uploads/document_upload_tile.dart';
import '../../../documents/presentation/widgets/attach_document_sheet.dart';

/// Adds or edits an authorised representative.
Future<void> showRepresentativeFormSheet(
  BuildContext context, {
  AuthorizedRepresentative? existing,
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
      child: _RepresentativeForm(existing: existing),
    ),
  );
}

class _RepresentativeForm extends StatefulWidget {
  final AuthorizedRepresentative? existing;

  const _RepresentativeForm({this.existing});

  @override
  State<_RepresentativeForm> createState() => _RepresentativeFormState();
}

class _RepresentativeFormState extends State<_RepresentativeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _relationship;

  DateTime? _authorizedUntil;
  DocumentModel? _spa;
  DocumentModel? _validId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.fullName ?? '');
    _relationship = TextEditingController(text: existing?.relationship ?? '');
    _authorizedUntil = existing?.authorizedUntil;
    _spa = existing?.specialPowerOfAttorney;
    _validId = existing?.validId;
  }

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    super.dispose();
  }

  // Name and relationship only. The SPA and ID are what let them *act*, and
  // the record is saved without them so an applicant can capture the person
  // now and attach the paperwork when they have it.
  bool get _isComplete =>
      _name.text.trim().isNotEmpty && _relationship.text.trim().isNotEmpty;

  Future<void> _attach(String label, ValueChanged<DocumentModel> assign) async {
    final picked = await showAttachDocumentOptions(context, label: label);
    if (picked == null) return;
    // The picker can outlive this step; setState on a defunct State throws.
    if (!mounted) return;
    setState(() => assign(picked));
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<ProfessionalsProvider>();
    provider.saveRepresentative(
      AuthorizedRepresentative(
        id: widget.existing?.id ?? provider.newId('rep'),
        fullName: _name.text.trim(),
        relationship: _relationship.text.trim(),
        specialPowerOfAttorney: _spa,
        validId: _validId,
        authorizedUntil: _authorizedUntil,
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
                    ? 'Add a representative'
                    : 'Edit representative',
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
              AppTextField(
                controller: _relationship,
                label: 'Relationship to you *',
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    Validators.required(v, fieldLabel: 'relationship'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),

              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _authorizedUntil ?? now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 10),
                  );
                  if (picked != null) {
                    // The picker can outlive this step; setState on a defunct State throws.
                    if (!mounted) return;
                    setState(() => _authorizedUntil = picked);
                  }
                },
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Authorised until',
                    helperText: 'Optional — leave blank if open-ended',
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                  ),
                  child: Text(
                    _authorizedUntil == null
                        ? 'No end date'
                        : format.format(_authorizedUntil!),
                    style: _authorizedUntil == null
                        ? AppTypography.helper
                        : AppTypography.body,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusSmall,
                  ),
                ),
                child: Text(
                  'A representative cannot claim a permit without a notarised '
                  'Special Power of Attorney and their own valid ID. Keep the '
                  'wet-signed original — the copy here is for your reference '
                  'and for filing, not a substitute at the counter.',
                  style: AppTypography.bodyMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              DocumentUploadTile(
                label: 'Notarised Special Power of Attorney',
                document: _spa,
                allowReplace: true,
                onUpload: () => _attach(
                  'Notarised Special Power of Attorney',
                  (d) => _spa = d,
                ),
                onRemove: () => setState(() => _spa = null),
              ),
              const SizedBox(height: AppSpacing.md),
              DocumentUploadTile(
                label: 'Representative’s valid ID',
                document: _validId,
                allowReplace: true,
                onUpload: () =>
                    _attach('Representative’s valid ID', (d) => _validId = d),
                onRemove: () => setState(() => _validId = null),
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
