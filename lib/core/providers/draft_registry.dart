import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/draft_summary.dart';
import 'building_permit_provider.dart';
import 'renovation_permit_provider.dart';
import 'addition_extension_permit_provider.dart';
import 'demolition_permit_provider.dart';
import 'architectural_permit_provider.dart';
import 'civil_structural_permit_provider.dart';
import 'electrical_permit_provider.dart';
import 'mechanical_permit_provider.dart';
import 'sanitary_plumbing_permit_provider.dart';
import 'plumbing_permit_provider.dart';
import 'electronics_permit_provider.dart';
import 'interior_design_permit_provider.dart';
import 'fencing_permit_provider.dart';
import 'sign_permit_provider.dart';
import 'excavation_permit_provider.dart';
import 'certificate_of_occupancy_provider.dart';

/// Collects every wizard's draft in one place.
///
/// Provider looks things up by type, so the sixteen have to be named
/// somewhere; [DraftSource] removed the coupling but not the enumeration.
/// Keeping the list here rather than scattering it means there is exactly one
/// place to add a permit — and `draft_registry_test` fails if a provider
/// implementing [DraftSource] is ever left out of it, so the list cannot go
/// stale quietly.
class DraftRegistry {
  const DraftRegistry._();

  /// Every registered wizard provider, in catalog order.
  static List<DraftSource> sources(BuildContext context) => [
    context.read<BuildingPermitProvider>(),
    context.read<RenovationPermitProvider>(),
    context.read<AdditionExtensionPermitProvider>(),
    context.read<DemolitionPermitProvider>(),
    context.read<ArchitecturalPermitProvider>(),
    context.read<CivilStructuralPermitProvider>(),
    context.read<ElectricalPermitProvider>(),
    context.read<MechanicalPermitProvider>(),
    context.read<SanitaryPlumbingPermitProvider>(),
    context.read<PlumbingPermitProvider>(),
    context.read<ElectronicsPermitProvider>(),
    context.read<InteriorDesignPermitProvider>(),
    context.read<FencingPermitProvider>(),
    context.read<SignPermitProvider>(),
    context.read<ExcavationPermitProvider>(),
    context.read<CertificateOfOccupancyProvider>(),
  ];

  /// The drafts that currently exist. Wizards with nothing resumable return
  /// null and are dropped.
  static List<DraftSummary> summaries(BuildContext context) => [
    for (final source in sources(context)) ?source.draftSummary,
  ];
}
