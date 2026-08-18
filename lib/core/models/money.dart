import 'package:intl/intl.dart';

/// A peso amount, held as whole centavos.
///
/// A value type rather than a bare `int` so pesos and centavos cannot be
/// mixed up at a call site, and never a `double`: the web admin stores money
/// as integer centavos, and a fee schedule rendered through binary floating
/// point acquires rounding error that an applicant discovers at the cashier
/// when the app's total and the Order of Payment disagree by a centavo.
class PesoAmount implements Comparable<PesoAmount> {
  final int centavos;

  const PesoAmount(this.centavos);

  const PesoAmount.zero() : centavos = 0;

  /// For literals in seed data and tests, where writing centavos is unreadable.
  /// Rounds half-away-from-zero so a value like 1234.565 cannot silently
  /// truncate.
  factory PesoAmount.fromPesos(num pesos) =>
      PesoAmount((pesos * 100).round());

  PesoAmount operator +(PesoAmount other) =>
      PesoAmount(centavos + other.centavos);

  bool get isZero => centavos == 0;

  static final _format = NumberFormat('#,##0.00', 'en_PH');

  /// `PHP 12,345.67` — the form used on an Order of Payment.
  String get formatted => 'PHP ${_format.format(centavos / 100)}';

  /// `12,345.67`, for places that supply their own currency label.
  String get formattedBare => _format.format(centavos / 100);

  @override
  int compareTo(PesoAmount other) => centavos.compareTo(other.centavos);

  @override
  bool operator ==(Object other) =>
      other is PesoAmount && other.centavos == centavos;

  @override
  int get hashCode => centavos.hashCode;

  @override
  String toString() => formatted;
}

/// Sums a list of amounts. Exact, because the addends are integers.
PesoAmount sumPesos(Iterable<PesoAmount> amounts) {
  var total = 0;
  for (final amount in amounts) {
    total += amount.centavos;
  }
  return PesoAmount(total);
}
