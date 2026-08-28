import 'package:flutter/foundation.dart';

import '../contract/admin_vocabulary.dart';
import '../models/contact_verification.dart';
import '../repositories/contact_verification_repository.dart';
import '../sync/offline_queue.dart';
import '../sync/queued_operation.dart';

/// Why the last action did not do what the applicant asked.
///
/// Three outcomes that look alike on screen and are not alike at all: the
/// office refused the code, the office has not switched this on, or the
/// request never left the device. Only the first is the applicant's to fix,
/// and only the last is worth retrying by itself.
enum VerificationOutcome { none, rejected, unavailable, queued }

/// Per-channel contact verification.
///
/// The admin has modelled four statuses and four methods since the first
/// reconciliation. The app registered an account and verified nothing, so the
/// office could not rely on the address it sends every notice to, and the
/// applicant was never told there was anything to do about it.
///
/// **Nothing here is gated on verification.** Whether an unverified applicant
/// may file is a product decision for the LGU, not one to take by accident in
/// a front-end TAB. The state is surfaced; what it costs is left open.
class ContactVerificationProvider extends ChangeNotifier {
  ContactVerificationProvider({
    required ContactVerificationRepository repository,
    OfflineQueue? queue,
    String email = '',
    String mobileNumber = '',
    DateTime Function()? clock,
  }) : // Assigned here rather than as `this._repository` initialising
       // formals: Dart will not let a named parameter carry a private name,
       // and these two fields are private on purpose.
       // ignore: prefer_initializing_formals
       _repository = repository,
       // ignore: prefer_initializing_formals
       _queue = queue,
       _clock = clock ?? DateTime.now,
       _channels = {
         ContactChannel.email: ContactVerification(
           channel: ContactChannel.email,
           value: email,
         ),
         ContactChannel.mobile: ContactVerification(
           channel: ContactChannel.mobile,
           value: mobileNumber,
         ),
       };

  final ContactVerificationRepository _repository;
  final OfflineQueue? _queue;
  final DateTime Function() _clock;
  final Map<ContactChannel, ContactVerification> _channels;

  bool _busy = false;
  VerificationOutcome _outcome = VerificationOutcome.none;
  String? _message;

  ContactVerification of(ContactChannel channel) => _channels[channel]!;
  List<ContactVerification> get channels => _channels.values.toList();

  bool get isBusy => _busy;
  VerificationOutcome get outcome => _outcome;

  /// What to tell the applicant about the last action, or null if there is
  /// nothing to say.
  String? get message => _message;

  /// Channels the applicant could act on. A channel with nothing in it is not
  /// one of them — there is nothing to send to.
  List<ContactVerification> get actionable =>
      channels.where((c) => !c.isMissing && !c.isVerified).toList();

  /// Keeps the channels in step with a profile edit.
  ///
  /// A changed address is an unverified address, whatever the old one was:
  /// carrying a verified status across an edit would let someone confirm one
  /// mailbox and then substitute another.
  void updateContactDetails({String? email, String? mobileNumber}) {
    var changed = false;
    for (final entry in {
      ContactChannel.email: email,
      ContactChannel.mobile: mobileNumber,
    }.entries) {
      final value = entry.value;
      if (value == null) continue;
      final current = _channels[entry.key]!;
      if (current.value == value) continue;
      _channels[entry.key] = ContactVerification(
        channel: entry.key,
        value: value,
      );
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Asks the office for a link or a one-time code.
  Future<void> request(ContactChannel channel) async {
    final current = _channels[channel]!;
    if (current.isMissing || _busy) return;

    _busy = true;
    _outcome = VerificationOutcome.none;
    _message = null;
    notifyListeners();

    try {
      // The previous failure is cleared here rather than left to each
      // repository: a fresh request supersedes the last one's reason whatever
      // is behind it, and a stale "That code has expired" sitting under a
      // freshly-sent code reads as if the new one had already failed.
      _channels[channel] = (await _repository.request(
        current,
      )).copyWith(clearFailure: true);
      _message =
          'We have asked the office to send a '
          '${channel == ContactChannel.email ? 'verification link to ${current.value}' : 'code to ${current.value}'}.';
    } on VerificationNotAvailable {
      _outcome = VerificationOutcome.unavailable;
      _message = _unavailableMessage;
    } catch (error) {
      // The request never left the device. Queued rather than dropped: an
      // applicant who tapped Send on a train believes they have asked.
      await _enqueue(channel, current);
      _outcome = VerificationOutcome.queued;
      _message =
          'You are offline, so this is saved and will be sent when you are '
          'back on a connection.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Submits the code the applicant received.
  Future<void> confirm(ContactChannel channel, String code) async {
    final current = _channels[channel]!;
    if (_busy) return;

    _busy = true;
    _outcome = VerificationOutcome.none;
    _message = null;
    notifyListeners();

    try {
      _channels[channel] = await _repository.confirm(current, code: code);
      _message = '${channel.label} verified.';
    } on VerificationRejected catch (error) {
      // A real failure, and the admin models it as its own status rather than
      // as a return to unverified — an applicant whose code was refused has
      // something to do that someone who never asked does not.
      _channels[channel] = current.copyWith(
        status: ContactVerificationStatus.verificationFailed,
        failureReason: error.reason,
      );
      _outcome = VerificationOutcome.rejected;
      _message = error.reason;
    } on VerificationNotAvailable {
      // Deliberately does not touch the channel's status. The applicant did
      // nothing wrong and marking their channel Failed would say they had.
      _outcome = VerificationOutcome.unavailable;
      _message = _unavailableMessage;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _enqueue(
    ContactChannel channel,
    ContactVerification current,
  ) async {
    final queue = _queue;
    if (queue == null) return;
    final now = _clock();
    try {
      await queue.enqueue(
        QueuedOperation(
          id: 'verify-${channel.name}-${now.microsecondsSinceEpoch}',
          kind: QueuedOperationKind.contactVerificationRequest,
          // One outstanding request per channel. Tapping Send four times on a
          // bad connection is one applicant asking once, not four codes.
          idempotencyKey:
              'contact-verification:${channel.name}:'
              '${current.value}',
          enqueuedAt: now,
          payload: {
            'channel': channel.name,
            'value': current.value,
            'method': channel.applicantMethod.wire,
          },
        ),
      );
      _channels[channel] = current.copyWith(lastRequestedAt: now);
    } catch (_) {
      // A full queue. Nothing is lost that the applicant thinks was saved,
      // because the message below is only set on the success path.
      _outcome = VerificationOutcome.none;
      _message =
          'Could not save this request. Try again when you have a '
          'connection.';
    }
  }

  static const _unavailableMessage =
      'The office has not switched on automatic verification yet, so this '
      'cannot be completed in the app. The Office of the Building Official '
      'can confirm your details at the counter.';
}
