import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/application_summary_model.dart';
import '../../../core/providers/dashboard_provider.dart';
import '../../../core/widgets/status_chip.dart';

/// Polished placeholder for the full permit-application workflow, which
/// belongs to Day 2. Navigation and layout are fully functional now.
class ApplicationsPlaceholderScreen extends StatelessWidget {
  const ApplicationsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final ApplicationSummaryModel application =
        dashboardProvider.activeApplication;

    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingHorizontal,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 96,
                height: 96,
                margin: const EdgeInsets.only(bottom: 16),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_open_outlined,
                  size: 44,
                  color: AppColors.primaryNavy,
                ),
              ),
              const Text(
                'Full Application Workflow — Coming Soon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Submitting new permit applications, uploading requirements, and step-by-step '
                'tracking will be available in the next module. For now, you can preview your '
                'current mock application below.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusLarge,
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            application.businessName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusChip(
                          label: application.status.label,
                          color: application.status.color,
                          backgroundColor: application.status.backgroundColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${application.applicationNumber} · ${application.applicationType}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add),
                label: const Text('New Application (available in Day 2)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
