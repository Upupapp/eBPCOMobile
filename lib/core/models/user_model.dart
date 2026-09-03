import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Verification state shown on the Profile screen's account status chip.
/// Mock/display-only — there is no real verification workflow.
enum AccountStatus { verified, pending, suspended }

extension AccountStatusX on AccountStatus {
  String get label {
    switch (this) {
      case AccountStatus.verified:
        return 'Verified';
      case AccountStatus.pending:
        return 'Pending Verification';
      case AccountStatus.suspended:
        return 'Suspended';
    }
  }

  Color get color {
    switch (this) {
      case AccountStatus.verified:
        return AppColors.statusApproved;
      case AccountStatus.pending:
        return AppColors.statusPending;
      case AccountStatus.suspended:
        return AppColors.statusRejected;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AccountStatus.verified:
        return AppColors.statusApprovedBg;
      case AccountStatus.pending:
        return AppColors.statusPendingBg;
      case AccountStatus.suspended:
        return AppColors.statusRejectedBg;
    }
  }
}

/// Sentinel used by [UserModel.copyWith] so `photoPath` can be explicitly
/// cleared to null (e.g. "Remove Photo") without it being indistinguishable
/// from "leave unchanged".
const _unset = Object();

/// Represents the mock authenticated user of the prototype.
class UserModel {
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String mobileNumber;

  /// Non-null once the user has set a (mock) profile photo via the picker
  /// bottom sheet. No real image is ever stored — this only flags that a
  /// placeholder "photo set" avatar should render instead of initials.
  final String? photoPath;

  /// The citizen's own postal address, as the office would post a notice to.
  ///
  /// **Nullable, and null is not blank.** Null means NOT RECORDED — nobody has
  /// ever been asked for these, so every account predating `PATCH /me` has
  /// them unset. Rendering that as an empty field would tell a citizen they
  /// had left something blank when they were never asked.
  ///
  /// `street`, not `address`: the server already calls this field `street` on
  /// businesses, and a second spelling of one idea inside one service is the
  /// defect D-10 spent a migration undoing. `postalCode` is this app's name,
  /// kept because the server had none to match.
  final String? street;
  final String? province;
  final String? city;
  final String? barangay;
  final String? postalCode;

  /// Free-text account classification shown on the profile info card.
  final String accountType;
  final AccountStatus accountStatus;
  final DateTime? registeredSince;

  const UserModel({
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    required this.email,
    this.mobileNumber = '',
    this.photoPath,
    this.street,
    this.province,
    this.city,
    this.barangay,
    this.postalCode,
    this.accountType = 'Individual Applicant',
    this.accountStatus = AccountStatus.verified,
    this.registeredSince,
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

  /// The address parts as one line, skipping what is not recorded.
  ///
  /// Empty when the office holds none of it — which is a different statement
  /// from an address that happens to be short, and the screens say so rather
  /// than rendering a blank.
  String get fullAddress => [
    street,
    barangay,
    city,
    province,
    postalCode,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');

  /// True when the office has never been given any of this.
  bool get hasNoRecordedAddress => fullAddress.isEmpty;

  UserModel copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? mobileNumber,
    Object? photoPath = _unset,
    // Sentinels for the same reason `photoPath` has one: a citizen must be
    // able to REMOVE a middle name they typed by mistake or never had, and
    // `null` meaning "leave alone" would make that impossible. A right to
    // correct that cannot remove is half a right.
    Object? street = _unset,
    Object? province = _unset,
    Object? city = _unset,
    Object? barangay = _unset,
    Object? postalCode = _unset,
    String? accountType,
    AccountStatus? accountStatus,
    DateTime? registeredSince,
  }) {
    return UserModel(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      photoPath: identical(photoPath, _unset)
          ? this.photoPath
          : photoPath as String?,
      street: identical(street, _unset) ? this.street : street as String?,
      province: identical(province, _unset)
          ? this.province
          : province as String?,
      city: identical(city, _unset) ? this.city : city as String?,
      barangay: identical(barangay, _unset)
          ? this.barangay
          : barangay as String?,
      postalCode: identical(postalCode, _unset)
          ? this.postalCode
          : postalCode as String?,
      accountType: accountType ?? this.accountType,
      accountStatus: accountStatus ?? this.accountStatus,
      registeredSince: registeredSince ?? this.registeredSince,
    );
  }
}
