/// Reusable, user-friendly form validators for the E-BPCO User App.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(
    r'^[\w\.\-\+]+@[\w\-]+\.[\w\-\.]+$',
  );

  // Accepts 09XXXXXXXXX or +639XXXXXXXXX (11 or 12/13 digit PH mobile formats).
  static final RegExp _phMobilePattern = RegExp(r'^(09\d{9}|\+639\d{9})$');

  static final RegExp _postalCodePattern = RegExp(r'^\d{4}$');

  static String? required(String? value, {String fieldLabel = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address.';
    }
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? philippineMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your mobile number.';
    }
    final cleaned = value.trim().replaceAll(' ', '');
    if (!_phMobilePattern.hasMatch(cleaned)) {
      return 'Enter a valid Philippine mobile number.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    final hasMinLength = value.length >= 8;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasNumber = RegExp(r'\d').hasMatch(value);
    if (!hasMinLength || !hasLetter || !hasNumber) {
      return 'Password must contain at least eight characters, one letter, and one number.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != originalPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? postalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your postal code.';
    }
    if (!_postalCodePattern.hasMatch(value.trim())) {
      return 'Enter a valid 4-digit postal code.';
    }
    return null;
  }
}
