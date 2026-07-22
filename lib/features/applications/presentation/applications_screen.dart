import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/building_permit_model.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/application_option_card.dart';
import 'widgets/before_you_start_card.dart';

/// Landing page for the "Applications" tab: a catalog of permit/application
/// types the user can file, grouped into a "Select Form Project Type" grid
/// and an "Other Applications" list, plus a "Before you start" checklist.
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  void _startNewApplication(BuildContext context) {
    context.push('/applications/new');
  }

  /// The four "Select Form Project Type" cards and the "Building Permit"
  /// card all lead into the Building Permit wizard; the project type (when
  /// known) is passed through so Step 3 can preselect the matching Scope
  /// of Work option.
  void _startBuildingPermit(
    BuildContext context, {
    BuildingPermitProjectScope? projectScope,
  }) {
    context.push('/applications/new/building-permit', extra: projectScope);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.screenPaddingHorizontal,
            AppSpacing.lg,
            AppConstants.screenPaddingHorizontal,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              'Choose the application you want to file.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Select Form Project Type', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose the application you want to file.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                mainAxisExtent: 214,
              ),
              children: [
                ApplicationOptionCard(
                  icon: Icons.add_home_work_outlined,
                  title: 'New Construction',
                  description:
                      'For building a completely new structure or property from the ground up, such as houses, commercial buildings, or facilities.',
                  onTap: () => _startBuildingPermit(
                    context,
                    projectScope: BuildingPermitProjectScope.newConstruction,
                  ),
                ),
                ApplicationOptionCard(
                  icon: Icons.handyman_outlined,
                  title: 'Renovation',
                  description:
                      'For improving, remodeling, or upgrading an existing structure without significantly increasing its size or floor area.',
                  onTap: () => _startBuildingPermit(
                    context,
                    projectScope: BuildingPermitProjectScope.renovation,
                  ),
                ),
                ApplicationOptionCard(
                  icon: Icons.open_in_full_rounded,
                  title: 'Extension',
                  description:
                      'For adding new spaces or expanding parts of an existing building, such as additional rooms, floors, or attached structures.',
                  onTap: () => _startBuildingPermit(
                    context,
                    projectScope: BuildingPermitProjectScope.extension,
                  ),
                ),
                ApplicationOptionCard(
                  icon: Icons.domain_disabled_outlined,
                  title: 'Demolition',
                  description:
                      'For safely removing or tearing down an existing structure, building, or portion of a property.',
                  onTap: () => _startBuildingPermit(
                    context,
                    projectScope: BuildingPermitProjectScope.demolition,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Other Applications', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            ApplicationOptionCard(
              layout: ApplicationOptionCardLayout.list,
              icon: Icons.assignment_outlined,
              title: 'Building Permit',
              description:
                  'Apply for a building permit for new construction, renovation, or repair.',
              accentColor: AppColors.secondaryBlue,
              accentBackgroundColor: AppColors.lightBlue,
              onTap: () => _startBuildingPermit(context),
            ),
            const SizedBox(height: AppSpacing.md),
            ApplicationOptionCard(
              layout: ApplicationOptionCardLayout.list,
              icon: Icons.verified_outlined,
              title: 'Certificate of Occupancy',
              description:
                  'Apply for a certificate of occupancy after building completion.',
              accentColor: AppColors.secondaryBlue,
              accentBackgroundColor: AppColors.lightBlue,
              onTap: () => _startNewApplication(context),
            ),
            const SizedBox(height: AppSpacing.xl),

            const BeforeYouStartCard(),
          ],
        ),
      ),
    );
  }
}
