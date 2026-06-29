# mobile-playback-servers Specification

## Purpose
TBD - created by archiving change replace-server-one-with-vidsrc. Update Purpose after archive.
## Requirements
### Requirement: Server 1 uses Vidsrc for mobile movie playback
The Android and iOS app SHALL route Server 1 movie playback to a Vidsrc movie embed URL. The URL MUST use the movie TMDB ID when available and MUST fall back to the IMDb ID when the TMDB ID is unavailable.

#### Scenario: Movie playback uses TMDB ID
- **WHEN** a user selects Server 1 for a movie with a valid TMDB ID
- **THEN** the app opens a Vidsrc movie embed URL containing that TMDB ID

#### Scenario: Movie playback falls back to IMDb ID
- **WHEN** a user selects Server 1 for a movie without a valid TMDB ID but with a valid IMDb ID
- **THEN** the app opens a Vidsrc movie embed URL containing that IMDb ID

#### Scenario: Movie playback has no provider ID
- **WHEN** a user selects Server 1 for a movie without a valid TMDB ID or IMDb ID
- **THEN** the app does not open a player and informs the user that a playback ID is unavailable

### Requirement: Server 1 uses Vidsrc for mobile TV episode playback
The Android and iOS app SHALL route Server 1 TV and series playback to a Vidsrc TV embed URL. The URL MUST include a season and episode number and MUST use the TV TMDB ID when available, falling back to the IMDb ID when the TMDB ID is unavailable.

#### Scenario: TV playback asks for episode selection
- **WHEN** a user selects Server 1 for TV or series content
- **THEN** the app prompts for season and episode before opening playback

#### Scenario: TV playback uses selected episode
- **WHEN** a user confirms season 2 episode 3 for TV or series content with a valid TMDB ID
- **THEN** the app opens a Vidsrc TV embed URL containing the TMDB ID, season 2, and episode 3

#### Scenario: TV playback falls back to IMDb ID
- **WHEN** a user confirms an episode for TV or series content without a valid TMDB ID but with a valid IMDb ID
- **THEN** the app opens a Vidsrc TV embed URL containing the IMDb ID and selected season and episode

### Requirement: Server 1 opens through embedded web playback
The Android and iOS app SHALL open Server 1 Vidsrc URLs through the embedded web player. Server 1 MUST NOT use the direct HLS video player or direct stream availability checker for Vidsrc playback.

#### Scenario: Server 1 movie opens web player
- **WHEN** a user selects Server 1 for a movie with a playable provider ID
- **THEN** the app opens `FullscreenLandscapeWebPlayer` with the Vidsrc URL

#### Scenario: Server 1 does not preflight Vidsrc as HLS
- **WHEN** a user selects Server 1 for any Vidsrc-backed title
- **THEN** the app does not call the direct stream availability checker before opening the embed URL

### Requirement: Other playback servers remain unchanged
Replacing Server 1 SHALL NOT change Server 2 or Server 3 routing behavior.

#### Scenario: Server 2 remains PlayIMDB based
- **WHEN** a user selects Server 2
- **THEN** the app uses the existing PlayIMDB or StreamIMDB playback flow with existing fallback URLs

#### Scenario: Server 3 remains Cinesrc based
- **WHEN** a user selects Server 3
- **THEN** the app uses the existing Cinesrc embed playback flow

