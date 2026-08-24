import 'package:flutter/material.dart';

import '../models/business_model.dart';
import '../repositories/business_repository.dart';
import 'notifications_provider.dart';

/// Holds the user's registered businesses, sourced from
/// [BusinessRepository]. Registering a business posts a matching
/// notification via [NotificationsProvider].
class BusinessProvider extends ChangeNotifier {
  BusinessProvider({
    required this._notifications,
    required this._repository,
  }) {
    _load();
  }

  final BusinessRepository _repository;
  final NotificationsProvider _notifications;

  bool _isLoading = true;
  List<BusinessModel> _businesses = const [];
  Object? _loadError;

  bool get isLoading => _isLoading;

  /// Why the last fetch failed, or null if it did not.
  Object? get loadError => _loadError;
  bool get hasLoadError => _loadError != null;
  List<BusinessModel> get businesses => _businesses;

  BusinessModel? byId(String id) {
    for (final business in _businesses) {
      if (business.id == id) return business;
    }
    return null;
  }

  /// Re-fetch, for the retry offered when a load failed.
  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      _businesses = await _repository.fetchAll();
      _loadError = null;
    } catch (error) {
      // Keep whatever was already loaded rather than blanking the list on a
      // failed refresh.
      _loadError = error;
    } finally {
      // In the `finally`, not the `try`: without it a thrown fetch left
      // `_isLoading` true for the rest of the session and the screen spun
      // forever, with the exception escaping unhandled on top.
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BusinessModel> registerBusiness({
    required String name,
    required BusinessCategory category,
    required String street,
    required String barangay,
    required String city,
    required String province,
  }) async {
    final business = await _repository.registerBusiness(
      name: name,
      category: category,
      street: street,
      barangay: barangay,
      city: city,
      province: province,
    );
    _businesses = [..._businesses, business];
    notifyListeners();
    _notifications.addNotification(
      title: 'Business registered successfully',
      message: '$name has been added to your registered businesses.',
      icon: Icons.storefront_outlined,
    );
    return business;
  }
}
