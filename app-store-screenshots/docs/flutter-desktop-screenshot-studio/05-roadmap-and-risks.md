# Roadmap And Risks

## Delivery Recommendation

Build this in phases. The product has two different kinds of complexity:

1. Screenshot-editor parity.
2. Agent and model orchestration.

Trying to solve both at once will slow the project down.

## Suggested Phases

### Phase 0: Schema Freeze And Design

Deliverables:

1. Versioned project schema.
2. Import contract for existing `app-store-screenshots.json` files.
3. UX wireframes for the connector flow and results page.
4. Connector capability model.

### Phase 1: Flutter Desktop Editor Parity

Goal:

Rebuild the current editor core without AI.

Deliverables:

1. Multi-device decks.
2. Connected canvas.
3. Manual editing.
4. Native asset import.
5. Native bundle export.
6. Project save and load.

Reason:

This de-risks the rendering and export engine before adding agent complexity.

### Phase 2: Connector Discovery And Connection

Deliverables:

1. Known connector discovery.
2. Manual connector add.
3. Health checks.
4. Secure credential storage.
5. Connector test panel.

### Phase 3: Reference Analysis And Theme Suggestions

Deliverables:

1. Reference board.
2. Structured analysis jobs.
3. Theme suggestion cards.
4. Concept approval flow.

### Phase 4: Result Generation And AI Editing

Deliverables:

1. Candidate result sets.
2. Result page.
3. Multi-select AI edit.
4. Per-run history and revert.
5. Lock and protect manual edits.

### Phase 5: Polish And Packaging

Deliverables:

1. Performance tuning.
2. Crash recovery.
3. Import/export hardening.
4. Installer packaging.
5. Telemetry only if you explicitly want it.

## Main Technical Risks

### 1. Agent Discovery Is Not Universal

Risk:

Users may expect the app to magically find every agent on the machine.

Mitigation:

1. Support curated adapters first.
2. Show manual add immediately.
3. Phrase the feature as `discover supported connectors`, not `discover everything`.

### 2. AI Output Can Be Messy

Risk:

LLM output may be vague, invalid, or inconsistent.

Mitigation:

1. Require structured output.
2. Validate before applying.
3. Apply changes as previewable patches.
4. Keep manual editing first-class.

### 3. Export Fidelity Must Match Preview

Risk:

If preview and export differ, trust breaks fast.

Mitigation:

1. Share one geometry engine for preview and export.
2. Snapshot the same render tree used by preview.
3. Add export golden tests for critical layouts.

### 4. Desktop Packaging And Permissions

Risk:

Local process access and filesystem scanning may conflict with sandboxed distribution.

Mitigation:

1. Ship direct desktop installers first.
2. Delay store-distribution constraints until later.

### 5. Scope Creep

Risk:

The product can easily turn into a design tool, AI agent hub, and store-delivery platform all at once.

Mitigation:

1. Keep v1 focused on screenshot generation and editing.
2. Treat deployment and advanced collaboration as later modules.

## Open Product Questions

These should be answered before implementation starts:

1. Which exact agents or model runtimes do you want to support first?
2. Do you want only local connectors, or both local and cloud?
3. Should the desktop app import the current project format exactly, or migrate to a new format with an importer?
4. Should references be global per project, or per device deck, or per slide?
5. Do you want AI to generate only composition and copy, or also background art and decorative assets?
6. Do you want the app to manage multiple brand themes inside one project?
7. Do you want later store-upload automation, or keep export as the final step?

## Recommended Build Strategy

Best long-term strategy:

1. Keep the current web project as the behavior reference.
2. Build the Flutter desktop version as a new app.
3. Import existing project JSON rather than trying to reuse UI code.

## Immediate Next Steps

1. Decide the first connector list.
2. Freeze the v1 desktop schema.
3. Wireframe the connector, references, and results flows.
4. Build a Flutter proof of concept for connected-canvas preview and native export.
5. Add one real connector and prove structured theme-suggestion output end to end.
