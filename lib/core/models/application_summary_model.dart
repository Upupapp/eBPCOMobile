import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Represents the status of a permit application in the mock dataset.
enum ApplicationStatus {
  draft,
  submitted,
  underReview,
  approved,
  released,
  rejected,
}

extension ApplicationStatusX on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.draft:
        return 'Draft';
      case ApplicationStatus.submitted:
        return 'Submitted';
      case ApplicationStatus.underReview:
        return 'Under Review';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.released:
        return 'Released';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.draft:
        return AppColors.textMuted;
      case ApplicationStatus.submitted:
        return AppColors.statusInfo;
      case ApplicationStatus.underReview:
        return AppColors.statusPending;
      case ApplicationStatus.approved:
        return AppColors.statusApproved;
      case ApplicationStatus.released:
        return AppColors.statusApproved;
      case ApplicationStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ApplicationStatus.draft:
        return AppColors.surfaceMuted;
      case ApplicationStatus.submitted:
        return AppColors.statusInfoBg;
      case ApplicationStatus.underReview:
        return AppColors.statusPendingBg;
      case ApplicationStatus.approved:
        return AppColors.statusApprovedBg;
      case ApplicationStatus.released:
        return AppColors.statusApprovedBg;
      case ApplicationStatus.rejected:
        return AppColors.statusRejectedBg;
    }
  }
}

/// Mock model describing a permit application shown on the dashboard.
class ApplicationSummaryModel {
  final String applicationNumber;
  final String businessName;
  final String applicationType;
  final ApplicationStatus status;
  final double progress;
  final String nextStep;

  const ApplicationSummaryModel({
    required this.applicationNumber,
    required this.businessName,
    required this.applicationType,
    required this.status,
    required this.progress,
    required this.nextStep,
  });
}
