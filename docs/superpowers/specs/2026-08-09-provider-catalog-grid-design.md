# Provider Catalog And Grid Design

**Date:** 2026-08-09
**Status:** Approved

## Goal

Make provider discovery denser and visually consistent with Veil, then use one responsive poster-grid language for provider catalogs and Home genre results.

## Provider Home Rail

- Provider images are 58x58 logical pixels inside 64-pixel-wide cells.
- Images fill their bounds with `BoxFit.cover` and 12-pixel corner radius.
- Remove white background, image padding, and white fallback styling.
- Keep subtle `VeilColors.hairlineStrong` border over the clipped image.
- Provider name remains one centered line below image.
- Loading skeleton dimensions match loaded image dimensions.
- Existing rail-only loaded/loading/error behavior remains.

## Tester Account

- Normalize authenticated email with trim and lowercase.
- When email is `tester@vexellab.com`, provider Home rail renders nothing.
- Return before watching `watchProvidersProvider`, preventing provider request for tester account.
- Provider detail route behavior remains unchanged if opened directly.

## Provider Catalog Screen

- Convert `ProviderView` to `ConsumerStatefulWidget` with `Movies` and `TV Series` tabs.
- Use transparent Veil app bar with no title.
- Back action uses compact circular panel/glass treatment matching Detail/Home controls.
- Page background uses Veil graphite gradient rather than a plain generic Scaffold body.
- Provider logo and name remain in body header, using filled rounded image treatment without white card.
- Tabs use compact neutral pill styling: white selected surface with black selected text, raised graphite unselected surface.
- Tabs remain pinned in a fully transparent section with no separate blur, fill, or divider.
- Watch only selected catalog provider: `providerMoviesProvider(id)` for Movies or `providerTvProvider(id)` for TV Series.
- Switching tabs shows the selected tab loading/data/empty/error state.
- Retry invalidates only selected provider.
- Keep exact JustWatch/TMDB attribution below selected grid.

## Poster Grids

- Phone widths show exactly three columns.
- Tablet/desktop use existing `VeilLayout.posterGridColumns`, expanding to five, six, or seven columns where available.
- Provider catalog selected tab uses vertical poster grid.
- Home selected genres use the same responsive poster grid instead of wide detail rows.
- Use existing `PosterCard` metadata, Detail navigation, page gutters, and spacing.
- Loading skeletons use the same column count and approximate card aspect ratio.
- Keep Home selected-genre See all, empty/error state, automatic pagination, and Load more footer.

## Testing

- Provider cards use 58x58 clipped images, no white background, no padding, and cover fit.
- Provider skeletons match 58x58 dimensions.
- Tester account shows no provider rail and does not subscribe to provider request.
- Other accounts still show provider rail.
- Provider app bar has no `Streaming catalog` title and retains back action.
- Movies/TV tabs render one vertical grid at a time and switch providers correctly.
- Phone provider and genre grids have three columns; desktop uses expanded count.
- Provider partial failures remain isolated to selected tab.
- Home genre pagination and navigation remain functional.
- Run focused widget tests, full Flutter tests, and analyzer.

## Non-Goals

- No provider API/repository changes.
- No provider region change.
- No Home All-feed rail changes.
- No provider route or attribution change.
- No Cinejoy/playback changes.
