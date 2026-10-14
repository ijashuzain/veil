import 'dart:convert';

const directPlayerHlsScriptUrl =
    'https://cdn.jsdelivr.net/npm/hls.js@1.6.13/dist/hls.min.js';

String buildDirectPlayerBootstrapScript({
  required String url,
  required String videoId,
  required String statusId,
}) =>
    '''
(function () {
  const sourceUrl = ${jsonEncode(url)};
  let domWaitAttempts = 0;

  function attachWhenReady() {
    const video = document.getElementById(${jsonEncode(videoId)});
    const status = document.getElementById(${jsonEncode(statusId)});
    if (!video || !status) {
      if (++domWaitAttempts <= 50) setTimeout(attachWhenReady, 100);
      return;
    }
    if (video.__veilHlsBootstrapped || video.__veilDisposed) return;
    video.__veilHlsBootstrapped = true;
    start(video, status);
  }

  function setStatus(status, message) {
    status.textContent = message || '';
    status.style.opacity = message ? '1' : '0';
  }

  function requestPlay(video, status) {
    if (video.__veilDisposed) return;
    const promise = video.play();
    if (promise && typeof promise.catch === 'function') {
      promise.catch(function () {
        if (!video.__veilDisposed) setStatus(status, 'Tap play to start');
      });
    }
  }

  function loadHlsLibrary() {
    if (window.Hls) return Promise.resolve();
    if (window.__veilHlsLibrary) return window.__veilHlsLibrary;
    window.__veilHlsLibrary = new Promise(function (resolve, reject) {
      const script = document.createElement('script');
      script.src = ${jsonEncode(directPlayerHlsScriptUrl)};
      script.async = true;
      const timer = setTimeout(function () {
        script.remove();
        reject(new Error('HLS library timeout'));
      }, 10000);
      script.onload = function () { clearTimeout(timer); resolve(); };
      script.onerror = function () {
        clearTimeout(timer);
        script.remove();
        reject(new Error('HLS library unavailable'));
      };
      document.head.appendChild(script);
    }).catch(function (error) {
      window.__veilHlsLibrary = null;
      throw error;
    });
    return window.__veilHlsLibrary;
  }

  function start(video, status) {
    let usingNative = false;
    let hlsStarted = false;
    video.addEventListener('playing', function () { setStatus(status, ''); });
    video.addEventListener('waiting', function () {
      setStatus(status, 'Buffering...');
    });
    video.addEventListener('error', function () {
      if (video.__veilDisposed) return;
      if (usingNative && !hlsStarted) {
        usingNative = false;
        startHls();
      } else {
        setStatus(status, 'Stream cannot be played. Try another server.');
      }
    });

    function startHls() {
      if (hlsStarted || video.__veilDisposed) return;
      hlsStarted = true;
      setStatus(status, 'Loading stream...');
      loadHlsLibrary().then(function () {
        if (video.__veilDisposed) return;
        if (!window.Hls || !window.Hls.isSupported()) {
          setStatus(status, 'HLS not supported. Try another server.');
          return;
        }
        // VOD needs adaptive bitrate and bounded buffers, not live low latency.
        const Hls = window.Hls;
        const hls = new Hls({
          enableWorker: true,
          lowLatencyMode: false,
          capLevelToPlayerSize: true,
          startLevel: -1,
          maxBufferLength: 20,
          maxMaxBufferLength: 40
        });
        video.__veilHls = hls;
        let networkRecoveries = 0;
        let mediaRecoveries = 0;
        hls.on(Hls.Events.MANIFEST_PARSED, function () {
          requestPlay(video, status);
        });
        hls.on(Hls.Events.ERROR, function (_, data) {
          if (!data.fatal || video.__veilDisposed) return;
          if (data.type === Hls.ErrorTypes.NETWORK_ERROR &&
              networkRecoveries++ < 2) {
            setStatus(status, 'Reconnecting...');
            hls.startLoad();
          } else if (data.type === Hls.ErrorTypes.MEDIA_ERROR &&
                     mediaRecoveries++ < 1) {
            hls.recoverMediaError();
          } else {
            hls.destroy();
            video.__veilHls = null;
            setStatus(status, 'Stream cannot be played. Try another server.');
          }
        });
        hls.loadSource(sourceUrl);
        hls.attachMedia(video);
      }).catch(function () {
        if (!video.__veilDisposed) {
          setStatus(status, 'Unable to load player. Check connection or retry.');
        }
      });
    }

    const nativeSupport =
      video.canPlayType('application/vnd.apple.mpegurl') ||
      video.canPlayType('application/x-mpegURL');
    if (nativeSupport || /\\.mp4(?:[?#]|\$)/i.test(sourceUrl)) {
      usingNative = true;
      setStatus(status, 'Loading stream...');
      video.src = sourceUrl;
      video.load();
      requestPlay(video, status);
    } else {
      startHls();
    }
  }

  attachWhenReady();
})();
''';
