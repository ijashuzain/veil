# Poster Rating Deduplication Design

**Date:** 2026-08-09
**Status:** Approved

## Goal

Show each shared movie/series poster-card rating once by removing rating overlay from artwork and retaining lower metadata rating.

## Changes

- Remove top-left `_PosterRatingChip` from shared `PosterCard` artwork.
- Remove unused private `_PosterRatingChip` widget.
- Keep lower star icon, numeric rating, separator, and year under title.
- Apply globally to every `PosterCard` consumer: Home, providers, See All, curated collections, and recommendations.

## Preserved Behavior

- Poster dimensions, radius, shadow, title, and taps.
- `showMeta: true` lower title/metadata section.
- `showMeta: false` artwork-only cards.
- Ratings elsewhere, including Detail and reviews.

## Verification

- Assert one numeric rating and one rating star per metadata-enabled `PosterCard`.
- Assert no rating text/icon is overlaid within `PosterArt` bounds.
- Assert metadata-disabled cards remain artwork-only.
- Run focused poster/provider/Home tests and analyzer.
