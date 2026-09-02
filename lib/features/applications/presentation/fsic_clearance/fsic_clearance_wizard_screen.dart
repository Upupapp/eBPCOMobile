import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/contract/admin_vocabulary.dart';
import '../../../../core/models/fsic_permit_model.dart';
import 'steps/step1_applicant_info.dart';
import 'steps/step2_project_details.dart';
import 'steps/step3_required_documents.dart';
import 'steps/step4_certification.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/fsic_permit_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/drafts/fsic_permit_draft_codec.dart';
import '../../../../core/drafts/form_payload.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../../shared/widgets/layout/wizard_progress_header.dart';
import '../widgets/submit_permit_application.dart';
import '../../../../shared/widgets/layout/reattach_notice.dart';

class _StepMeta {
  final String title;
  final String subtitle;
  const _StepMeta({required this.title, required this.subtitle});
}

/// Fire Safety Inspection Certificate (FSIC) application wizard — a 4-step flow built from the
/// BFP Castilla Fire Station's own form, as transcribed in the requirements
/// catalog.
///
/// One of the two fire clearances the admin portal recognises and this app
/// could not file. Both are preconditions under RA 9514, and both are issued
/// and charged for by the **Bureau of Fire Protection** rather than the LGU —
/// which is why the wizard says so on every screen an applicant might read as
/// a bill.
class FsicClearanceWizardScreen extends StatefulWidget {
  const FsicClearanceWizardScreen({super.key});

  @override
  State<FsicClearanceWizardScreen> createState() =>
      _FsicClearanceWizardScreenState();
}

class _FsicClearanceWizardScreenState extends State<FsicClearanceWizardScreen> {
  static const totalSteps = 4;
  static const implementedStepCount = 4;

  static const List<_StepMeta> _stepMeta = [
    _StepMeta(
      title: 'Applicant Information',
      subtitle: 'Tell us who is applying and how to reach you.',
    ),
    _StepMeta(
      title: 'Project Details',
      subtitle: 'Describe the building this clearance concerns.',
    ),
    _StepMeta(
      title: 'Required Documents',
      subtitle: 'Upload what the Bureau of Fire Protection needs.',
    ),
    _StepMeta(
      title: 'Certification & Submission',
      subtitle: 'Certify your application and submit it.',
    ),
  ];

  late final PageController _pageController;
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    implementedStepCount,
    (_) => GlobalKey<FormState>(),
  );

  late FsicPermitDraft _draft;
  late int _currentStep;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FsicPermitProvider>();
    final wasResuming = provider.hasResumableDraft;
    _draft = provider.resumeOrStart();
    _currentStep = provider.currentStep.clamp(0, implementedStepCount - 1);
    _pageController = PageController(initialPage: _currentStep);

    if (!wasResuming) {
      _prefillFromProfile();
    }

    if (wasResuming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resumed your saved draft.')),
        );
      });
    }
  }

  /// Prefills whatever profile information is available for a brand-new
  /// draft — a read-only lookup, never written back to [AuthProvider].
  void _prefillFromProfile() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    _draft.applicant
      ..firstName = user.firstName
      ..lastName = user.lastName
      ..contactNumber = user.mobileNumber
      ..address = user.address;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDraftChanged() => setState(() {});

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    context.read<FsicPermitProvider>().goToStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 0:
        return _draft.isStep1Valid;
      case 1:
        return _draft.isStep2Valid;
      case 2:
        return _draft.isStep3Valid;
      case 3:
        return _draft.isStep4Valid;
      default:
        return false;
    }
  }

  void _handleContinue() {
    if (!_isCurrentStepValid) return;
    if (_currentStep < implementedStepCount - 1) {
      _goToStep(_currentStep + 1);
    } else {
      _handleSubmit();
    }
  }

  Future<void> _handleSubmit() async {
    final provider = context.read<FsicPermitProvider>();
    provider.submitApplication();
    final now = DateTime.now();
    final referenceNumber =
        'FSIC-${now.year}-${(now.millisecondsSinceEpoch % 900000 + 100000)}';
    final application = await submitPermitApplication(
      context,
      // Everything the applicant typed. Sent since 31 August 2026;
      // before this a filing carried none of it. See permitFormPayload.
      form: permitFormPayload(const FsicPermitDraftCodec(), _draft),
      // The attachments the citizen added. Passed since 31 August
      // 2026; before that submitPermitApplication hardcoded an empty
      // list and none of them were ever uploaded.
      documents: permitDocuments(const FsicPermitDraftCodec(), _draft),
      referenceNumber: referenceNumber,
      permitTypeLabel: CanonicalPermitType.fsicForOccupancyPermitBfp.wire,
      applicantName: applicantDisplayName(
        enterpriseName: _draft.applicant.enterpriseName,
        firstName: _draft.applicant.firstName,
        lastName: _draft.applicant.lastName,
      ),
    );
    // Null means the submission failed and the applicant has been told. Stay
    // on the step so their work is still in front of them.
    if (application == null || !mounted) return;
    context.pushReplacement(
      '/applications/new/fsic-clearance/submitted',
      extra: {
        'applicationId': application.id,
        'referenceNumber': referenceNumber,
        'submissionDate': now,
      },
    );
  }

  void _handleSaveDraft() {
    context.read<FsicPermitProvider>().saveAsDraft();
    _showMessage('Draft saved successfully.');
  }

  Future<void> _handleExitAttempt() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Leave application?',
      message:
          'Save your progress as a draft before leaving so you can pick up where you left off.',
      confirmLabel: 'Save & Exit',
      cancelLabel: 'Keep Editing',
    );
    if (!confirmed || !mounted) return;
    context.read<FsicPermitProvider>().saveAsDraft();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final meta = _stepMeta[_currentStep];
    final isFirstStep = _currentStep == 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExitAttempt();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fire Safety Inspection Certificate'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Exit',
            onPressed: _handleExitAttempt,
          ),
          actions: [
            TextButton(
              onPressed: _handleSaveDraft,
              child: const Text('Save Draft'),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              WizardProgressHeader(
                intro:
                    'Complete your FSIC application step by step. This is '
                    'issued by the Bureau of Fire Protection, not the Building '
                    'Office.',
                currentStep: _currentStep,
                totalSteps: totalSteps,
                title: meta.title,
                subtitle: meta.subtitle,
              ),
              // What this draft could not give back. The Drafts row names them too,
              // but that is where the applicant CHOSE the draft, not where they
              // fill it in — an empty slot on a step they remember finishing needs
              // its explanation here.
              ReattachNotice(
                documents: context
                    .watch<FsicPermitProvider>()
                    .documentsToReattach,
                onDismiss: () => context
                    .read<FsicPermitProvider>()
                    .acknowledgeDetachedDocuments(),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Step1ApplicantInfo(
                      formKey: _formKeys[0],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step2ProjectDetails(
                      formKey: _formKeys[1],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step3RequiredDocuments(
                      formKey: _formKeys[2],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step4Certification(
                      formKey: _formKeys[3],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                  ],
                ),
              ),
              _BottomActionBar(
                isFirstStep: isFirstStep,
                isContinueEnabled: _isCurrentStepValid,
                continueLabel: _currentStep == implementedStepCount - 1
                    ? 'Submit Application'
                    : 'Continue',
                onBack: () => _goToStep(_currentStep - 1),
                onContinue: _handleContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final bool isFirstStep;
  final bool isContinueEnabled;
  final String continueLabel;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _BottomActionBar({
    required this.isFirstStep,
    required this.isContinueEnabled,
    this.continueLabel = 'Continue',
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final continueButton = PrimaryButton(
      label: continueLabel,
      onPressed: isContinueEnabled ? onContinue : null,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPaddingHorizontal,
        AppSpacing.sm,
        AppConstants.screenPaddingHorizontal,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: isFirstStep
          ? continueButton
          : Row(
              children: [
                Expanded(
                  child: SecondaryButton(label: 'Back', onPressed: onBack),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 2, child: continueButton),
              ],
            ),
    );
  }
}
