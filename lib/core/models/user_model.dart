/// Represents the mock authenticated user of the prototype.
class UserModel {
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String mobileNumber;

  const UserModel({
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    required this.email,
    this.mobileNumber = '',
  });

  String get fullName {
    final middle = middleName.trim().isNotEmpty ? ' $middleName' : '';
    return '$firstName$middle $lastName'.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final combined = '$first$last'.toUpperCase();
    return combined.isNotEmpty ? combined : 'U';
  }

  UserModel copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? mobileNumber,
  }) {
    return UserModel(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
    );
  }
}
