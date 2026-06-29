import 'package:veil/src/features/social/models/follow_request.dart';

enum UserRelationshipStatus {
  self,
  none,
  requested,
  incomingRequest,
  followsMe,
  following,
  friends,
  blocked,
}

class UserRelationship {
  const UserRelationship({
    required this.userId,
    required this.status,
    this.outgoingRequest,
    this.incomingRequest,
  });

  final String userId;
  final UserRelationshipStatus status;
  final FollowRequest? outgoingRequest;
  final FollowRequest? incomingRequest;

  bool get isFollowing =>
      status == UserRelationshipStatus.following ||
      status == UserRelationshipStatus.friends;

  bool get isFriend => status == UserRelationshipStatus.friends;

  bool get canFollow =>
      status == UserRelationshipStatus.none ||
      status == UserRelationshipStatus.followsMe;

  bool get canCancelRequest => status == UserRelationshipStatus.requested;

  bool get canUnfollow => isFollowing;
}
