# Provider Collapsing Identity Design

**Date:** 2026-08-09
**Status:** Approved

## Goal

Transform provider logo and name into a compact app-bar identity as provider catalog scrolls upward, while preserving sticky media tabs and pagination.

## Behavior

- Keep existing fixed transparent Scaffold app bar and glass back button.
- Keep large provider header in catalog scroll content.
- Add a `ScrollController` to provider `CustomScrollView`.
- During first 88 logical pixels of vertical scroll, reveal compact app-bar identity with fade, upward slide, and subtle scale.
- At offset zero compact identity is fully transparent and excluded from semantics.
- At offset 88 or greater compact identity is fully visible.
- Transition follows scroll position directly; it does not start a separate timer animation.

## Collapsed Identity

- Show 38x38 provider logo with rounded corners and subtle border.
- Show provider name on one line with ellipsis.
- Use current provider-name fallback and logo fallback.
- Position identity after back-button area with no app-bar title copy.
- Identity is informational and not tappable.

## Preserved Behavior

- Titleless appearance at top of page.
- Large scrolling provider logo/name header.
- Movies/TV Series tabs pinned below fixed app bar.
- Selected-only catalog subscription, infinite pagination, retries, poster navigation, and responsive grid.

## Verification

- Assert compact identity opacity is zero at initial offset.
- Scroll beyond 88 pixels and assert opacity is one.
- Assert compact logo is 38x38 and long name uses one-line ellipsis.
- Assert large provider header scrolls upward.
- Assert media tabs remain pinned and catalog pagination still passes.
- Run focused provider tests, full widget tests, analyzer, and diff check.
