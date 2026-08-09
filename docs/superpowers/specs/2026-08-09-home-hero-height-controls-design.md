# Home Hero Height And Controls Design

**Date:** 2026-08-09
**Status:** Approved

## Goal

Reduce Home cinematic hero height by exactly 25 percent and replace its top-left app mark with Search.

## Changes

- Mobile height factor changes from `.68` to `.51`.
- Mobile height bounds change from `560–680` to `420–510`.
- Tablet height changes from `600` to `450`.
- Desktop height changes from `620` to `465`.
- Remove `home-hero-logo` and its app-icon asset widget from hero.
- Position `home-hero-search` at top left.
- Keep `home-hero-alerts` at top right.

## Preserved Behavior

- Full-bleed backdrop and zero radius.
- Side vignette, top contrast, and bottom blend.
- Title, metadata, overview, View, quick-add, and info actions.
- Seven-second rotation and reduced-motion behavior.
- Category rail placement directly after hero.

## Verification

- Assert 430.44 logical pixels at 390x844 (`844 * .51`).
- Assert 465 logical pixels at desktop width.
- Assert logo key is absent and Search/Alerts remain present.
- Run focused Home hero tests and analyzer.
