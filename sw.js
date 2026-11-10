const CACHE = 'coach-0378e385bf';
const CORE = ['./', './index.html', './manifest.webmanifest', './voice-heart.ogg', './voice-michael.ogg', './icon-192.png', './icon-512.png'];
self.addEventListener('install', e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)).then(() => self.skipWaiting())); });
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  const keep = res => { if (res && (res.ok || res.type === 'opaque')) { const c = res.clone(); caches.open(CACHE).then(x => x.put(req, c)); } return res; };
  if (url.origin === location.origin && req.mode === 'navigate') {
    e.respondWith(fetch(req).then(keep).catch(() => caches.match(req).then(r => r || caches.match('./index.html'))));
    return;
  }
  if (url.origin === location.origin || /fonts\.(googleapis|gstatic)\.com$/.test(url.hostname)) {
    e.respondWith(caches.match(req).then(r => r || fetch(req).then(keep)));
  }
});
