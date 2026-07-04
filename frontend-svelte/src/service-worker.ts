/// <reference lib="webworker" />

import { build, files, version } from '$service-worker';

const worker = self as unknown as ServiceWorkerGlobalScope;
const cacheName = `portal-si-static-${version}`;
const staticAssets = [...build, ...files].filter(
	(path) => !path.endsWith('.map') && !path.includes('muslim-man.png')
);

worker.addEventListener('install', (event) => {
	event.waitUntil(caches.open(cacheName).then((cache) => cache.addAll(staticAssets)));
	void worker.skipWaiting();
});

worker.addEventListener('activate', (event) => {
	event.waitUntil(
		caches
			.keys()
			.then((keys) =>
				Promise.all(keys.filter((key) => key !== cacheName).map((key) => caches.delete(key)))
			)
			.then(() => worker.clients.claim())
	);
});

worker.addEventListener('fetch', (event) => {
	const request = event.request;
	if (request.method !== 'GET') return;
	const url = new URL(request.url);
	if (url.origin !== worker.location.origin || url.pathname.startsWith('/api/')) return;

	// Authenticated HTML is deliberately network-only and never written to Cache Storage.
	if (request.mode === 'navigate') {
		event.respondWith(
			fetch(request).catch(
				() =>
					new Response(
						'Portal SI sedang offline. Sambungkan kembali internet untuk membuka halaman ini.',
						{ status: 503, headers: { 'Content-Type': 'text/plain; charset=utf-8' } }
					)
			)
		);
		return;
	}

	if (staticAssets.includes(url.pathname)) {
		event.respondWith(caches.match(request).then((cached) => cached ?? fetch(request)));
	}
});
