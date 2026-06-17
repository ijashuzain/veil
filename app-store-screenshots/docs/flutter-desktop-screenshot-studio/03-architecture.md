# Architecture

## Recommended Architecture

Build a Flutter desktop app with a local service layer.

Recommended principle:

1. Flutter owns UI, canvas, export, and project state.
2. A connector layer owns agent and model discovery plus execution.
3. A versioned local project format keeps imports and exports portable.

## Why Flutter Is Viable Here

Flutter desktop is a good fit because the product is:

1. Heavy on custom canvas and layout rendering.
2. Cross-platform across macOS and Windows.
3. Mostly local-first.
4. Better served by native image export than browser DOM capture.

## Why This Is Not A Direct Port

The current repo depends on:

1. React component rendering.
2. Browser drag/drop and `react-rnd`.
3. Next.js file routes.
4. `html-to-image` for export.

These should be replaced, not translated line by line.

## High-Level System

```text
Flutter Desktop App
  |- Workspace + project manager
  |- Screenshot editor canvas
  |- Result browser and comparison UI
  |- Export engine
  |- Local project store
  |- Connector registry
       |- CLI agent adapters
       |- Local model adapters
       |- Remote API adapters
  |- Job orchestrator
       |- analysis jobs
       |- generation jobs
       |- edit jobs
```

## Core Modules

### 1. Project Core

Responsibilities:

1. Define the versioned project schema.
2. Load, validate, migrate, and save project files.
3. Own devices, locales, slides, layouts, themes, transforms, and generation history.

Recommendation:

Keep compatibility with the current `app-store-screenshots.json` shape where practical, then extend it with desktop-specific sections.

### 2. Canvas Engine

Responsibilities:

1. Render single-screen and connected multi-screen decks.
2. Support drag, resize, rotate, and layer ordering.
3. Render thumbnails and full-size output from the same model.

Implementation direction:

1. Use Flutter widgets for layout.
2. Use a `CustomPainter` only where precision or performance requires it.
3. Use `RepaintBoundary` for export surfaces.
4. Keep one source of truth for geometry so preview and export match.

### 3. Asset Library

Responsibilities:

1. Import screenshots and references.
2. Generate thumbnails.
3. Copy or link source assets.
4. Resolve per-locale and per-device paths.

Recommendation:

Move away from raw path strings as the only identity. Use asset records with ids, source path, imported path, tags, and metadata.

### 4. Connector Registry

Responsibilities:

1. Discover known agents and model runtimes.
2. Test health and capabilities.
3. Store approved connectors.
4. Route analysis and edit jobs to the correct backend.

Connector categories:

1. CLI agent adapters.
2. OpenAI-compatible HTTP adapters.
3. Local runtime adapters.
4. Custom connector adapters.

## Agent Discovery Strategy

This is the critical design choice.

Do not try to detect every possible agent generically.

Use an adapter registry with these discovery methods:

1. PATH lookup for known executable names.
2. Known install locations on macOS and Windows.
3. Known local ports for runtimes that expose HTTP APIs.
4. Known config locations for previously approved connectors.
5. Manual connector creation.

Each connector should expose capability flags:

1. `text_generation`
2. `image_input`
3. `structured_output`
4. `streaming`
5. `batch_edit`
6. `tool_calling`
7. `local_only`
8. `remote_api`

## Recommended Initial Connectors

1. OpenAI-compatible endpoint.
2. Ollama.
3. LM Studio.
4. Anthropic API.
5. One or two known local CLI agents used in your workflow.
6. Custom command adapter.

## Orchestration Model

Each AI action should be a job with:

1. input assets
2. selected connector
3. structured prompt template
4. expected output schema
5. status
6. logs
7. result payload

Job types:

1. `reference_analysis`
2. `theme_suggestion`
3. `deck_generation`
4. `selected_screen_edit`
5. `batch_edit`
6. `copy_rewrite`

## Structured Output Rule

Do not let agents return only prose if the app needs editable results.

Require structured output for:

1. theme suggestions
2. slide plans
3. copy suggestions
4. edit patches

The app should parse and validate outputs before applying them.

## Suggested Desktop Data Additions

Extend the current project model with sections like:

```json
{
  "schemaVersion": 3,
  "appName": "Veil",
  "connectors": [],
  "assets": [],
  "references": [],
  "themeSuggestions": [],
  "generationRuns": [],
  "lockedSlideIds": [],
  "slidesByDevice": {}
}
```

Key new records:

1. `ConnectorProfile`
2. `ReferenceAsset`
3. `ThemeSuggestion`
4. `GenerationRun`
5. `EditOperation`
6. `ExportPreset`

## Export Engine

Use native Flutter rendering instead of browser capture.

Recommended flow:

1. Build an off-screen render tree for the selected device deck.
2. Render the connected strip at full resolution.
3. Crop each slide region natively.
4. Encode PNGs.
5. Zip outputs in a background isolate.

Preserve current naming logic:

`platform/device/size/locale/NN-layout.png`

## Persistence And Recovery

Use a local project folder structure such as:

```text
project/
  project.json
  assets/
  references/
  exports/
  cache/
```

Recommended rules:

1. `project.json` is canonical.
2. Autosave writes atomically.
3. Connector secrets go to OS keychain, not project.json.
4. Generation logs remain local unless the user exports them.

## Security And Trust

1. Never auto-run a discovered connector without user approval.
2. Show the exact command or endpoint being used.
3. Store API keys in Keychain on macOS and Credential Manager on Windows through a secure plugin.
4. Let the user inspect prompt and output history.
5. Keep agent execution scoped to the chosen workspace.

## Suggested Flutter Stack

Recommended starting stack:

1. `flutter_riverpod` for state.
2. `freezed` and `json_serializable` for models.
3. `file_selector` for native file picking.
4. `desktop_drop` for drag-drop.
5. `window_manager` for desktop window control.
6. `path_provider` for app data folders.
7. `archive` for zip creation.
8. `dart:io` for process and HTTP work.

Optional later:

1. A Rust or Go sidecar if process management becomes too brittle in pure Dart.

## Distribution Caveat

If the product needs to inspect the machine, launch local CLIs, and connect to local runtimes, direct desktop distribution is safer for v1 than Mac App Store distribution.
