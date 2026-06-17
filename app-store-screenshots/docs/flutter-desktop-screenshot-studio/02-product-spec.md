# Product Spec

## Working Name

Agent-Powered Screenshot Studio

## Product Vision

Create a desktop app for macOS and Windows that helps a user turn real app screenshots, style references, and a project brief into polished App Store and Play Store screenshot bundles using connected agents, models, and local editing tools.

## Product Goal

Reduce the work from:

1. Manually designing every slide.
2. Manually rewriting copy.
3. Manually iterating style directions.
4. Manually exporting every device bundle.

To:

1. Connect agents and models.
2. Provide source screenshots and references.
3. Review AI-generated themes and concepts.
4. Edit one or many screens.
5. Export final bundles.

## Non-Goals

1. Generating fake app UI from nothing.
2. Replacing the need for real source screenshots.
3. Detecting every agent installed on every system with no configuration.
4. Full design-tool parity with Figma.
5. Shipping on Mac App Store in v1 if sandbox restrictions block local process discovery.

## Primary Users

1. Indie app developers.
2. Mobile product teams.
3. Agencies producing app store assets.
4. Builders using local coding agents and local or remote LLMs.

## Core User Story

When I open the app, I want it to discover the agents and model runtimes I already have, let me connect the ones I trust, take my screenshots and references, ask an agent to suggest themes and styling, generate candidate screenshot sets, let me edit one or many screens with AI and manual controls, and export ready-to-upload bundles.

## Scope Summary

### In Scope

1. macOS and Windows Flutter desktop app.
2. Project creation and import.
3. Agent discovery and connection.
4. Reference screenshot and inspiration board.
5. Theme and styling suggestion workflow.
6. Prompt-driven concept generation.
7. Result page with candidate sets.
8. Single-screen and multi-screen editing.
9. Bundle export for Apple and Google formats.
10. Local-first project persistence.

### Out Of Scope For V1

1. Collaboration and multi-user sync.
2. Browser version.
3. Full plugin marketplace.
4. Automatic publishing to App Store Connect or Play Console.
5. Full vector illustration generation pipeline.

## Functional Requirements

### 1. Launch And Agent Discovery

The app must:

1. Scan for known local agent executables in PATH and known install locations.
2. Scan for known local model runtimes such as Ollama and LM Studio.
3. Show discovered connectors with status: available, not configured, unavailable, or error.
4. Let the user manually add a custom connector.
5. Let the user test a connector before using it.
6. Persist approved connectors per machine.

### 2. Project Setup

The app must let the user:

1. Create a new screenshot project.
2. Import an existing `app-store-screenshots.json` project.
3. Choose target stores and devices.
4. Select a workspace folder.
5. Set app name, locales, and export targets.

### 3. Source Assets And References

The app must support:

1. Importing source screenshots by device and locale.
2. Drag-dropping multiple screenshots at once.
3. A reference board for inspiration images.
4. Tags on references such as `style`, `layout`, `copy-tone`, `color`, and `avoid`.
5. Optional notes per reference.

### 4. Analysis And Theme Suggestions

The user selects an agent or model and runs analysis.

The system must:

1. Send source screenshots, references, and project metadata to the selected connector.
2. Ask for structured output, not only free-form text.
3. Return theme suggestions with:
   - theme name
   - color palette
   - typography direction
   - layout notes
   - copy tone
   - confidence or rationale
4. Show multiple concepts instead of a single answer.
5. Let the user approve one concept or combine parts of several.

### 5. Generation Workflow

After concept approval, the user adds a project brief.

The app must support:

1. A brief field for goals, audience, tone, and constraints.
2. Structured generation of slide headlines, labels, layout selection, and element placement.
3. Candidate result sets with version numbers.
4. Regeneration of a whole set or selected screens.
5. Locking screens so later runs do not overwrite them.

### 6. Result Page And Editing

The result page must preserve current editing strengths and add AI workflows.

The app must support:

1. Single-screen selection.
2. Multi-screen selection.
3. Manual editing of text, layout, image assignment, transform, and style.
4. AI edit prompts applied to selected screens only.
5. AI edit prompts applied to all unlocked screens.
6. Compare current version against previous generation.
7. Accept, reject, or revert AI changes.
8. Inline activity history for agent actions.

### 7. Export

The app must:

1. Export store-ready bundles by platform, device, orientation, and locale.
2. Preserve connected-canvas cropping behavior.
3. Support feature graphic export.
4. Show missing-asset warnings before export.
5. Save exported bundles to a user-chosen output folder.

### 8. Persistence

The app must:

1. Store project state locally.
2. Keep a versioned project schema.
3. Support autosave.
4. Keep generation history.
5. Store connector settings securely.

## Quality Requirements

1. The app must work offline for manual editing and export.
2. Agent-powered features may require local or remote connectors.
3. Large export jobs must not freeze the UI.
4. Project files must remain readable and portable.
5. Users must be able to recover from failed agent runs without losing manual edits.

## Acceptance Criteria

| Area | Acceptance Criteria |
|---|---|
| Discovery | At least one known local runtime or CLI agent can be auto-detected on a supported machine. |
| Connection | User can test a connector and see pass/fail details. |
| Reference analysis | User can attach screenshots and references and receive at least 3 structured theme suggestions. |
| Generation | User can produce at least one candidate set for a chosen device deck. |
| Result editing | User can select multiple screens and apply one AI edit instruction to them. |
| Manual editing | User can still do direct editing without using AI. |
| Export | User can export a full bundle matching Apple/Google size requirements. |
| Import | Existing `app-store-screenshots.json` projects can be loaded with reasonable fidelity. |

## Product Constraints

1. Real source screenshots remain the source of truth for app UI.
2. AI should generate composition, copy, style direction, and edit suggestions around those screenshots.
3. The first release should target direct desktop distribution, not app-store sandboxed desktop distribution.
