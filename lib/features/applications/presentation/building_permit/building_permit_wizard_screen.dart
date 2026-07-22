import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/building_permit_model.dart';
import '../../../../core/providers/building_permit_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';
import 'steps/step1_applicant_info.dart';
import 'steps/step2_property_location.dart';
import 'steps/step3_scope_of_work.dart';
import 'steps/step4_building_use.dart';
import 'steps/step5_project_details.dart';
import 'steps/step6_professional.dart';
import 'steps/step7_consent.dart';
import 'steps/step8_documents.dart';
import 'steps/step9_review.dart';
import 'steps/step10_assessment_payment.dart';

class _StepMeta {
  final String title;
  final String subtitle;
  const _StepMeta({required this.title, required this.subtitle});
}

/// 10-step mobile wizard for the Unified Application Form for Building
/// Permit and Fire Safety Evaluation Clearance (New application flow
/// only). All data lives in a [BuildingPermitDraft] held by
/// [BuildingPermitProvider] so the draft survives if the user exits and
/// reopens the flow within the same app session.
class BuildingPermitWizardScreen extends StatefulWidget {
  final BuildingPermitProjectScope? initialProjectScope;

  const BuildingPermitWizardScreen({super.key, this.initialProjectScope});

  @override
  State<BuildingPermitWizardScreen> createState() =>
      _BuildingPermitWizardScreenState();
}

class _BuildingPermitWizardScreenState
    extends State<BuildingPermitWizardScreen> {
  static const totalSteps = 10;

  static const List<_StepMeta> _stepMeta = [
    _StepMeta(
      title: 'Applicant Information',
      subtitle:
          'Tell us who owns the property and who is filing this application.',
    ),
    _StepMeta(
      title: 'Property Location',
      subtitle:
          'Provide the official location and property references for the construction site.',
    ),
    _StepMeta(
      title: 'Scope of Work',
      subtitle:
          'Confirm the type of construction activity included in this application.',
    ),
    _StepMeta(
      title: 'Building Use',
      subtitle:
          'Select the primary purpose or occupancy classification of the proposed building.',
    ),
    _StepMeta(
      title: 'Project Details',
      subtitle:
          'Provide the size, cost estimate, and expected construction schedule.',
    ),
    _StepMeta(
      title: 'Architect or Civil Engineer',
      subtitle:
          'Provide the licensed professional who will inspect and supervise the construction work.',
    ),
    _StepMeta(
      title: 'Consent and Authorization',
      subtitle:
          'Complete this section when the applicant is not the registered lot owner or is filing through an authorized representative.',
    ),
    _StepMeta(
      title: 'Document Upload',
      subtitle: 'Upload the required forms, plans, and supporting documents.',
    ),
    _StepMeta(
      title: 'Review Application',
      subtitle:
          'Review all information before proceeding to assessment and payment.',
    ),
    _StepMeta(
      title: 'Assessment and Payment',
      subtitle: 'Review the estimated fees and select how you intend to pay.',
    ),
  ];

  late final PageController _pageController;
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    totalSteps,
    (_) => GlobalKey<FormState>(),
  );

  late BuildingPermitDraft _draft;
  late int _currentStep;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<BuildingPermitProvider>();
    final wasResuming = provider.hasResumableDraft;
    _draft = provider.resumeOrStart(projectScope: widget.initialProjectScope);
    _currentStep = provider.currentStep;
    _pageController = PageController(initialPage: _currentStep);

    if (wasResuming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resumed your saved draft.')),
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDraftChanged() => setState(() {});

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    context.read<BuildingPermitProvider>().goToStep(step);
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

  bool _validateCurrentStep() {
    final step = _currentStep;

    if (step == 2) {
      if (_draft.scopeOfWork.isEmpty) {
        _showMessage('Please select at least one scope of work.');
        return false;
      }
      if (_draft.scopeOfWork.contains(ScopeOfWorkOption.others) &&
          _draft.scopeOfWorkOtherDetail.trim().isEmpty) {
        _showMessage('Please specify the scope of work.');
        return false;
      }
    }

    if (step == 3) {
      if (_draft.occupancyGroup == null) {
        _showMessage(
          'Please select the building use or occupancy classification.',
        );
        return false;
      }
      if (_draft.occupancyGroup == OccupancyGroup.others &&
          _draft.occupancyOtherDetail.trim().isEmpty) {
        _showMessage('Please specify the occupancy use.');
        return false;
      }
    }

    if (step == 4) {
      final proposed = _draft.project.proposedConstructionDate;
      final expected = _draft.project.expectedCompletionDate;
      if (proposed != null && expected != null && !expected.isAfter(proposed)) {
        _showMessage(
          'Expected completion date must be later than the proposed construction date.',
        );
        return false;
      }
    }

    if (step == 6) {
      final consent = _draft.consent;
      if (consent.isRegisteredOwner == null) {
        _showMessage('Please answer whether you are the registered lot owner.');
        return false;
      }
      if (consent.isRegisteredOwner == false) {
        if (consent.ownerValidIdUpload == null ||
            consent.applicantValidIdUpload == null ||
            consent.authorizationLetterUpload == null) {
          _showMessage(
            'Please upload the required identification and authorization documents.',
          );
          return false;
        }
      }
      if (!consent.declarationConfirmed) {
        _showMessage(
          'Please confirm that the information provided is complete and accurate.',
        );
        return false;
      }
    }

    if (step == 7 && _draft.missingRequiredDocuments.isNotEmpty) {
      _showMessage('Please upload all required documents before continuing.');
      return false;
    }

    if (step == 8 && !_draft.allDeclarationsConfirmed) {
      _showMessage('Please agree to all declarations before proceeding.');
      return false;
    }

    final formState = _formKeys[step].currentState;
    if (formState != null && !formState.validate()) {
      _showMessage('Please complete the highlighted fields before continuing.');
      return false;
    }
    return true;
  }

  void _handleContinue() {
    if (!_validateCurrentStep()) return;
    context.read<BuildingPermitProvider>().markStepCompleted(_currentStep);
    if (_currentStep < totalSteps - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _handleSaveDraft() {
    context.read<BuildingPermitProvider>().saveAsDraft();
    _showMessage('Draft saved. You can continue anytime.');
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
    context.read<BuildingPermitProvider>().saveAsDraft();
    if (mounted) context.pop();
  }

  Future<void> _handleSubmit() async {
    if (_draft.paymentMethod == null) {
      _showMessage('Please select a payment method to continue.');
      return;
    }
    setState(() => _isSubmitting = true);
    await Future.delayed(AppConstants.mockNetworkDelay);
    if (!mounted) return;
    context.read<BuildingPermitProvider>().submitForAssessment();
    setState(() => _isSubmitting = false);
    context.pushReplacement('/applications/new/building-permit/success');
  }

  @override
  Widget build(BuildContext context) {
    final meta = _stepMeta[_currentStep];
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == totalSteps - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExitAttempt();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Building Permit'),
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
              _WizardProgressHeader(
                currentStep: _currentStep,
                totalSteps: totalSteps,
                title: meta.title,
                subtitle: meta.subtitle,
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
                    Step2PropertyLocation(
                      formKey: _formKeys[1],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step3ScopeOfWork(
                      formKey: _formKeys[2],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step4BuildingUse(
                      formKey: _formKeys[3],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step5ProjectDetails(
                      formKey: _formKeys[4],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step6Professional(
                      formKey: _formKeys[5],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step7Consent(
                      formKey: _formKeys[6],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step8Documents(
                      formKey: _formKeys[7],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                    Step9Review(
                      formKey: _formKeys[8],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                      onEditStep: _goToStep,
                    ),
                    Step10AssessmentPayment(
                      formKey: _formKeys[9],
                      draft: _draft,
                      onChanged: _onDraftChanged,
                    ),
                  ],
                ),
              ),
              _BottomActionBar(
                isFirstStep: isFirstStep,
                isLastStep: isLastStep,
                isSubmitting: _isSubmitting,
                onBack: () => _goToStep(_currentStep - 1),
                onContinue: _handleContinue,
                onSubmit: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WizardProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;

  const _WizardProgressHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPaddingHorizontal,
        12,
        AppConstants.screenPaddingHorizontal,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${currentStep + 1} of $totalSteps',
            style: AppTypography.label,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusXs),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / totalSteps,
              minHeight: 6,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.sectionTitle),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.bodyMuted),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final bool isFirstStep;
  final bool isLastStep;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSubmit;

  const _BottomActionBar({
    required this.isFirstStep,
    required this.isLastStep,
    required this.isSubmitting,
    required this.onBack,
    required this.onContinue,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final primaryButton = isLastStep
        ? PrimaryButton(
            label: 'Submit Application for Assessment',
            isLoading: isSubmitting,
            onPressed: onSubmit,
          )
        : PrimaryButton(label: 'Continue', onPressed: onContinue);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.screenPaddingHorizontal,
        12,
        AppConstants.screenPaddingHorizontal,
        12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: isFirstStep
          ? primaryButton
          : Row(
              children: [
                Expanded(
                  child: SecondaryButton(label: 'Back', onPressed: onBack),
                ),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: primaryButton),
              ],
            ),
    );
  }
}
