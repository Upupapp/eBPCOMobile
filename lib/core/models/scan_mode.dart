/// The output style applied to a scanned document page. Kept as a plain
/// enum (rather than a free-form string) so the scanner UI, the eventual
/// image-processing service, and storage metadata all agree on the same
/// fixed set of modes.
enum ScanMode { defaultMode, blackAndWhite, enhance }

extension ScanModeX on ScanMode {
  String get label {
    switch (this) {
      case ScanMode.defaultMode:
        return 'Default';
      case ScanMode.blackAndWhite:
        return 'Black and White';
      case ScanMode.enhance:
        return 'Enhance';
    }
  }
}
