class ReviewComment {
  const ReviewComment({
    required this.id,
    required this.reviewUserId,
    required this.reviewId,
    required this.userId,
    required this.body,
    this.parentCommentId,
    this.isSpoiler = false,
    this.authorDisplayName = '',
    required this.createdAt,
  });

  factory ReviewComment.create({
    required String reviewUserId,
    required String reviewId,
    required String userId,
    required String body,
    String? parentCommentId,
    bool isSpoiler = false,
    String authorDisplayName = '',
  }) {
    return ReviewComment(
      id: 'comment_${DateTime.now().microsecondsSinceEpoch}',
      reviewUserId: reviewUserId,
      reviewId: reviewId,
      userId: userId,
      body: body.trim(),
      parentCommentId: parentCommentId,
      isSpoiler: isSpoiler,
      authorDisplayName: authorDisplayName,
      createdAt: DateTime.now(),
    );
  }

  factory ReviewComment.fromJson(Map<String, dynamic> json) {
    return ReviewComment(
      id: json['id'] as String? ?? '',
      reviewUserId: json['review_user_id'] as String? ?? '',
      reviewId: json['review_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      body: json['body'] as String? ?? '',
      parentCommentId: json['parent_comment_id'] as String?,
      isSpoiler: json['is_spoiler'] == true,
      authorDisplayName: json['author_display_name'] as String? ?? '',
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  factory ReviewComment.fromSupabaseJson(Map<String, dynamic> json) {
    return ReviewComment.fromJson(json);
  }

  final String id;
  final String reviewUserId;
  final String reviewId;
  final String userId;
  final String body;
  final String? parentCommentId;
  final bool isSpoiler;
  final String authorDisplayName;
  final DateTime createdAt;

  bool get isReply => parentCommentId?.isNotEmpty == true;

  ReviewComment copyWith({
    String? id,
    String? reviewUserId,
    String? reviewId,
    String? userId,
    String? body,
    String? parentCommentId,
    bool clearParentCommentId = false,
    bool? isSpoiler,
    String? authorDisplayName,
    DateTime? createdAt,
  }) {
    return ReviewComment(
      id: id ?? this.id,
      reviewUserId: reviewUserId ?? this.reviewUserId,
      reviewId: reviewId ?? this.reviewId,
      userId: userId ?? this.userId,
      body: body ?? this.body,
      parentCommentId: clearParentCommentId
          ? null
          : parentCommentId ?? this.parentCommentId,
      isSpoiler: isSpoiler ?? this.isSpoiler,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'review_user_id': reviewUserId,
      'review_id': reviewId,
      'user_id': userId,
      'body': body,
      'parent_comment_id': parentCommentId,
      'is_spoiler': isSpoiler,
      'author_display_name': authorDisplayName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseInsertJson() {
    return {
      'review_user_id': reviewUserId,
      'review_id': reviewId,
      'user_id': userId,
      'body': body,
      'parent_comment_id': parentCommentId,
      'is_spoiler': isSpoiler,
    };
  }
}

DateTime? _parseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
