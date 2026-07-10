# Portal SI Web

Frontend SvelteKit untuk Portal SI. Backend Laravel di `../api` adalah source of truth untuk kontrak API dan perilaku data.

## Status

Frontend SvelteKit memakai API Laravel nyata untuk auth, feed, post/comment, story, explore, social graph, profil, pesan/grup, pengumuman, notifikasi, pengaturan, portfolio, dan presence. Reverb memakai private-channel auth melalui BFF dengan polling hanya sebagai fallback. Composer memakai BFF allowlist untuk iTunes/Nominatim, upload dengan progress/cancel, crop gambar, dan draft media IndexedDB. Tidak ada fixture pada route production.

## Prasyarat

- Node.js 24 atau rilis LTS kompatibel
- npm 11+
- Backend Laravel untuk fase integrasi

## Menjalankan lokal

```sh
cp .env.example .env
npm ci
npm run dev
```

Vite berjalan di `http://localhost:5173` secara default.

## Perintah kualitas

```sh
npm run format
npm run check
npm run lint
npm run test:unit -- --run
npm run test:e2e
npm run build
npm run preview
```

Playwright mengunduh browser saat `test:e2e` dijalankan pertama kali. Jangan arahkan E2E destructive ke data production.

## Struktur

```text
src/lib/components/   komponen UI, layout, feed, auth, chat, composer
src/lib/types/        domain types awal
src/routes/(public)/  onboarding dan authentication
src/routes/(app)/     shell authenticated dan domain aplikasi
docs/                 audit kontrak, parity, IA, dan screenshot
static/assets/        aset Portal SI yang dipakai ulang
```

## Arsitektur yang dituju

- Adapter Node menjadi deployment default agar token Sanctum dapat disimpan dalam sesi/cookie `HttpOnly`, `Secure`, `SameSite=Lax`.
- Browser memanggil route BFF SvelteKit; BFF meneruskan bearer ke Laravel. Token mentah tidak disimpan di localStorage.
- Response penting divalidasi runtime dengan Zod dan dipetakan ke model UI per domain.
- Reverb memakai Pusher protocol dengan private-channel auth melalui BFF.
- Draft composer beserta media disimpan di IndexedDB; preferensi device-only disimpan lokal dan diberi label jelas.
- PWA hanya melakukan cache-first untuk build/static asset; HTML authenticated dan `/api/*` selalu network-only.

Detail kontrak dan gap:

- [API contract](docs/api-contract.md)
- [Contract gaps](docs/contract-gaps.md)
- [Feature parity matrix](docs/feature-parity-matrix.md)
- [Information architecture](docs/information-architecture.md)

## Screenshot Fase 1

- `docs/screenshots/home-mobile-390x844.png`
- `docs/screenshots/home-tablet-820x1180.png`
- `docs/screenshots/home-desktop-1440x1000.png`
- `docs/screenshots/messages-desktop-1440x1000.png`
- `docs/screenshots/login-mobile-390x844.png`

Screenshot dihasilkan dari production build lokal. Pemeriksaan responsif awal mencakup 17 route utama dan tidak menemukan horizontal overflow setelah perbaikan grid mobile.

## Deployment

Build adapter Node menghasilkan server di `build/index.js`:

```sh
npm ci
npm run build
HOST=127.0.0.1 PORT=3100 node build/index.js
```

Reverse proxy production harus menangani HTTPS, `X-Forwarded-*`, WebSocket upgrade, batas upload yang konsisten dengan Laravel, dan health/readiness. Lihat [deployment](docs/deployment.md), [security](docs/security.md), dan [definition of done](docs/definition-of-done.md).
