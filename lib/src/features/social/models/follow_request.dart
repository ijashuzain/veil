enum FollowRequestStatus {
  pending,
  accepted,
  declined;

  static FollowRequestStatus fromJson(Object? value) {
    final normalized = value?.toString().toLowerCase();
    return FollowRequestStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => FollowRequestStatus.pending,
    );
  }
}

class FollowRequest {
  const FollowRequest({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    this.requesterDisplayName = '',
    this.recipientDisplayName = '',
    this.status = FollowRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  factory FollowRequest.create({
    required String requesterId,
    required String recipientId,
    String requesterDisplayName = '',
    String recipientDisplayName = '',
  }) {
    final now = DateTime.now();
    return FollowRequest(
      id: '${requesterId}_${recipientId}_${now.microsecondsSinceEpoch}',
      requesterId: requesterId,
      recipientId: recipientId,
      requesterDisplayName: requesterDisplayName,
      recipientDisplayName: recipientDisplayName,
      createdAt: now,
    );
  }

  factory FollowRequest.fromJson(Map<String, dynamic> json) {
    return FollowRequest(
      id: json['id'] as String? ?? '',
      requesterId: json['requester_id'] as String? ?? '',
      recipientId: json['recipient_id'] as String? ?? '',
      requesterDisplayName: json['requester_display_name'] as String? ?? '',
      recipientDisplayName: json['recipient_display_name'] as String? ?? '',
      status: FollowRequestStatus.fromJson(json['status']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      respondedAt: _parseDate(json['responded_at']),
    );
  }

  factory FollowRequest.fromSupabaseJson(Map<String, dynamic> json) {
    return FollowRequest.fromJson(json);
  }

  final String id;
  final String requesterId;
  final String recipientId;
  final String requesterDisplayName;
  final String recipientDisplayName;
  final FollowRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  bool isIncomingFor(String userId) => recipientId == userId;

  bool isAcceptedFor(String userId) =>
      requesterId == userId && status == FollowRequestStatus.accepted;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'recipient_id': recipientId,
      'requester_display_name': requesterDisplayName,
      'recipient_display_name': recipientDisplayName,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseInsertJson() {
    return {
      'requester_id': requesterId,
      'recipient_id': recipientId,
      'requester_display_name': requesterDisplayName,
      'recipient_display_name': recipientDisplayName,
      'status': status.name,
    };
  }

  FollowRequest copyWith({
    String? id,
    String? requesterId,
    String? recipientId,
    String? requesterDisplayName,
    String? recipientDisplayName,
    FollowRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FollowRequest(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      recipientId: recipientId ?? this.recipientId,
      requesterDisplayName: requesterDisplayName ?? this.requesterDisplayName,
      recipientDisplayName: recipientDisplayName ?? this.recipientDisplayName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
