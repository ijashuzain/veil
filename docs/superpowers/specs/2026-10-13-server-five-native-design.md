# Server 5 native playback

Approved scope: add a fifth, independent server option using CineSrc resolution
and the native video_player engines. Existing four targets and launch decisions
retain their current behavior and persisted enum names.

Server 5 resolves the requested movie or selected season/episode through a
bounded, temporary on-device WebView. Document-start instrumentation captures a
real HLS playlist request and its headers, rather than a browser-local blob URL.
The resolver copies only cookies applicable to that source and disposes its
WebView before returning the source to the native player. Signed URLs and session
headers remain in memory and are not written to playback history or logs.

The player provides playback, pause, seeking, loading/error state, retry with
fresh resolution, close, and an explicit embedded fallback. Resolution is
cancelled when the route closes. Web/unsupported desktop platforms use an
explicit embedded fallback; the first native implementation targets Android/iOS.

Verification must prove native advancing playback and seeking after resolver
disposal. Unit/widget checks cover URL/header selection, cancellation, timeout,
Server 5 selection/episode routing/history, and the four existing server targets.
