/// How an application is classified for service-standard purposes under
/// RA 11032 (Ease of Doing Business and Efficient Government Service Delivery
/// Act of 2018), as applied to construction-related permits by Amended Joint
/// Memorandum Circular No. 2021-01.
///
/// The classification is assigned by the LGU, never by this app — it depends
/// on the number of storeys, floor area, and occupancy of the project as
/// evaluated by the Office of the Building Official. Mobile displays what the
/// LGU assigned and nothing more.
enum PermitClassification { simple, complex, highlyTechnical }

extension PermitClassificationX on PermitClassification {
  /// Maximum processing time in working days prescribed by RA 11032.
  int get prescribedWorkingDays {
    switch (this) {
      case PermitClassification.simple:
        return 3;
      case PermitClassification.complex:
        return 7;
      case PermitClassification.highlyTechnical:
        return 20;
    }
  }

  String get label {
    switch (this) {
      case PermitClassification.simple:
        return 'Simple';
      case PermitClassification.complex:
        return 'Complex';
      case PermitClassification.highlyTechnical:
        return 'Highly Technical';
    }
  }

  /// Shown beside the countdown so the applicant knows where the number came
  /// from rather than having to take it on trust.
  String get pledgeDescription =>
      '$label application — $prescribedWorkingDays working days under RA 11032.';
}
