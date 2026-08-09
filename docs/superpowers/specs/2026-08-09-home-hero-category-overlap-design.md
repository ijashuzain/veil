# Home Hero Category Overlap Design

**Date:** 2026-08-09
**Status:** Approved

## Goal

Overlap Home category tabs 32 logical pixels into cinematic hero, move following Home sections upward, and simplify hero secondary action to one rounded plus button.

## Category Layout

- Replace category `SliverPersistentHeader` with an in-flow hero/category stack.
- Hero keeps its current visual height.
- Category rail starts 32 pixels before hero bottom.
- Stack layout height is `heroHeight + categoryHeight - 32`, so provider and later sections move upward instead of retaining blank sliver space.
- Category height is 52 pixels.
- Initial category rail has transparent surroundings so hero bottom gradient remains visible behind pills.

## Sticky Behavior

- Track Home vertical scroll through existing `ScrollNotification` handler.
- Pin threshold is category top minus current status-bar inset.
- Before threshold, render only in-flow category rail.
- At/after threshold, replace in-flow rail with an equal-size noninteractive spacer and render one overlay category bar at screen top.
- Pinned overlay includes status-bar inset, graphite background, and bottom border.
- Only one interactive category rail is visible/mounted at a time.
- Genre selection and selected styling remain unchanged.

## Hero Action

- Remove info action, divider, and `onInfo` callback.
- Set both View and plus actions to exactly 44 logical pixels high.
- Keep View as a compact white rounded pill.
- Keep one 44x44 circular graphite plus button.
- Keep key `home-hero-add` and tooltip `Add to Veil`.
- Plus continues opening existing rate/log/review/suggestion social sheet.
- View remains the only Detail action in hero.

## Preserved Behavior

- Current reduced hero height.
- Full-bleed backdrop and all gradients.
- Search left and Alerts right.
- Rotation, metadata, description, View, social quick-add, provider rail, and all later Home content.
- Selected-genre pagination through same scroll notification.

## Verification

- Assert category top equals hero bottom minus 32 at initial position.
- Assert first following section moves upward with overlap stack geometry.
- Scroll to threshold and assert category remains visible at status-bar inset.
- Assert only one `home-category-tabs` exists before and after pinning.
- Assert `home-hero-info` is absent and rounded `home-hero-add` remains functional.
- Assert View and plus render at equal 44-pixel heights.
- Run focused Home hero/category tests, full widget tests, analyzer, and diff check.
