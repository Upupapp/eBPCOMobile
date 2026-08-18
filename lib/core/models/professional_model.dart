import 'document_model.dart';

/// Disciplines a design professional can be tagged to an application under.
enum ProfessionalDiscipline {
  architect,
  civilEngineer,
  structuralEngineer,
  electricalEngineer,
  mechanicalEngineer,
  sanitaryEngineer,
  plumbingEngineer,
  electronicsEngineer,
  interiorDesigner,
  geodeticEngineer,
}

extension ProfessionalDisciplineX on ProfessionalDiscipline {
  String get label {
    switch (this) {
      case ProfessionalDiscipline.architect:
        return 'Architect';
      case ProfessionalDiscipline.civilEngineer:
        return 'Civil Engineer';
      case ProfessionalDiscipline.structuralEngineer:
        return 'Structural Engineer';
      case ProfessionalDiscipline.electricalEngineer:
        return 'Professional Electrical Engineer';
      case ProfessionalDiscipline.mechanicalEngineer:
        return 'Professional Mechanical Engineer';
      case ProfessionalDiscipline.sanitaryEngineer:
        return 'Sanitary Engineer';
      case ProfessionalDiscipline.plumbingEngineer:
        return 'Master Plumber';
      case ProfessionalDiscipline.electronicsEngineer:
        return 'Professional Electronics Engineer';
      case ProfessionalDiscipline.interiorDesigner:
        return 'Interior Designer';
      case ProfessionalDiscipline.geodeticEngineer:
        return 'Geodetic Engineer';
    }
  }
}

/// A licensed professional tagged to the applicant's projects.
///
/// Modelled as a linked party with their own credentials rather than as free
/// text typed into each wizard, mirroring how QC e-Services has the design
/// professional hold their own account and be tagged to the application. It
/// also means a lapsed PRC is caught once, here, instead of being discovered
/// at the counter.
class ProfessionalModel {
  final String id;
  final String fullName;
  final ProfessionalDiscipline discipline;

  /// PRC licence number and the date it lapses.
  final String prcNumber;
  final DateTime prcValidityDate;

  /// Professional Tax Receipt — number, when it was issued, and where.
  final String ptrNumber;
  final DateTime ptrDateIssued;
  final String ptrPlaceIssued;

  final DocumentModel? prcIdImage;
  final DocumentModel? ptrImage;

  const ProfessionalModel({
    required this.id,
    required this.fullName,
    required this.discipline,
    required this.prcNumber,
    required this.prcValidityDate,
    required this.ptrNumber,
    required this.ptrDateIssued,
    required this.ptrPlaceIssued,
    this.prcIdImage,
    this.ptrImage,
  });

  bool isPrcExpired(DateTime asOf) => prcValidityDate.isBefore(_day(asOf));

  /// Days until the PRC lapses; negative once it has.
  int prcDaysRemaining(DateTime asOf) =>
      _day(prcValidityDate).difference(_day(asOf)).inDays;

  /// Warn from 60 days out, so there is time to renew before the next filing
  /// rather than after a submission is refused.
  bool prcNeedsAttention(DateTime asOf) => prcDaysRemaining(asOf) <= 60;

  /// A PTR is valid for the calendar year in which it was issued, so one from
  /// a previous year will not be accepted on a new filing.
  bool isPtrStale(DateTime asOf) => ptrDateIssued.year < asOf.year;

  bool get hasCompleteCredentials => prcIdImage != null && ptrImage != null;

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

/// Someone permitted to file or claim on the applicant's behalf.
///
/// Both documents are required rather than optional: a representative
/// claiming a permit has to present a notarised Special Power of Attorney and
/// their own valid ID, so a record missing either cannot actually be used.
class AuthorizedRepresentative {
  final String id;
  final String fullName;
  final String relationship;

  /// Notarised SPA. Notarised documents are outside RA 8792's functional
  /// equivalence, so this is a scan of a wet-signed original, not a substitute
  /// for one.
  final DocumentModel? specialPowerOfAttorney;
  final DocumentModel? validId;

  final DateTime? authorizedUntil;

  const AuthorizedRepresentative({
    required this.id,
    required this.fullName,
    required this.relationship,
    this.specialPowerOfAttorney,
    this.validId,
    this.authorizedUntil,
  });

  bool get canAct => specialPowerOfAttorney != null && validId != null;

  bool isExpired(DateTime asOf) {
    final until = authorizedUntil;
    if (until == null) return false;
    return until.isBefore(DateTime(asOf.year, asOf.month, asOf.day));
  }

  /// What is stopping this representative from acting, or null if nothing is.
  String? blockingReason(DateTime asOf) {
    if (specialPowerOfAttorney == null && validId == null) {
      return 'Needs a notarised Special Power of Attorney and a valid ID.';
    }
    if (specialPowerOfAttorney == null) {
      return 'Needs a notarised Special Power of Attorney.';
    }
    if (validId == null) return 'Needs a copy of their valid ID.';
    if (isExpired(asOf)) return 'Their authorisation has lapsed.';
    return null;
  }
}
