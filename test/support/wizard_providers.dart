import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:ebpco_user_app/core/providers/addition_extension_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/architectural_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/building_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/certificate_of_occupancy_provider.dart';
import 'package:ebpco_user_app/core/providers/civil_structural_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/demolition_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/electrical_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/electronics_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/excavation_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/fencing_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/interior_design_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/mechanical_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/plumbing_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/renovation_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/sanitary_plumbing_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/sign_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/zoning_permit_provider.dart';

/// Every wizard provider, for tests that mount something reading
/// `DraftRegistry`.
///
/// The registry looks each of the sixteen up by type, so anything that asks it
/// for drafts needs all sixteen present — `MainShell`, for its idle-draft
/// nudge, and `ApplicationListScreen`, for its Drafts segment. Spelling them
/// out in each harness meant sixteen lines of noise per test file and one more
/// place to forget when a seventeenth permit arrives.
List<SingleChildWidget> wizardProviders() => [
  ChangeNotifierProvider<BuildingPermitProvider>(
    create: (_) => BuildingPermitProvider(),
  ),
  ChangeNotifierProvider<RenovationPermitProvider>(
    create: (_) => RenovationPermitProvider(),
  ),
  ChangeNotifierProvider<AdditionExtensionPermitProvider>(
    create: (_) => AdditionExtensionPermitProvider(),
  ),
  ChangeNotifierProvider<DemolitionPermitProvider>(
    create: (_) => DemolitionPermitProvider(),
  ),
  ChangeNotifierProvider<ArchitecturalPermitProvider>(
    create: (_) => ArchitecturalPermitProvider(),
  ),
  ChangeNotifierProvider<CivilStructuralPermitProvider>(
    create: (_) => CivilStructuralPermitProvider(),
  ),
  ChangeNotifierProvider<ElectricalPermitProvider>(
    create: (_) => ElectricalPermitProvider(),
  ),
  ChangeNotifierProvider<MechanicalPermitProvider>(
    create: (_) => MechanicalPermitProvider(),
  ),
  ChangeNotifierProvider<SanitaryPlumbingPermitProvider>(
    create: (_) => SanitaryPlumbingPermitProvider(),
  ),
  ChangeNotifierProvider<PlumbingPermitProvider>(
    create: (_) => PlumbingPermitProvider(),
  ),
  ChangeNotifierProvider<ElectronicsPermitProvider>(
    create: (_) => ElectronicsPermitProvider(),
  ),
  ChangeNotifierProvider<InteriorDesignPermitProvider>(
    create: (_) => InteriorDesignPermitProvider(),
  ),
  ChangeNotifierProvider<FencingPermitProvider>(
    create: (_) => FencingPermitProvider(),
  ),
  ChangeNotifierProvider<SignPermitProvider>(
    create: (_) => SignPermitProvider(),
  ),
  ChangeNotifierProvider<ExcavationPermitProvider>(
    create: (_) => ExcavationPermitProvider(),
  ),
  ChangeNotifierProvider<CertificateOfOccupancyProvider>(
    create: (_) => CertificateOfOccupancyProvider(),
  ),
  ChangeNotifierProvider<ZoningPermitProvider>(
    create: (_) => ZoningPermitProvider(),
  ),
];
