import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/application_model.dart';
import '../../../core/providers/applications_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/badges/status_badge.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/search/app_search_field.dart';
import '../../../shared/widgets/states/empty_state.dart';
import '../../../shared/widgets/states/loading_view.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final applicationsProvider = context.watch<ApplicationsProvider>();
    final query = _query.trim().toLowerCase();
    final applications = applicationsProvider.applications.where((
      application,
    ) {
      if (query.isEmpty) return true;
      return application.businessName.toLowerCase().contains(query) ||
          application.applicationNumber.toLowerCase().contains(query);
    }).toList()..sort((a, b) => b.submittedDate.compareTo(a.submittedDate));
    final hasAnyApplication = applicationsProvider.applications.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: SafeArea(
        child: applicationsProvider.isLoading
            ? const LoadingView()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.screenPaddingHorizontal,
                      12,
                      AppConstants.screenPaddingHorizontal,
                      0,
                    ),
                    child: AppSearchField(
                      hint: 'Search applications',
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  Expanded(
                    child: applications.isEmpty
                        ? EmptyState(
                            icon: Icons.folder_open_outlined,
                            title: hasAnyApplication
                                ? 'No matching applications'
                                : 'No applications yet',
                            message: hasAnyApplication
                                ? 'Try a different search term.'
                                : 'Apply for a permit to see it listed here.',
                            action: hasAnyApplication
                                ? null
                                : PrimaryButton(
                                    label: 'New Application',
                                    onPressed: () =>
                                        context.push('/applications/new'),
                                  ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(
                              AppConstants.screenPaddingHorizontal,
                            ),
                            itemCount: applications.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _ApplicationTile(application: applications[index]),
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: !hasAnyApplication
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/applications/new'),
              icon: const Icon(Icons.add),
              label: const Text('New Application'),
            ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  final ApplicationModel application;

  const _ApplicationTile({required this.application});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/applications/${application.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.businessName,
                      style: AppTypography.cardTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(application.type.label, style: AppTypography.bodyMuted),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: application.status.label,
                color: application.status.color,
                backgroundColor: application.status.backgroundColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(application.applicationNumber, style: AppTypography.caption),
        ],
      ),
    );
  }
}
