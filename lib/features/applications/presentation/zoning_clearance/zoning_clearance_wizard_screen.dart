import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/contract/admin_vocabulary.dart';
import '../../../../core/models/zoning_permit_model.dart';
import 'steps/step1_applicant_info.dart';
import 'steps/step2_site_location.dart';
import 'steps/step3_proposed_use.dart';
import 'steps/step4_required_documents.dart';
import 'steps/step5_certification.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/zoning_permit_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/drafts/zoning_permit_draft_codec.dart';
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

/// Zoning / Locational Clearance application wizard — a 5-step flow built from
/// the Municipality of Castilla MPDO's own Form FM-MPD-12, as transcribed in
/// the requirements catalog.
///
/// The first of the three permit types the admin portal recognises and this
/// app could not file. It matters more than its size suggests: most other
/// permit types list a Locational Clearance among the documents an applicant
/// must already hold, so until now the app asked for a clearance it gave no
/// way to obtain.
///
/// Issued by the Municipal Planning and Development Office, not the Office of
/// the Building Official, and assessed under the zoning ordinance rather than
/// the National Building Code.
class ZoningClearanceWizardScreen extends StatefulWidget {
  const ZoningClearanceWizardScreen({super.key});

  @override
  State<ZoningClearanceWizardScreen> createState() =>
      _ZoningClearanceWizardScreenState();
}

class _ZoningClearanceWizardScreenState
    extends State<ZoningClearanceWizardScreen> {
  static const totalSteps = 5;
  static const implementedStepCount = 5;

  static const List<_StepMeta> _stepMeta = [
    _StepMeta(
      title: 'Applicant Information',
      subtitle: 'Tell us who is applying and how to reach you.',
    ),
    _StepMeta(
      title: 'Site Location',
      subtitle: 'Identify the lot the clearance is sought for.',
    ),
    _StepMeta(
      title: 'Proposed Use',
      subtitle: 'Describe what you intend to do with the lot.',
    ),
    _StepMeta(
      title: 'Required Documents',
      subtitle: 'Upload what the MPDO needs to evaluate your application.',
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

  late ZoningPermitDraft _draft;
  late int _currentStep;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ZoningPermitProvider>();
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
    context.read<ZoningPermitProvider>().goToStep(step);
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
      case 4:
        return _draft.isStep5Valid;
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
    final provider = context.read<ZoningPermitProvider>();
    provider.submitApplication();
    final now = DateTime.now();
    final referenceNumber =
        'ZON-${now.year}-${(now.millisecondsSinceEpoch % 900000 + 100000)}';
    final application = await submitPermitApplication(
      context,
      // Everything the applicant typed. Sent since 31 August 2026;
      // before this a filing carried none of it. See permitFormPayload.
      form: permitFormPayload(const ZoningPermitDraftCodec(), _draft),
      // The contract has declared a nullable `location` since it was
      // written, and the app sent nothing — so the office learned the
      // permit type and the applicant and not the site.
      location: constructionLocationLine(
        lot: _draft.siteLocation.lotNumber,
        block: _draft.siteLocation.blockNumber,
        street: _draft.siteLocation.street,
        barangay: _draft.siteLocation.barangay,
        city: _draft.siteLocation.city,
      ),
      referenceNumber: referenceNumber,
      permitTypeLabel: CanonicalPermitType.zoningLocationalClearance.wire,
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
      '/applications/new/zoning-clearance/submitted',
      extra: {
        'applicationId': application.id,
        'referenceNumber': referenceNumber,
        'submissionDate': now,
      },
    );
  }

  void _handleSaveDraft() {
    context.read<ZoningPermitProvider>().saveAsDraft();
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
    context.read<ZoningPermitProvider>().saveAsDraft();
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
          title: const Text('Zoning / Locational Clearance'),
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
                    'Complete your Locational Clearance application step by '
                    'step. This is issued by the MPDO, not the Building '
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
                    .watch<ZoningPermitProvider>()
                    .documentsToReattach,
                onDismiss: () => context
                    .read<ZoningPermitProvider>()
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
                    Step2SiteLocation(
                      formKey: _formKeys[1],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step3ProposedUse(
                      formKey: _formKeys[2],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step4RequiredDocuments(
                      formKey: _formKeys[3],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step5Certification(
                      formKey: _formKeys[4],
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
