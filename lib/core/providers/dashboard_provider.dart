import 'package:flutter/material.dart';

import '../models/application_summary_model.dart';

/// Holds mock dashboard data: the active application and summary counters.
class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  final ApplicationSummaryModel activeApplication =
      const ApplicationSummaryModel(
        applicationNumber: 'E-BPCO-2026-000145',
        businessName: "Juan's General Merchandise",
        applicationType: 'New Business Permit',
        status: ApplicationStatus.underReview,
        progress: 0.4,
        nextStep: 'Wait for the initial document evaluation.',
      );

  final Map<String, int> summaryCounts = const {
    'Draft': 1,
    'Submitted': 2,
    'Approved': 1,
    'Released': 1,
  };

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _isLoading = false;
    notifyListeners();
  }
}
