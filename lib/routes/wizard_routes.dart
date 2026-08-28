import '../core/contract/admin_vocabulary.dart';

/// Which wizard files each permit type.
///
/// Lifted out of the Applications catalog screen, where it was a private field
/// on a private class, because a second caller appeared: a renewal starts from
/// an issued permit rather than from the catalog, and has to reach the same
/// wizard the catalog would have opened. Two hard-coded copies of a
/// nineteen-row table is the shape this codebase has already grown four times.
///
/// Total over [CanonicalPermitType]: every type the admin recognises has a
/// wizard, and an architecture test proves both that and that every route
/// below is one the router actually declares.
const Map<CanonicalPermitType, String> permitWizardRoutes = {
  CanonicalPermitType.buildingPermitNewConstruction:
      '/applications/new/building-permit',
  CanonicalPermitType.buildingPermitRenovationAlteration:
      '/applications/new/renovation-permit',
  CanonicalPermitType.buildingPermitAdditionExtension:
      '/applications/new/addition-extension-permit',
  CanonicalPermitType.demolitionPermit: '/applications/new/demolition-permit',
  CanonicalPermitType.zoningLocationalClearance:
      '/applications/new/zoning-clearance',
  CanonicalPermitType.architecturalPermit:
      '/applications/new/architectural-permit',
  CanonicalPermitType.civilStructuralPermit:
      '/applications/new/civil-structural-permit',
  CanonicalPermitType.electricalPermit: '/applications/new/electrical-permit',
  CanonicalPermitType.mechanicalPermit: '/applications/new/mechanical-permit',
  CanonicalPermitType.sanitaryPermit:
      '/applications/new/sanitary-plumbing-permit',
  CanonicalPermitType.plumbingPermit: '/applications/new/plumbing-permit',
  CanonicalPermitType.electronicsPermit: '/applications/new/electronics-permit',
  CanonicalPermitType.interiorDesignPermit:
      '/applications/new/interior-design-permit',
  CanonicalPermitType.fencingPermit: '/applications/new/fencing-permit',
  CanonicalPermitType.signPermit: '/applications/new/sign-permit',
  CanonicalPermitType.excavationPermit: '/applications/new/excavation-permit',
  CanonicalPermitType.fsecForBuildingPermitBfp:
      '/applications/new/fsec-clearance',
  CanonicalPermitType.certificateOfOccupancy:
      '/applications/new/certificate-of-occupancy',
  CanonicalPermitType.fsicForOccupancyPermitBfp:
      '/applications/new/fsic-clearance',
};

/// The wizard for [label], or null where the label is not one the admin
/// recognises.
///
/// Null rather than a throw: the legacy Business Permit flow predates this
/// catalog and is filed under a label that is deliberately absent from it, and
/// a caller holding an old application should get "no renewal path" rather
/// than a crash.
String? wizardRouteForLabel(String label) {
  try {
    return permitWizardRoutes[canonicalPermitTypeFromWire(label)];
  } on UnknownWireValue {
    return null;
  }
}
