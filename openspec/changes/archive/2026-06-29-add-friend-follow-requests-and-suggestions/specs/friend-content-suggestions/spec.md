## ADDED Requirements

### Requirement: Users can suggest movies and series to friends
The system SHALL allow a user to suggest a movie or series only to friends, where friendship is defined as mutual follow edges.

#### Scenario: Suggestion sheet lists friends
- **WHEN** a signed-in user opens Suggest from a movie or series detail page
- **THEN** the system lists eligible recipients who mutually follow the viewer
- **AND** followers who are not followed back are not listed as suggestion recipients

#### Scenario: Suggestion is sent to selected friends
- **WHEN** a signed-in user selects one or more friends and submits a suggestion
- **THEN** the system creates one movie suggestion for each selected friend
- **AND** each suggestion stores the sender, recipient, content snapshot, and creation timestamp

#### Scenario: No friends empty state
- **WHEN** a signed-in user opens Suggest without any mutual friends
- **THEN** the system shows an empty state explaining that suggestions can be sent to friends
- **AND** no suggestion can be submitted until at least one friend is selected

### Requirement: Suggestion delivery is enforced server-side
The system SHALL enforce suggestion eligibility in the backend so a user cannot create suggestions for non-friends or blocked users by bypassing the client UI.

#### Scenario: Non-friend recipient is rejected
- **WHEN** a sender attempts to create a suggestion for a recipient who is not a mutual friend
- **THEN** the backend rejects or ignores that recipient
- **AND** no suggestion alert is delivered to that recipient

#### Scenario: Blocked recipient is rejected
- **WHEN** either the sender or recipient has blocked the other
- **THEN** the backend rejects or ignores the suggestion
- **AND** no suggestion alert is delivered between those users

### Requirement: Recipients see suggested content in Alerts
The system SHALL show received movie and series suggestions in the Alerts suggestions view with sender identity, content title, content metadata, and unread state.

#### Scenario: Received suggestion appears in suggestions tab
- **WHEN** a friend suggests a movie or series to the recipient
- **THEN** the recipient's Alerts suggestions view shows the suggestion
- **AND** the row identifies who suggested the content
- **AND** the row displays the suggested content title and metadata

#### Scenario: Suggestion opens content detail
- **WHEN** the recipient taps a suggestion alert
- **THEN** the system marks the suggestion read
- **AND** opens the detail page for the suggested movie or series

### Requirement: Suggestion unread state participates in alert counts
The system SHALL count unread movie and series suggestions in the alert unread state and SHALL update that state when suggestions are marked read.

#### Scenario: Unread suggestion contributes to badge
- **WHEN** a recipient has an unread movie or series suggestion
- **THEN** the alert unread state includes that suggestion
- **AND** the Alerts subtitle or badge reflects unread social content

#### Scenario: Mark all read clears suggestion unread state
- **WHEN** a recipient selects Mark read from Alerts
- **THEN** the system marks unread suggestions as read
- **AND** those suggestions no longer contribute to unread counts

### Requirement: Suggestion history remains participant-visible
The system SHALL allow only the sender and recipient of a suggestion to view that suggestion, while preserving recipient read state.

#### Scenario: Sender and recipient can view suggestion row
- **WHEN** the sender or recipient loads suggestion data
- **THEN** the system allows that participant to read the suggestion row

#### Scenario: Non-participant cannot view suggestion row
- **WHEN** a user who is neither sender nor recipient attempts to read a suggestion row
- **THEN** the backend does not expose that suggestion row
