const nativeStreamCaptureScript = r'''
(function () {
  if (window.__veilStreamCapture) return;
  window.__veilStreamCapture = true;
  const pending = [];
  const seen = new Set();
  const subtitles = new Map();
  const subtitleRequests = [];
  function collectSubtitles(value, depth) {
    if (!value || depth > 6) return;
    if (Array.isArray(value)) { value.slice(0,200).forEach(v=>collectSubtitles(v,depth+1)); return; }
    if (typeof value !== 'object') return;
    const src=value.url||value.file||value.src||value.downloadUrl;
    if(typeof src==='string' && (value.lang||value.language||value.label||/\.(vtt|srt)(\?|$)/i.test(src))) {
      try { const url=new URL(src,location.href); if(url.protocol==='https:')subtitles.set(url.href,{url:url.href,label:String(value.label||value.language||value.lang||'Subtitles'),language:String(value.language||value.lang||'')}); } catch (_) {}
    }
    Object.values(value).forEach(v=>collectSubtitles(v,depth+1));
  }
  function emit(url, headers, body) {
    if (typeof body !== 'string' || !body.trimStart().startsWith('#EXTM3U')) return;
    const absolute = new URL(url, location.href).href;
    if (seen.has(absolute)) return;
    seen.add(absolute);
    const candidate = {url:absolute,headers:headers,playlist:body,
      referer:location.href,userAgent:navigator.userAgent,subtitles:Array.from(subtitles.values()),subtitleRequests};
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('veilResolvedStream', candidate);
    } else { pending.push(candidate); }
  }
  window.addEventListener('flutterInAppWebViewPlatformReady', function () {
    pending.splice(0).forEach(c=>window.flutter_inappwebview.callHandler('veilResolvedStream',c));
  });
  const open = XMLHttpRequest.prototype.open;
  const setHeader = XMLHttpRequest.prototype.setRequestHeader;
  XMLHttpRequest.prototype.open = function (method, url) {
    this.__veilUrl = String(url); this.__veilHeaders = {};
    this.addEventListener('load', function () {
      if (this.status < 200 || this.status >= 300) return;
      try { emit(this.responseURL || this.__veilUrl, this.__veilHeaders, this.responseText); } catch (_) {}
    });
    return open.apply(this, arguments);
  };
  XMLHttpRequest.prototype.setRequestHeader = function (name, value) {
    if (this.__veilHeaders) this.__veilHeaders[name] = String(value);
    return setHeader.apply(this, arguments);
  };
  const originalFetch = window.fetch;
  window.fetch = function (input, init) {
    const url = input && input.url || String(input);
    if(/\/api\/subtitles\/search/i.test(url))subtitleRequests.push({url:new URL(url,location.href).href,method:init&&init.method||'GET',body:init&&typeof init.body==='string'?init.body:null});
    const headers = {};
    new Headers(input && input.headers || {}).forEach((v,k)=>headers[k]=v);
    new Headers(init && init.headers || {}).forEach((v,k)=>headers[k]=v);
    return originalFetch.apply(this, arguments).then(function (response) {
      const mime = response.headers.get('content-type') || '';
      if(response.ok && /\/subtitles\//i.test(url))response.clone().json().then(v=>collectSubtitles(v,0)).catch(()=>{});
      if (response.ok && (/mpegurl/i.test(mime) || /\.m3u8|\/api\/playlist\//i.test(url))) {
        response.clone().text().then(body=>emit(response.url || url, headers, body)).catch(()=>{});
      }
      return response;
    });
  };
  // Resolution must not create a second audible player or allow popup escape.
  try { Object.defineProperty(window,'open',{value:()=>null,writable:false}); } catch (_) {}
  document.addEventListener('play', e=>{if(e.target && e.target.tagName==='VIDEO')e.target.muted=true;},true);
  function inspect() {
    document.querySelectorAll('video').forEach(video=>{
      video.muted=true;
      const url=video.currentSrc||video.src;
      if(/^https:\/\//.test(url) && /\.m3u8(?:[?#]|$)/i.test(url) && !seen.has(url) && window.flutter_inappwebview) {
        seen.add(url);
        window.flutter_inappwebview.callHandler('veilResolvedStream',{url,direct:true,referer:location.href,userAgent:navigator.userAgent,subtitles:Array.from(subtitles.values())});
      }
    });
    const gate=document.getElementById('bigPlay');
    if(gate && gate.getBoundingClientRect().width>0 && !gate.__veilClicked) {gate.__veilClicked=true;gate.click();}
    document.querySelectorAll('track[src]').forEach(t=>collectSubtitles({url:t.src,label:t.label||t.srclang,language:t.srclang},0));
  }
  setInterval(inspect,500);
})();
''';
