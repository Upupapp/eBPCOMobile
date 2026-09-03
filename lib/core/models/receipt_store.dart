import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'filing_receipt.dart';

/// Where filing receipts live between launches.
///
/// The receipts were held in a map on `ApplicationsProvider` and nowhere else,
/// so what the office had actually received was visible for the few seconds
/// between filing and leaving the confirmation screen. A citizen who wanted to
/// check a week later — which is when they would want to — had nothing.
///
/// Same store as the offline queue and the drafts: on-device, this-device-only,
/// not synchronised to iCloud. A receipt names a citizen's application, its
/// site and the ids of the documents they filed.
abstract class ReceiptStore {
  Future<Map<String, FilingReceipt>> load();
  Future<void> save(Map<String, FilingReceipt> receipts);
}

class SecureReceiptStore implements ReceiptStore {
  SecureReceiptStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
          );

  final FlutterSecureStorage _storage;
  static const _key = 'ebpco.filing.receipts';

  @override
  Future<Map<String, FilingReceipt>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, Object?>;
      return {
        for (final entry in decoded.entries)
          entry.key: FilingReceipt.fromJson(
            entry.value! as Map<String, Object?>,
          ),
      };
    } on Object {
      // A receipt that cannot be read is a receipt the citizen has lost, which
      // is bad — but bricking every launch is worse, and the application
      // itself is still on the server. Dropped rather than retried forever.
      return {};
    }
  }

  @override
  Future<void> save(Map<String, FilingReceipt> receipts) => _storage.write(
    key: _key,
    value: jsonEncode({
      for (final entry in receipts.entries) entry.key: entry.value.toJson(),
    }),
  );
}

class InMemoryReceiptStore implements ReceiptStore {
  Map<String, FilingReceipt> _receipts = {};

  @override
  Future<Map<String, FilingReceipt>> load() async => Map.of(_receipts);

  @override
  Future<void> save(Map<String, FilingReceipt> receipts) async =>
      _receipts = Map.of(receipts);
}
