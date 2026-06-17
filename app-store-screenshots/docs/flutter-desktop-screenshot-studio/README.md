# Flutter Desktop Screenshot Studio

## Conclusion

Yes, this idea is possible with Flutter for macOS and Windows.

The main caveat is that this repository is currently a local-first Next.js editor, so this would be a real desktop product build, not a small port. The strongest things to carry over are the project model, connected-canvas behavior, screenshot workflow, and export rules. The weakest thing to carry over is the current browser-specific rendering/export stack.

The other important caveat is agent discovery: the app can discover known installed agents and model runtimes, but it cannot reliably detect every possible coding agent on every machine with zero configuration. The right design is adapter-based discovery plus manual connection.

## Recommended Direction

1. Build a Flutter desktop app for macOS and Windows.
2. Keep a versioned JSON project format so existing work can be imported.
3. Rebuild canvas rendering and export natively in Flutter.
4. Add an adapter layer for agent discovery, connection, prompt orchestration, and background jobs.
5. Preserve the current connected-canvas editing model because it is the best differentiator in the existing project.

## Document Index

1. `01-current-project-analysis.md`
   Current repository analysis, architecture, strengths, gaps, and reuse opportunities.
2. `02-product-spec.md`
   Product requirements for the Flutter desktop version with agent-assisted generation.
3. `03-architecture.md`
   Recommended technical architecture, data model direction, and agent integration strategy.
4. `04-ux-and-flows.md`
   Screen structure, workflow design, and result-page editing behaviors.
5. `05-roadmap-and-risks.md`
   Delivery phases, technical risks, open questions, and migration guidance.

## Short Answer To Your Question

Possible in Flutter:

| Capability | Feasible | Notes |
|---|---|---|
| macOS desktop app | Yes | Flutter desktop is production-capable here. |
| Windows desktop app | Yes | Flutter desktop is production-capable here. |
| Discover installed agents | Yes, with limits | Use known adapters plus manual add. |
| Connect local and remote models | Yes | Support CLI agents and OpenAI-compatible endpoints. |
| Analyze screenshots and references | Yes | Best done as structured analysis, not raw image generation only. |
| Generate theme and styling suggestions | Yes | Strong fit for LLM + reference images. |
| Agent-assisted editing of one or many screens | Yes | Needs batch-selection and job orchestration. |
| Prepare export bundles | Yes | Better done with native Flutter rendering than browser capture. |
| Reuse current React code directly | No | Reuse concepts and schema, not UI code. |

## Recommended Scope Decision

Treat this as a new desktop product that imports the current project format rather than a direct rewrite of the current UI file-for-file.
