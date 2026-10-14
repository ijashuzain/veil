# Server 5 implementation plan

1. Append `PlaybackServer.five`; add its CineSrc target and native-route flag.
   Add a fifth server-sheet callback and episode selection without altering the
   four existing callbacks. Preserve enum-name history serialization.
2. Add an isolated `native_player` feature: resolved-stream model, pure candidate
   validation, document-start stream capture, and cancellable headless resolver.
   Capture HLS URL/request context and close the resolver before native handoff.
3. Add video_player and a native fullscreen view with retry, seek, pause, and
   explicit embedded fallback. Use conditional/platform guards so web builds work.
4. Add focused regression tests and extend opt-in live auditing for native
   controller telemetry. Run movies and selected episodes on the simulator.
5. Check existing playback tests, analysis, native build, and web compilation.
   Report actual native handoff outcomes and any fallback limitations.
