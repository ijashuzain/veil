class UserProfileSummary {
  const UserProfileSummary({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  factory UserProfileSummary.fromJson(Map<String, dynamic> json) {
    return UserProfileSummary(
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  factory UserProfileSummary.fromSupabaseJson(Map<String, dynamic> json) {
    return UserProfileSummary.fromJson(json);
  }

  final String userId;
  final String displayName;
  final String? avatarUrl;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
    };
  }

  UserProfileSummary copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
  }) {
    return UserProfileSummary(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserProfileSummary &&
            runtimeType == other.runtimeType &&
            userId == other.userId &&
            displayName == other.displayName &&
            avatarUrl == other.avatarUrl;
  }

  @override
  int get hashCode => Object.hash(userId, displayName, avatarUrl);
}
