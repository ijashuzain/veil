/// Observational instrumentation only; all URL queries/fragments are omitted.
const playbackProbeScript = r'''
(function () {
  const cleanUrl = function (value) {
    try {
      const url = new URL(value, location.href);
      if(url.protocol==='data:')return 'data:'+String(value).substring(5).split(',')[0];
      if(url.protocol==='about:')return url.href;
      const path = url.pathname.split('/').map(p => p.length > 80 ? '[redacted]' : p).join('/');
      return url.protocol + '//' + url.host + path;
    } catch (_) { return String(value || '').slice(0, 120); }
  };
  const pending = [];
  function send(data) {
    data.frame = cleanUrl(location.href);
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('veilProbe', data);
    } else if (pending.length < 100) { pending.push(data); }
  }
  window.addEventListener('flutterInAppWebViewPlatformReady', function () {
    while (pending.length) send(pending.shift());
  });
  const attached = new WeakSet();
  const sourceProbed = new Set();
  const players = new WeakSet();
  const handledCommands = new Set();
  function snapshot(video, event) {
    send({kind:'video',event:event,time:video.currentTime,paused:video.paused,
      readyState:video.readyState,networkState:video.networkState,
      width:video.videoWidth,height:video.videoHeight,duration:Number.isFinite(video.duration)?video.duration:null,
      buffered:video.buffered.length?video.buffered.end(video.buffered.length-1):0,
      source:cleanUrl(video.currentSrc || video.src),
      errorCode:video.error?video.error.code:0,
      errorMessage:video.error?String(video.error.message).replace(/https?:\S+/g,'[url]'):''});
  }
  function inspect() {
    try {
      const player = window.jwplayer && window.jwplayer();
      if (player && player.on && !players.has(player)) {
        players.add(player);
        player.on('error',function(e){send({kind:'playerError',code:e.code,message:e.message});});
      }
    } catch (_) {}
    document.querySelectorAll('video').forEach(function(video) {
      const source = video.currentSrc || video.src;
      if(source && /^https?:/.test(source) && !sourceProbed.has(source) && window.flutter_inappwebview) {
        sourceProbed.add(source);
        window.flutter_inappwebview.callHandler('veilProbeSource',source,location.href,navigator.userAgent);
      }
      if (!attached.has(video)) {
        attached.add(video);
        ['loadstart','loadedmetadata','loadeddata','canplay','playing','waiting','stalled','error','seeking','seeked'].forEach(function(event) {
          video.addEventListener(event,function(){snapshot(video,event);});
        });
      }
      snapshot(video,'snapshot');
    });
  }
  function documentSnapshot() {
    const video = document.createElement('video');
    send({kind:'document',title:document.title,
      text:document.body?document.body.innerText.slice(0,900):'',
      ua:navigator.userAgent,
      nativeHls:video.canPlayType('application/vnd.apple.mpegurl'),
      h264:video.canPlayType('video/mp4; codecs="avc1.640028"'),
      hevc:video.canPlayType('video/mp4; codecs="hvc1.1.6.L93.B0"'),
      mse:typeof MediaSource!=='undefined',managedMse:typeof ManagedMediaSource!=='undefined',
      viewport:{innerWidth:innerWidth,innerHeight:innerHeight,outerWidth:outerWidth,outerHeight:outerHeight},
      frames:Array.from(document.querySelectorAll('iframe')).map(f=>cleanUrl(f.src))});
    inspect();
  }
  window.addEventListener('error',function(event) {
    send({kind:'scriptError',message:String(event.message||'resource error').replace(/https?:\S+/g,'[url]'),
      url:cleanUrl(event.filename||(event.target&&(event.target.src||event.target.href))||'')});
  },true);
  if (window.fetch) {
    const original = window.fetch;
    window.fetch = function(input, init) {
      const url = input && input.url || String(input);
      const start = performance.now();
      return original.apply(this,arguments).then(function(response) {
        send({kind:'fetch',url:cleanUrl(url),status:response.status,
          mime:response.headers.get('content-type'),ms:Math.round(performance.now()-start)});
        return response;
      },function(error){send({kind:'fetch',url:cleanUrl(url),status:0,ms:Math.round(performance.now()-start),error:String(error)});throw error;});
    };
  }
  const originalOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method,url) {
    const xhr = this; const start = performance.now();
    xhr.addEventListener('loadend',function(){send({kind:'xhr',url:cleanUrl(url),status:xhr.status,
      mime:xhr.getResponseHeader('content-type'),ms:Math.round(performance.now()-start)});});
    return originalOpen.apply(this,arguments);
  };
  try {
    new PerformanceObserver(function(list){list.getEntries().forEach(function(e){
      if (/\.m3u8|\.mpd|\.ts|\.m4s|\.mp4|\/api\//i.test(e.name)) {
        send({kind:'resource',url:cleanUrl(e.name),type:e.initiatorType,ms:Math.round(e.duration),bytes:e.transferSize});
      }
    });}).observe({type:'resource',buffered:true});
  } catch (_) {}
  window.addEventListener('message',function(event) {
    if(event.data && event.data.type==='VS_DEVTOOLS')send({kind:'providerAbort',reason:'VS_DEVTOOLS'});
    const command = event.data && event.data.veilProbeCommand;
    if (!command) return;
    // Providers relay messages up/down nested frames. Keep probe commands out
    // of that relay to avoid creating a diagnostic-only message feedback loop.
    event.stopImmediatePropagation();
    const commandKey=command+':'+String(event.data.time||'');
    if(handledCommands.has(commandKey)) return;
    handledCommands.add(commandKey);
    document.querySelectorAll('iframe').forEach(f=>{try{f.contentWindow.postMessage(event.data,'*');}catch(_){}});
    if (command==='snapshot') documentSnapshot();
    if (command==='play') {
      const button=document.getElementById('bigPlay');
      if(button && button.getBoundingClientRect().width>0) {
        send({kind:'playControlClick',control:'bigPlay'});
        button.click();
      }
    }
    document.querySelectorAll('video').forEach(function(video){
      if(command==='play') {
        try { if(window.jwplayer) window.jwplayer().play(); } catch (_) {}
        const p=video.play(); if(p&&p.catch)p.catch(e=>send({kind:'playRejected',name:e.name,message:e.message}));
      }
      if(command==='seek' && Number.isFinite(video.duration) && video.duration>50) video.currentTime=event.data.time;
    });
  },true);
  document.addEventListener('DOMContentLoaded',documentSnapshot);
  document.addEventListener('error',function(e){if(e.target && e.target.tagName==='VIDEO')snapshot(e.target,'capturedError');},true);
  setInterval(inspect,1000);
})();
''';
