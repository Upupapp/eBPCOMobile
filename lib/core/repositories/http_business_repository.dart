import '../api/api_client.dart';
import '../api/idempotency_key.dart';
import '../api/api_exception.dart';
import '../models/business_model.dart';
import 'business_repository.dart';

/// Businesses, from the API.
class HttpBusinessRepository implements BusinessRepository {
  HttpBusinessRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<BusinessModel>> fetchAll() async {
    final rows = await _api.getList('/businesses');
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>)
          _parse(row)
        else
          throw const ApiException(
            ApiFailure.malformed,
            'expected business objects',
          ),
    ];
  }

  @override
  Future<BusinessModel> registerBusiness({
    required String name,
    required BusinessCategory category,
    required String street,
    required String barangay,
    required String city,
    required String province,
  }) async {
    final created = await _api.post(
      '/businesses',
      body: {
        'name': name,
        'category': _categoryLabel(category),
        'street': street,
        'barangay': barangay,
        'city': city,
        'province': province,
      },
      // One key per attempt. The contract requires the header and this app
      // sent it on nothing until 30 August 2026. Note the limit honestly: a
      // key made here is stable across the client's own retry of this call,
      // and NOT across an applicant tapping the button twice — the durable
      // version generates it where the operation is created, as the offline
      // queue already does. Recorded in M-47.
      idempotencyKey: newIdempotencyKey(),
    );
    return _parse(created);
  }

  BusinessModel _parse(Map<String, dynamic> json) => BusinessModel(
    id: _string(json, 'id'),
    name: _string(json, 'name'),
    category: _category(_string(json, 'category')),
    street: _string(json, 'street'),
    barangay: _string(json, 'barangay'),
    city: _string(json, 'city'),
    province: _string(json, 'province'),
    registrationNumber: _string(json, 'registrationNumber'),
    dateRegistered: _date(json, 'dateRegistered'),
    status: _status(_string(json, 'status')),
  );

  /// The admin's labels, verbatim, and unknown values throw.
  ///
  /// Softening this to a default would mean a business silently filed under
  /// "Other" because the LGU added a category the app has not shipped yet —
  /// which is wrong quietly, where a loud failure is wrong loudly and gets
  /// fixed.
  static BusinessCategory _category(String raw) {
    switch (raw) {
      case 'Retail':
        return BusinessCategory.retail;
      case 'Food Service':
        return BusinessCategory.foodService;
      case 'Services':
        return BusinessCategory.services;
      case 'Manufacturing':
        return BusinessCategory.manufacturing;
      case 'Wholesale':
        return BusinessCategory.wholesale;
      case 'Other':
        return BusinessCategory.other;
    }
    throw ApiException(
      ApiFailure.malformed,
      'unknown business category "$raw"',
    );
  }

  static String _categoryLabel(BusinessCategory category) {
    switch (category) {
      case BusinessCategory.retail:
        return 'Retail';
      case BusinessCategory.foodService:
        return 'Food Service';
      case BusinessCategory.services:
        return 'Services';
      case BusinessCategory.manufacturing:
        return 'Manufacturing';
      case BusinessCategory.wholesale:
        return 'Wholesale';
      case BusinessCategory.other:
        return 'Other';
    }
  }

  static BusinessStatus _status(String raw) {
    switch (raw) {
      case 'Active':
        return BusinessStatus.active;
      case 'Inactive':
        return BusinessStatus.inactive;
    }
    throw ApiException(ApiFailure.malformed, 'unknown business status "$raw"');
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw ApiException(ApiFailure.malformed, 'missing required string "$key"');
  }

  static DateTime _date(Map<String, dynamic> json, String key) {
    final parsed = DateTime.tryParse('${json[key]}');
    if (parsed == null) {
      throw ApiException(
        ApiFailure.malformed,
        'missing or unparseable date "$key"',
      );
    }
    // Local time: every date an applicant sees is a Philippine office date.
    return parsed.toLocal();
  }
}
