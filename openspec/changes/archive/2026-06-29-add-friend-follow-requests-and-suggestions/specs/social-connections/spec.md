## ADDED Requirements

### Requirement: Follow requests require recipient approval
The system SHALL create a pending follow request when a user attempts to follow another user who does not already follow them, and SHALL NOT create a follow edge until the recipient accepts the request.

#### Scenario: New follow request is pending
- **WHEN** a signed-in user taps Follow on another member who does not already follow them
- **THEN** the system creates one pending follow request from the viewer to that member
- **AND** the viewer does not become a follower until the request is accepted
- **AND** the viewer-facing profile action shows a requested state

#### Scenario: Duplicate follow request is not created
- **WHEN** a signed-in user taps Follow again while an outgoing request to the same member is pending
- **THEN** the system keeps a single pending request
- **AND** no duplicate request rows or alerts are created

#### Scenario: User cannot follow self
- **WHEN** a signed-in user attempts to follow their own profile
- **THEN** the system rejects or ignores the action
- **AND** no follow request or follow edge is created

### Requirement: Recipients can accept or decline follow requests
The system SHALL show incoming pending follow requests in Alerts with Accept and Decline actions, and SHALL apply the selected response to the request.

#### Scenario: Recipient accepts request
- **WHEN** the request recipient accepts a pending follow request
- **THEN** the system marks the request accepted with a response timestamp
- **AND** creates a follow edge from the requester to the recipient
- **AND** the requester sees that they are following the recipient

#### Scenario: Recipient declines request
- **WHEN** the request recipient declines a pending follow request
- **THEN** the system marks the request declined with a response timestamp
- **AND** no follow edge is created between the requester and recipient
- **AND** the pending request is no longer shown as actionable to the recipient

### Requirement: Follow back creates mutual friend status
The system SHALL expose a Follow Back action when another member follows the viewer and the viewer does not follow them, and SHALL create the reciprocal follow edge when Follow Back is selected.

#### Scenario: Follow back from profile or member row
- **WHEN** a viewer sees a member who follows them but whom they do not follow
- **THEN** the system shows a Follow Back action
- **AND** tapping Follow Back creates a follow edge from the viewer to that member
- **AND** the two users become friends because both follow edges exist

#### Scenario: Friends are derived from mutual follows
- **WHEN** user A follows user B and user B follows user A
- **THEN** the system treats A and B as friends
- **AND** friend-only capabilities include that relationship

### Requirement: Users can unfollow and cancel outgoing requests
The system SHALL allow users to cancel pending outgoing follow requests and remove their own follow edges without deleting the other user's reciprocal edge.

#### Scenario: Cancel pending request
- **WHEN** a viewer cancels a pending outgoing follow request
- **THEN** the pending request is removed or marked inactive
- **AND** the target member no longer sees it as an incoming actionable request

#### Scenario: Unfollow one side of a friendship
- **WHEN** a viewer unfollows a friend
- **THEN** the system removes only the viewer's follow edge
- **AND** the other member's follow edge remains unless they also unfollow
- **AND** the relationship is no longer treated as a friendship

### Requirement: Follow alerts expose social unread state
The system SHALL include pending incoming follow requests and unread accepted-follow notices in Alerts and in the social unread count used by alert badges or subtitles.

#### Scenario: Incoming request contributes unread alert
- **WHEN** a member has a pending incoming follow request
- **THEN** Alerts shows the request with requester identity and Accept/Decline actions
- **AND** the alert unread count includes that pending request

#### Scenario: Accepted request notice can be dismissed
- **WHEN** a user's outgoing follow request has been accepted and the accepted notice has not been read or dismissed
- **THEN** Alerts shows an accepted-follow notice to the requester
- **AND** marking alerts read or dismissing the notice prevents that accepted notice from continuing to appear as unread

### Requirement: Social connection transitions respect blocks and ownership
The system SHALL enforce that users can only act on their own follow requests and follow edges, and SHALL prevent blocked relationships from creating requests, follows, or friend status.

#### Scenario: Non-participant cannot respond to request
- **WHEN** a signed-in user who is not the recipient attempts to accept or decline a follow request
- **THEN** the system rejects the action
- **AND** the request status and follow edges remain unchanged

#### Scenario: Blocked user cannot create connection
- **WHEN** either participant has blocked the other
- **THEN** the system prevents new follow requests, follow-back edges, and friend status between them
