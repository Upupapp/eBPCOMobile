import 'package:flutter/foundation.dart';

/// Session UI preferences.
///
/// Notification preferences deliberately do **not** live here. They gate
/// delivery, so they belong with the thing that delivers — NotificationsProvider
/// owns them, and this class keeping a second copy would let the screen and
/// the delivery decision disagree.
class SettingsProvider extends ChangeNotifier {
  String _selectedLanguage = 'English';

  String get selectedLanguage => _selectedLanguage;

  void setLanguage(String language) {
    if (_selectedLanguage == language) return;
    _selectedLanguage = language;
    notifyListeners();
  }
}
