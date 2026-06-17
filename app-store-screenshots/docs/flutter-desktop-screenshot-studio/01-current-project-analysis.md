# Current Project Analysis

## Executive Summary

The current project is a strong local screenshot-composition editor built with Next.js. It already solves several hard product problems well:

1. It persists work to a git-trackable JSON file.
2. It supports multiple device decks.
3. It supports connected-canvas composition across adjacent screens.
4. It supports per-screen layout variation and image placement.
5. It exports bundle zips for store-ready sizes.

It does not currently include any agent discovery, model orchestration, prompt pipeline, or AI-assisted generation workflow. Those additions are possible, but they require a new application layer rather than a small extension.

## What The Current App Is

The repository in this folder is a local-first screenshot editor for App Store and Google Play marketing images.

Key files:

| Area | Files |
|---|---|
| App shell | `src/app/page.tsx`, `src/components/editor/screenshot-editor.tsx` |
| Canvas rendering | `src/components/editor/slide-canvas.tsx`, `src/components/editor/device-frames.tsx` |
| Editing UI | `src/components/editor/toolbar.tsx`, `sidebar.tsx`, `preview-stage.tsx`, `inspector.tsx`, `slide-thumb.tsx` |
| Persistence | `src/lib/storage.ts`, `src/app/api/project/route.ts` |
| Uploads | `src/components/editor/screenshot-picker.tsx`, `src/app/api/upload/route.ts` |
| Project model | `src/lib/types.ts`, `src/lib/constants.ts`, `src/lib/defaults.ts`, `app-store-screenshots.json` |

## Current End-To-End Workflow

1. The app boots into `ScreenshotEditor`.
2. State hydrates from `localStorage` first, then `app-store-screenshots.json` through `/api/project`.
3. The user edits slides, copy, theme selection, screenshots, positions, and layouts.
4. Uploads go through `/api/upload` and are saved into `public/screenshots/uploaded/`.
5. Autosave writes back to `localStorage` and the root JSON file.
6. Export renders an off-screen deck and builds a zip using `html-to-image` and `JSZip`.

## Current State Of The Veil Project

The saved project state already shows the current product direction clearly:

1. App name is `Veil`.
2. Theme id is `veil-noir`.
3. Connected canvas is enabled.
4. Locale list is only `en`.
5. Device decks exist for iPhone, Android phone, iPad, Android tablet, and feature graphic.

This means the project already contains a useful real-world example of multi-device composition and export.

## Strong Parts Worth Preserving

### 1. Versioned project persistence

`src/lib/storage.ts` already implements a good local-first persistence model:

1. File-backed canonical state.
2. Fast cache for instant reload.
3. Migration handling.
4. Autosave.
5. Undo and redo.

This is a very good foundation for a desktop app.

### 2. Connected canvas

`src/components/editor/slide-canvas.tsx` is the most important product differentiator.

It allows:

1. Cross-screen device overlap.
2. Cross-screen decorative composition.
3. Export crops from a shared horizontal strip.

This should be preserved exactly in the desktop version.

### 3. Project JSON model

`src/lib/types.ts` and `app-store-screenshots.json` already define a useful domain model:

1. Device decks.
2. Slide layouts.
3. Localized copy.
4. Element transforms.
5. Theme selection.

This can become the desktop app's import/export format.

### 4. Store export rules

`src/lib/constants.ts` already contains device canvas sizes and export sizes. That logic is reusable even if the renderer is rebuilt.

## Weak Parts That Should Not Be Ported Directly

### 1. Browser-based export pipeline

The current export path depends on:

1. DOM paint timing.
2. `html-to-image`.
3. Image preloading to base64.
4. Off-screen HTML capture.

This works, but it is web-specific and more fragile than a native desktop renderer.

### 2. Thin JSON write endpoint

`src/app/api/project/route.ts` writes any JSON body directly to disk. That is fine for a private local tool, but a desktop product should validate and version state before writing.

### 3. Upload model

The current upload path is built for a browser app. A desktop app should support:

1. Native file pickers.
2. Drag-drop from Finder/Explorer.
3. Asset import or linked-file modes.
4. Asset manifests and thumbnails.

### 4. No agent system at all

There is nothing in the current codebase for:

1. Detecting installed agents.
2. Connecting models.
3. Running analysis jobs.
4. Managing prompt history.
5. Streaming results.
6. Applying AI edits to multiple slides.

That must be designed from scratch.

## Current Functional Gaps Relative To Your Idea

Your requested desktop product needs the following that the repo does not have yet:

| Requested capability | Current status |
|---|---|
| Discover installed coding agents on launch | Missing |
| Connect local or remote models | Missing |
| Add screenshot references and style references | Partial only. There is screenshot input, but no reference-board workflow. |
| Ask an agent to analyze references and suggest themes | Missing |
| Prompt-driven generation flow | Missing |
| Result page with candidate sets | Missing |
| Multi-select edit with AI | Missing |
| Batch regeneration and bundle management | Partial only. Export exists, generation management does not. |

## Risks Already Visible In The Current Code

### 1. Theme type drift

`src/lib/types.ts` lists a narrower `ThemeId` union than the actual themes in `src/lib/constants.ts`. The saved state uses `veil-noir`, but that value is not present in the union. This is a small but important signal that schema and runtime values need tighter validation before a desktop rewrite.

### 2. Reset messaging is stronger than actual behavior

The reset dialog says uploaded screenshots will be lost, but the reset actions only reset project state. They do not remove uploaded files from disk.

### 3. Export correctness depends on browser timing

The project already has extra logic to wait for paint and preload images before export. That is useful evidence that the current export system is doing real work around browser capture limitations.

## Reuse Strategy For Flutter

Reuse directly:

1. Project concepts.
2. Slide/layout definitions.
3. Connected-canvas semantics.
4. Export size tables.
5. Per-device deck model.

Do not reuse directly:

1. React components.
2. Next.js routes.
3. `html-to-image` export path.
4. Radix/ShadCN and `react-rnd` behavior.

## Practical Conclusion

This repo is a strong product prototype and a useful behavior reference. It is not a direct codebase to convert into Flutter. The right approach is:

1. Keep the current repo as the reference implementation.
2. Freeze and validate the project schema.
3. Build a new Flutter desktop editor that imports and exports that schema.
4. Add the missing agent and LLM orchestration layers as first-class desktop features.
