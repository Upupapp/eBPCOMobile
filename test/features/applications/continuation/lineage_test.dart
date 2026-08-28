import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/providers/application_intent_provider.dart';

/// What a renewal or an amendment is a continuation of.
///
/// The app filed everything as New. Both lines have carried the action since
/// the first reconciliation; what neither carried is the reference, and
/// "Renewal" without saying of what leaves the office in the same position as
/// the applicant.

void main() {
  group('a renewal', () {
    test('carries the permit it renews', () {
      final lineage = ApplicationLineage.renewal(
        priorApplicationId: 'app-1',
        priorPermitNumber: 'BP-2026-000145',
        priorApplicationNumber: 'E-BPCO-2026-000145',
        permitTypeLabel: 'Fencing Permit',
      );

      expect(lineage.action, ApplicationType.renewal);
      expect(lineage.priorPermitNumber, 'BP-2026-000145');
      expect(lineage.description, 'Renewal of permit BP-2026-000145');
    });
  });

  group('an amendment', () {
    test('carries the application it amends, and no permit', () {
      final lineage = ApplicationLineage.amendment(
        priorApplicationId: 'app-1',
        priorApplicationNumber: 'E-BPCO-2026-000145',
        permitTypeLabel: 'Fencing Permit',
      );

      expect(lineage.action, ApplicationType.amendment);
      expect(lineage.priorApplicationId, 'app-1');
      expect(
        lineage.priorPermitNumber,
        isNull,
        reason: 'an application under evaluation has no permit to name',
      );
      expect(lineage.description, contains('E-BPCO-2026-000145'));
    });
  });

  group('the pending intent', () {
    test('is consumed once, and only by a filing of the same permit type', () {
      final provider = ApplicationIntentProvider();
      provider.start(
        ApplicationLineage.renewal(
          priorApplicationId: 'app-1',
          priorPermitNumber: 'BP-2026-000145',
          permitTypeLabel: 'Fencing Permit',
        ),
      );

      expect(provider.consumeFor('Fencing Permit'), isNotNull);
      expect(
        provider.consumeFor('Fencing Permit'),
        isNull,
        reason: 'an intent that survives its filing attaches to the next one',
      );
    });

    test('a mismatched filing does not inherit it', () {
      // The applicant started a Fencing renewal, backed out, and filed an
      // Electrical permit. The electrical filing is a new application.
      final provider = ApplicationIntentProvider();
      provider.start(
        ApplicationLineage.renewal(
          priorApplicationId: 'app-1',
          priorPermitNumber: 'BP-2026-000145',
          permitTypeLabel: 'Fencing Permit',
        ),
      );

      expect(provider.consumeFor('Electrical Permit'), isNull);
    });

    test('and the mismatch clears it rather than leaving it to catch a later '
        'filing', () {
      final provider = ApplicationIntentProvider();
      provider.start(
        ApplicationLineage.renewal(
          priorApplicationId: 'app-1',
          priorPermitNumber: 'BP-2026-000145',
          permitTypeLabel: 'Fencing Permit',
        ),
      );

      provider.consumeFor('Electrical Permit');

      expect(
        provider.pending,
        isNull,
        reason: 'an overtaken intent must not lie in wait for the right type',
      );
    });

    test('a filing with no permit type inherits nothing', () {
      // The legacy Business Permit wizard passes no canonical label.
      final provider = ApplicationIntentProvider();
      provider.start(
        ApplicationLineage.amendment(
          priorApplicationId: 'app-1',
          permitTypeLabel: 'Fencing Permit',
        ),
      );

      expect(provider.consumeFor(null), isNull);
    });

    test('clear abandons it', () {
      final provider = ApplicationIntentProvider();
      provider.start(
        ApplicationLineage.amendment(
          priorApplicationId: 'app-1',
          permitTypeLabel: 'Fencing Permit',
        ),
      );
      provider.clear();
      expect(provider.pending, isNull);
    });

    test('no intent means no lineage', () {
      expect(ApplicationIntentProvider().consumeFor('Fencing Permit'), isNull);
    });
  });
}
