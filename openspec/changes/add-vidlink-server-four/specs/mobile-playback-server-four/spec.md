## ADDED Requirements

### Requirement: Server 4 uses VidLink for mobile movie playback
The Android and iOS app SHALL route Server 4 movie playback to a VidLink movie URL using the movie TMDB ID. The app MUST NOT require an IMDb ID for Server 4 movie playback.

#### Scenario: Movie playback uses TMDB ID
- **WHEN** a user selects Server 4 for a movie with a valid TMDB ID
- **THEN** the app opens `https://vidlink.pro/movie/{tmdbId}?player=jw&primaryColor=FFFFFF&secondaryColor=253034&iconColor=FFFFFF` for that movie

#### Scenario: Movie playback has no TMDB ID
- **WHEN** a user selects Server 4 for a movie without a valid TMDB ID
- **THEN** the app does not open a player and informs the user that a TMDB ID is unavailable

### Requirement: Server 4 uses VidLink for mobile TV episode playback
The Android and iOS app SHALL route Server 4 TV and series playback to a VidLink TV URL using the TV TMDB ID, selected season, and selected episode.

#### Scenario: TV playback asks for episode selection
- **WHEN** a user selects Server 4 for TV or series content with a valid TMDB ID
- **THEN** the app prompts for season and episode before opening playback

#### Scenario: TV playback uses selected episode
- **WHEN** a user confirms season 2 episode 3 for TV or series content with a valid TMDB ID
- **THEN** the app opens `https://vidlink.pro/tv/{tmdbId}/2/3?player=jw&primaryColor=FFFFFF&secondaryColor=253034&iconColor=FFFFFF`

#### Scenario: TV playback has invalid selected values
- **WHEN** Server 4 TV playback is requested with a season or episode less than 1
- **THEN** the VidLink URL uses season 1 or episode 1 for those invalid values

#### Scenario: TV playback has no TMDB ID
- **WHEN** a user selects Server 4 for TV or series content without a valid TMDB ID
- **THEN** the app does not open a player and informs the user that a TMDB ID is unavailable

### Requirement: Server 4 opens through embedded web playback
The Android and iOS app SHALL open Server 4 VidLink URLs through the embedded web player. Server 4 MUST NOT use the direct HLS video player or the direct stream availability checker.

#### Scenario: Server 4 movie opens web player
- **WHEN** a user selects Server 4 for a movie with a valid TMDB ID
- **THEN** the app opens `FullscreenLandscapeWebPlayer` with the VidLink URL

#### Scenario: Server 4 does not preflight VidLink as HLS
- **WHEN** a user selects Server 4 for any VidLink-backed title
- **THEN** the app does not call the direct stream availability checker before opening the VidLink URL

### Requirement: Other playback servers remain unchanged
Adding Server 4 SHALL NOT change Server 1, Server 2, or Server 3 routing behavior.

#### Scenario: Existing servers remain available
- **WHEN** the playback server sheet is shown for a playable title
- **THEN** Server 1, Server 2, Server 3, and Server 4 are all available as separate choices

#### Scenario: Existing server routing is preserved
- **WHEN** a user selects Server 1, Server 2, or Server 3
- **THEN** the app uses the same provider flow that server used before Server 4 was added

### Requirement: VidLink anime playback is out of scope
The app SHALL NOT expose VidLink anime playback unless the content has a supported MyAnimeList ID source.

#### Scenario: Anime URL is not generated from TMDB-only content
- **WHEN** the app builds Server 4 playback URLs from current TMDB-backed movie or TV content
- **THEN** the app generates only VidLink movie or TV URLs and does not generate VidLink anime URLs
