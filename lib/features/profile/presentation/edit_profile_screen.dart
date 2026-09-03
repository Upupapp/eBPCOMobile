import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';
import '../../../shared/widgets/dialogs/success_dialog.dart';
import '../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../shared/widgets/text_fields/app_text_field.dart';
import 'widgets/profile_photo_avatar.dart';
import 'widgets/profile_photo_bottom_sheet.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/repositories/auth_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _streetController;
  late final TextEditingController _provinceController;
  late final TextEditingController _cityController;
  late final TextEditingController _barangayController;
  late final TextEditingController _postalCodeController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _middleNameController = TextEditingController(text: user?.middleName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _mobileController = TextEditingController(text: user?.mobileNumber ?? '');
    _streetController = TextEditingController(text: user?.street ?? '');
    _provinceController = TextEditingController(text: user?.province ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _barangayController = TextEditingController(text: user?.barangay ?? '');
    _postalCodeController = TextEditingController(text: user?.postalCode ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _streetController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _barangayController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleEditPhoto() async {
    final authProvider = context.read<AuthProvider>();
    final hasPhoto = authProvider.currentUser?.photoPath != null;

    await showProfilePhotoOptions(
      context,
      hasPhoto: hasPhoto,
      onTakePhoto: () => authProvider.updateProfilePhoto('mock_photo'),
      onChooseFromGallery: () => authProvider.updateProfilePhoto('mock_photo'),
      onRemovePhoto: () => authProvider.updateProfilePhoto(null),
    );
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _isSubmitting = true);

    final ProfileUpdate update;
    try {
      update = await context.read<AuthProvider>().updateProfile(
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        street: _streetController.text.trim(),
        province: _provinceController.text.trim(),
        city: _cityController.text.trim(),
        barangay: _barangayController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );
    } catch (error) {
      // Stays on the screen with everything typed still in it. This method
      // used to write three fields to the device, tell nobody, and announce
      // success — so a citizen who had moved house believed the office knew.
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException && error.failure == ApiFailure.rejected
                ? error.applicantMessage
                : 'Could not save your details. Check your connection and try '
                      'again — the office still has your previous details.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    await SuccessDialog.show(
      context,
      message: update.mobileVerificationCleared
          // Unverified, not pending. The office has no message provider
          // configured, so a code cannot reach the new number at all today —
          // under a pending model the change would never take effect and a
          // citizen who moved would be stranded on their old number.
          ? 'Your details are with the Office of the Building Official. Your '
                'new mobile number is in use immediately, but it is now '
                'unverified — the office will confirm it with you.'
          : 'Your details are with the Office of the Building Official.',
    );
    if (mounted) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = context.watch<AuthProvider>().currentUser?.photoPath;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: FormScrollScaffold(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ProfilePhotoAvatar(
                    photoPath: photoPath,
                    initials:
                        context.read<AuthProvider>().currentUser?.initials ??
                        'U',
                    onEditTap: _handleEditPhoto,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      Validators.required(v, fieldLabel: 'First name'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _middleNameController,
                  label: 'Middle Name',
                  hint: 'Optional',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      Validators.required(v, fieldLabel: 'Last name'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  enabled: false,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _mobileController,
                  label: 'Mobile Number',
                  hint: '09XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                  validator: Validators.philippineMobile,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _streetController,
                  label: 'Address',
                  hint: 'House or building number, street',
                  validator: (v) =>
                      Validators.required(v, fieldLabel: 'Address'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _provinceController,
                  label: 'Province',
                  validator: (v) =>
                      Validators.required(v, fieldLabel: 'Province'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _cityController,
                  label: 'City/Municipality',
                  validator: (v) => Validators.required(
                    v,
                    fieldLabel: 'City or municipality',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _barangayController,
                  label: 'Barangay',
                  validator: (v) =>
                      Validators.required(v, fieldLabel: 'Barangay'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _postalCodeController,
                  label: 'ZIP Code',
                  keyboardType: TextInputType.number,
                  // Optional here, unlike registration: the office has never
                  // asked most citizens for this, and blank means clear it.
                  // Four digits or nothing — the server answers 400 otherwise.
                  validator: Validators.optionalPostalCode,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Cancel',
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        label: 'Save Changes',
                        isLoading: _isSubmitting,
                        onPressed: _handleSave,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
