# Search Glass Back Button Design

**Date:** 2026-08-09
**Status:** Approved

## Goal

Make Search leading back button match Veil's provider-page glass navigation treatment.

## Changes

- Keep `SearchView(showBack: true)` header structure and Cancel action.
- Add key `search-back-button`.
- Use 38x38 circular button.
- Use `VeilColors.panel` at `.72` opacity.
- Use translucent white `.20` border.
- Use white 20px `arrow_back_rounded` icon.
- Use zero internal padding and shrink-wrapped tap target.

## Preserved Behavior

- Back action remains `Navigator.maybePop()`.
- Search title, field, scopes, results, and Cancel action remain unchanged.
- `showBack: false` layout remains unchanged.

## Verification

- Assert button circle, size, background, border, and icon.
- Assert tap pops Search route.
- Assert default Search without back button remains unchanged.
- Run focused Search tests and analyzer.
