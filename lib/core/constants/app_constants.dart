/// Shared layout and behavior constants for the E-BPCO User App.
class AppConstants {
  AppConstants._();

  static const double screenPaddingHorizontal = 20;
  static const double screenPaddingVertical = 16;
  static const double maxFormWidth = 480;

  // Fintech-premium radius scale: soft on small controls, large on cards.
  static const double borderRadiusXs = 4;
  static const double borderRadiusSmall = 12;
  static const double borderRadiusMedium = 14;
  static const double borderRadiusLarge = 16;
  static const double borderRadiusXl = 24;
  static const double borderRadiusPill = 999;

  static const double minTouchTarget = 48;

  static const Duration mockNetworkDelay = Duration(milliseconds: 900);

  /// How long the splash takes to assemble its mark.
  ///
  /// Replaces `splashMinimumDuration`, and the rename is the point. That was a
  /// floor on how long startup took — `Future.wait` held the boot until it
  /// elapsed. This is the length of an animation that **nothing waits for**:
  /// the router redirects the moment the session resolves, whether the reveal
  /// has finished or not. See `SplashScreen`, rule 1, and Servana's
  /// `SPLASH_MOTION_SPEC.md` §3.
  static const Duration splashRevealDuration = Duration(milliseconds: 1600);

  // SharedPreferences keys.
  static const String prefOnboardingCompleted = 'onboardingCompleted';
  static const String prefIsLoggedIn = 'isLoggedIn';
  static const String prefRememberMe = 'rememberMe';
  static const String prefRegisteredEmail = 'registeredEmail';

  /// Password verifier and its salt. The password itself is never stored —
  /// see CredentialVerifier.
  /// Bearer token for the API, once a real auth backend issues one.
  ///
  /// SharedPreferences is unencrypted, so this is a placeholder location, not
  /// the final one — a session token belongs in the platform keychain or
  /// keystore. See M-01 and M-22 in docs/MANUAL-TASKS.md.
  static const String prefSessionToken = 'sessionToken';

  /// When the applicant consented to this app processing their personal
  /// documents, ISO-8601. Absent until they do.
  static const String prefPrivacyConsentAt = 'privacyConsentAt';

  static const String prefRegisteredVerifier = 'registeredPasswordVerifier';
  static const String prefRegisteredSalt = 'registeredPasswordSalt';

  /// Legacy key holding a plain-text password. Retained only so existing
  /// installs can have it deleted on next launch; never written again.
  static const String legacyPrefRegisteredPassword = 'registeredPassword';
  static const String prefRegisteredFirstName = 'registeredFirstName';
  static const String prefRegisteredLastName = 'registeredLastName';
  static const String prefRegisteredMobile = 'registeredMobile';
  // The rest of the profile. Only the three above were persisted until
  // 2026-09-03: a citizen who moved house typed a new address, was told
  // "Profile updated successfully", and found the old one back after the next
  // app restart.
  static const String prefRegisteredMiddleName = 'registeredMiddleName';
  static const String prefRegisteredStreet = 'registeredStreet';
  static const String prefRegisteredProvince = 'registeredProvince';
  static const String prefRegisteredCity = 'registeredCity';
  static const String prefRegisteredBarangay = 'registeredBarangay';
  static const String prefRegisteredPostalCode = 'registeredPostalCode';
  static const String prefCurrentUserEmail = 'currentUserEmail';
  static const String prefRememberedEmail = 'rememberedEmail';
  static const String prefProfilePhotoPath = 'profilePhotoPath';
  static const String prefFileAccessPrimerShown = 'fileAccessPrimerShown';
}
