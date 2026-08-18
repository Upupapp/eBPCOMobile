import 'package:flutter/foundation.dart';

import '../models/professional_model.dart';

/// The licensed professionals and authorised representatives attached to the
/// applicant's projects.
///
/// Held once, here, rather than retyped into each wizard. A lapsed PRC is then
/// caught in one place instead of being discovered at the counter, and an
/// applicant filing a fourth permit does not key the same architect's licence
/// details in for the fourth time.
class ProfessionalsProvider extends ChangeNotifier {
  ProfessionalsProvider({
    List<ProfessionalModel>? professionals,
    List<AuthorizedRepresentative>? representatives,
    DateTime Function()? clock,
  }) : _professionals = [...?professionals],
       _representatives = [...?representatives],
       _clock = clock ?? DateTime.now;

  final List<ProfessionalModel> _professionals;
  final List<AuthorizedRepresentative> _representatives;
  final DateTime Function() _clock;

  List<ProfessionalModel> get professionals =>
      List.unmodifiable(_professionals);

  List<AuthorizedRepresentative> get representatives =>
      List.unmodifiable(_representatives);

  /// Professionals whose PRC has lapsed or is about to, soonest first.
  ///
  /// Drives the credential warning: a filing signed and sealed by someone
  /// whose licence expired will be returned, and the applicant is the one who
  /// pays for that in weeks.
  List<ProfessionalModel> get professionalsNeedingAttention {
    final now = _clock();
    final due = _professionals
        .where((p) => p.prcNeedsAttention(now) || p.isPtrStale(now))
        .toList();
    due.sort(
      (a, b) => a.prcDaysRemaining(now).compareTo(b.prcDaysRemaining(now)),
    );
    return due;
  }

  /// Representatives that cannot actually act yet, because something required
  /// is missing or their authorisation has lapsed.
  List<AuthorizedRepresentative> get representativesBlocked {
    final now = _clock();
    return _representatives
        .where((r) => r.blockingReason(now) != null)
        .toList();
  }

  ProfessionalModel? professionalById(String id) {
    for (final professional in _professionals) {
      if (professional.id == id) return professional;
    }
    return null;
  }

  void saveProfessional(ProfessionalModel professional) {
    final index = _professionals.indexWhere((p) => p.id == professional.id);
    if (index == -1) {
      _professionals.add(professional);
    } else {
      _professionals[index] = professional;
    }
    notifyListeners();
  }

  void removeProfessional(String id) {
    _professionals.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void saveRepresentative(AuthorizedRepresentative representative) {
    final index = _representatives.indexWhere(
      (r) => r.id == representative.id,
    );
    if (index == -1) {
      _representatives.add(representative);
    } else {
      _representatives[index] = representative;
    }
    notifyListeners();
  }

  void removeRepresentative(String id) {
    _representatives.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  /// A stable-enough identifier for a locally created record.
  String newId(String prefix) =>
      '$prefix-${_clock().microsecondsSinceEpoch}';
}
