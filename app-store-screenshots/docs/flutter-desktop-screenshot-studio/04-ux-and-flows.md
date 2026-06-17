# UX And Flows

## Product Structure

Recommended top-level sections:

1. Home
2. Connectors
3. Projects
4. References
5. Generate
6. Results
7. Export
8. Settings

## Desktop Layout Principle

Keep the editing experience close to the strengths of the current app:

1. Left panel for structure and assets.
2. Center for canvas and result preview.
3. Right panel for properties, AI controls, and history.

## Primary Flow

### 1. Launch Flow

```text
Open app
  -> pick or reopen workspace
  -> run connector discovery
  -> show discovered agents/models
  -> user approves or configures connectors
  -> continue to project setup
```

### 2. Project Setup Flow

```text
Create project or import existing project
  -> set app name, locales, stores, devices
  -> import screenshots
  -> import references
  -> continue to analysis
```

### 3. Analysis Flow

```text
Select connector
  -> choose model or agent profile
  -> review assets and references
  -> run analysis
  -> receive 3-5 theme/styling concepts
  -> approve one concept or combine concepts
```

### 4. Generation Flow

```text
Enter project brief
  -> choose target device decks
  -> generate candidate result set
  -> review progress and logs
  -> land on results page
```

### 5. Result Editing Flow

```text
View generated set
  -> single select or multi-select screens
  -> manual edit or AI edit
  -> compare before/after
  -> accept or revert changes
  -> export bundle
```

## Key Screens

### Home

Shows:

1. Recent projects.
2. Last used connectors.
3. Discovery summary.
4. Quick actions: New, Import, Reopen.

### Connectors Screen

Sections:

1. Discovered local connectors.
2. Remote API connectors.
3. Manual custom connectors.
4. Test connection panel.
5. Capability badges.

### References Screen

This should behave like a lightweight moodboard.

Areas:

1. Source screenshots by device.
2. Style references.
3. Notes and tags.
4. Prompt preview for analysis.

### Generate Screen

Inputs:

1. Selected connector and model.
2. Approved theme concept.
3. Project brief.
4. Constraints such as dark mode only, fewer words, premium tone, family-friendly tone.

Outputs:

1. Queued job status.
2. Live logs.
3. Estimated result set size.

### Results Screen

This is the most important new surface.

Required capabilities:

1. Switch between candidate sets.
2. Compare current set with previous set.
3. Toggle single-select and multi-select modes.
4. Lock selected screens.
5. Apply AI edit to selected screens.
6. Apply AI edit to all unlocked screens.
7. Open a selected screen in full manual edit mode.

## Results Screen Layout

Recommended desktop arrangement:

```text
Left:    candidate sets, slide list, filters
Center:  connected-canvas preview or selected-screen focus view
Right:   inspector, AI edit prompt, history, approve/revert controls
Bottom:  job activity, warnings, export readiness
```

## Multi-Select Editing Rules

This is central to your requested workflow.

The result page should let the user:

1. Click one screen for focused editing.
2. Shift-click or checkbox-select multiple screens.
3. Run prompts like `make these darker`, `shorten headlines`, `increase contrast`, `use warmer palette`, or `replace all labels with stronger benefit copy`.
4. Review changes as patches before accepting.
5. Apply to selected only, current device only, or all unlocked devices.

## UX Rules For AI Actions

1. Never silently overwrite manual edits.
2. Every AI action should produce a previewable patch.
3. The app should highlight which screens changed.
4. The user should be able to revert per action, not only global undo.
5. Manual editing must still work even if no connector is available.

## Preserve Existing Editing Strengths

The current app already has good editing patterns worth keeping:

1. Screen list with thumbnails.
2. Connected strip preview.
3. Inspector panel.
4. Inline text editing.
5. Direct manipulation of elements.
6. Export bundle action.

The desktop app should keep these behaviors, then layer AI workflows around them.

## Empty States

Important empty states to design well:

1. No connectors discovered.
2. Connectors discovered but not approved.
3. No screenshots imported.
4. No reference board yet.
5. Analysis failed.
6. Generation returned partial output.
7. Export blocked by missing assets.

## Error Handling Expectations

1. Connector errors must show the failing command or endpoint.
2. Structured output errors must show what field failed validation.
3. If AI output is invalid, the project state must remain unchanged.
4. Users must be able to continue manual editing after any failed AI step.
