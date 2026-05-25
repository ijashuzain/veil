import 'dart:convert';

String buildDirectPlayerBootstrapScript({
  required String url,
  required String videoId,
  required String statusId,
}) {
  return '''
(function () {
  const sourceUrl = ${jsonEncode(url)};
  let hlsWaitAttempts = 0;
  let domWaitAttempts = 0;

  function attachWhenReady() {
    const video = document.getElementById(${jsonEncode(videoId)});
    const status = document.getElementById(${jsonEncode(statusId)});
    if (!video || !status) {
      domWaitAttempts += 1;
      if (domWaitAttempts <= 50) {
        setTimeout(attachWhenReady, 100);
      }
      return;
    }

    if (video.__veilHlsBootstrapped) return;
    start(video, status);
  }

  function setStatus(status, message) {
    status.textContent = message || '';
    status.style.opacity = message ? '1' : '0';
  }

  function requestPlay(video, status) {
    const promise = video.play();
    if (promise && typeof promise.catch === 'function') {
      promise.catch(function () {
        setStatus(status, 'Tap play to start');
      });
    }
  }

  function loadNative(video, status) {
    setStatus(status, '');
    video.src = sourceUrl;
    video.load();
    requestPlay(video, status);
  }

  function start(video, status) {
    if (!window.Hls) {
      hlsWaitAttempts += 1;
      if (hlsWaitAttempts <= 50) {
        setTimeout(function () {
          start(video, status);
        }, 100);
        return;
      }

      loadNative(video, status);
      return;
    }

    if (window.Hls.isSupported()) {
      video.__veilHlsBootstrapped = true;
      const hls = new Hls({
        enableWorker: true,
        lowLatencyMode: true
      });
      video.__veilHls = hls;
      hls.loadSource(sourceUrl);
      hls.attachMedia(video);
      hls.on(Hls.Events.MANIFEST_PARSED, function () {
        setStatus(status, '');
        requestPlay(video, status);
      });
      hls.on(Hls.Events.ERROR, function (_, data) {
        if (!data.fatal) return;

        hls.destroy();
        video.__veilHls = null;
        loadNative(video, status);
      });
      return;
    }

    const nativeSupport =
      video.canPlayType('application/vnd.apple.mpegurl') ||
      video.canPlayType('application/x-mpegURL');
    if (nativeSupport) {
      video.__veilHlsBootstrapped = true;
      loadNative(video, status);
      return;
    }

    setStatus(status, 'HLS not supported');
  }

  attachWhenReady();
})();
''';
}
