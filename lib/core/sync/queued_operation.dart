import 'dart:convert';

/// Work the applicant finished that has not reached the LGU yet.
///
/// A permit application is fifteen or more screens and a stack of photographed
/// documents. Losing one to a dropped connection is not a minor inconvenience —
/// it sends the applicant back to the counter, which is the entire thing this
/// system exists to avoid. Mobile connectivity here cannot be assumed.
enum QueuedOperationKind {
  /// Uploads the bytes of one attachment. Must complete before any submission
  /// that references it.
  documentUpload,

  /// Files an application.
  applicationSubmission,

  /// Responds to a Letter of Instruction.
  instructionResponse,

  /// Submits proof of payment.
  paymentProof,
}

/// Where an item is, and — the part that matters most — what the applicant is
/// told about it.
enum QueuedOperationState {
  /// Waiting for a connection. **Shown as "Queued", never as "Submitted".**
  pending,

  /// Being sent right now.
  inFlight,

  /// Accepted by the LGU. The item leaves the queue.
  completed,

  /// Refused for a reason retrying will not change — a validation error, a
  /// permission, a contract mismatch. Kept, with an explanation and a route to
  /// fix it, because discarding an applicant's work silently is worse than
  /// any error message.
  failedPermanently,
}

class QueuedOperation {
  const QueuedOperation({
    required this.id,
    required this.kind,
    required this.idempotencyKey,
    required this.enqueuedAt,
    required this.payload,
    this.applicationId,
    this.dependsOn = const [],
    this.state = QueuedOperationState.pending,
    this.attempts = 0,
    this.nextAttemptAt,
    this.failureMessage,
  });

  final String id;
  final QueuedOperationKind kind;

  /// Created ONCE, at enqueue, and reused on every retry.
  ///
  /// This is what makes criterion 2 hold: a submission interrupted after the
  /// server committed but before the response arrived is replayed with the same
  /// key, and the server returns the original result rather than filing a
  /// second application. Regenerating it per attempt would turn one bad
  /// connection into two permits.
  final String idempotencyKey;

  final DateTime enqueuedAt;
  final Map<String, dynamic> payload;

  /// Which application this belongs to, so items for one are replayed in order
  /// while items for another are not held up behind them.
  final String? applicationId;

  /// Ids of operations that must complete first. A submission referencing three
  /// photographs cannot be sent before those photographs exist server-side.
  final List<String> dependsOn;

  final QueuedOperationState state;
  final int attempts;
  final DateTime? nextAttemptAt;

  /// Plain language, for the applicant. Never a status code.
  final String? failureMessage;

  QueuedOperation copyWith({
    QueuedOperationState? state,
    int? attempts,
    DateTime? nextAttemptAt,
    String? failureMessage,
    bool clearNextAttempt = false,
  }) =>
      QueuedOperation(
        id: id,
        kind: kind,
        idempotencyKey: idempotencyKey,
        enqueuedAt: enqueuedAt,
        payload: payload,
        applicationId: applicationId,
        dependsOn: dependsOn,
        state: state ?? this.state,
        attempts: attempts ?? this.attempts,
        nextAttemptAt: clearNextAttempt ? null : (nextAttemptAt ?? this.nextAttemptAt),
        failureMessage: failureMessage ?? this.failureMessage,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'idempotencyKey': idempotencyKey,
        'enqueuedAt': enqueuedAt.toIso8601String(),
        'payload': payload,
        'applicationId': applicationId,
        'dependsOn': dependsOn,
        'state': state.name,
        'attempts': attempts,
        'nextAttemptAt': nextAttemptAt?.toIso8601String(),
        'failureMessage': failureMessage,
      };

  static QueuedOperation fromJson(Map<String, dynamic> json) => QueuedOperation(
        id: json['id'] as String,
        kind: QueuedOperationKind.values.byName(json['kind'] as String),
        idempotencyKey: json['idempotencyKey'] as String,
        enqueuedAt: DateTime.parse(json['enqueuedAt'] as String),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        applicationId: json['applicationId'] as String?,
        dependsOn: List<String>.from((json['dependsOn'] as List?) ?? const []),
        state: QueuedOperationState.values.byName(json['state'] as String),
        attempts: json['attempts'] as int? ?? 0,
        nextAttemptAt: json['nextAttemptAt'] == null
            ? null
            : DateTime.parse(json['nextAttemptAt'] as String),
        failureMessage: json['failureMessage'] as String?,
      );

  static String encode(List<QueuedOperation> operations) =>
      jsonEncode(operations.map((operation) => operation.toJson()).toList());

  static List<QueuedOperation> decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final entry in decoded)
        if (entry is Map<String, dynamic>) QueuedOperation.fromJson(entry),
    ];
  }
}

extension QueuedOperationDisplay on QueuedOperation {
  /// What the applicant sees.
  ///
  /// **Never "Submitted".** An applicant who believes a filing reached the LGU
  /// when it is sitting on their phone will not resend it, and will find out at
  /// the counter — possibly after a deadline they thought they had met.
  String get applicantStatus {
    switch (state) {
      case QueuedOperationState.pending:
        return 'Queued';
      case QueuedOperationState.inFlight:
        return 'Sending';
      case QueuedOperationState.completed:
        return 'Submitted';
      case QueuedOperationState.failedPermanently:
        return 'Needs your attention';
    }
  }

  bool get isWaitingToReachTheLgu =>
      state == QueuedOperationState.pending || state == QueuedOperationState.inFlight;
}
