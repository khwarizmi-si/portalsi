# Memori Proyek — frontend-svelte (Portal SI Web)

> File ini adalah memori kerja tetap untuk folder `frontend-svelte`. Semua perintah pengguna
> di sesi ini ditujukan untuk folder ini kecuali dinyatakan lain. Backend Laravel
> (`../api-portalsi`) adalah source of truth; Flutter (`../lib`) referensi perilaku client.

## Identitas & lokasi

- Nama package: `portal-si-web` (SvelteKit, version 0.0.1)
- Root pengembangan: `D:\Projects\psi-app\frontend-svelte`
- Repo induk `psi-app` berisi: `api-portalsi/` (Laravel, source of truth API),
  `lib/` (Flutter, referensi fitur/perilaku), `assets/` (logo, font, media reuse),
  dan `frontend-svelte/` (proyek web ini).
- Spec lengkap ada di `../PROMPT_SVELTE_FRONTEND.md` (master prompt).

## Stack & konfigurasi

- SvelteKit 2.63 + Svelte 5 (runes mode dipaksa untuk kode proyek, non-`node_modules`).
- TypeScript strict, `checkJs`, no `any` — semua respons penting pakai DTO + schema Zod.
- Adapter: `@sveltejs/adapter-node` (output `build/index.js`).
- Vite 8, Vitest 4 (dua project test: `client` via Playwright browser, `server` via node).
- E2E: Playwright + `@axe-core/playwright` (a11y gate serious/critical di surface publik).
- Realtime: `laravel-echo` + `pusher-js` (protokol Pusher / Laravel Reverb).
- Ikon: `@lucide/svelte`. Text UI utama: Bahasa Indonesia natural.

## Arsitektur (BFF-first, aman by default)

- Browser memanggil route BFF SvelteKit (`/api/*`), BFF meneruskan bearer ke Laravel.
- Token Sanctum disimpan di cookie `HttpOnly, Secure, SameSite=Lax` — TIDAK di localStorage.
- `src/hooks.server.ts`: session bootstrap, CSRF origin-check untuk method unsafe,
  security headers (Referrer-Policy, X-Content-Type-Options, X-Frame-Options=DENY).
- Reverb pakai private-channel auth lewat BFF; polling hanya fallback.
- Draft composer + media di IndexedDB; preferensi device-only disimpan lokal & dilabeli.
- PWA: cache-first hanya untuk build/static; HTML authenticated & `/api/*` selalu network-only.
- Endpoint eksternal via BFF allowlist: iTunes Search (musik), Nominatim/OSM (lokasi),
  ranking `santriboard.vercel.app` (server-only, di-cache). Store = konten eksternal, jangan
  pakai URL dari input pengguna.

## Struktur direktori (`src/`)

- `lib/api/` — `client.ts` (clientRequest ke `/api/*`, cegah path traversal), `errors.ts`,
  `mappers.ts` (peta respons → model UI). Ada `.spec.ts` menyertai.
- `lib/server/` — `api.ts`, `session.ts`, `forms.ts`, `env.ts` (server-only, jangan bocor ke client).
- `lib/schemas/` — Zod per domain: account, announcement, auth, chat, comment, feed,
  notification, portfolio, post, profile, ranking, story, user.
- `lib/types/domain.ts` — domain types. `lib/realtime/client.ts` — Echo/Reverb.
- `lib/ui/` (progress, confirm), `lib/utils/` (media, time), `lib/story/read-state.ts`.
- `lib/components/` — subfolder: `auth`, `chat`, `composer`, `feed`, `layout`, `profile`,
  `story`, `ui`. Layout inti: `AppShell`, `PageHeader`, `RightRail`, `SectionPage`.
- `routes/(public)/` — welcome, login, register, forgot/reset-password, verify-email, verified-success.
- `routes/(app)/` — shell authenticated: home, explore, posts/[postId], stories/[userId],
  clips/[postId], messages (direct/[userId], groups/[groupId], new), groups, notifications,
  announcements, create (post/story/clips), portfolio, profile (+edit, [connection]),
  u/[username], ranking, settings (password, privacy, sessions, saved, preferences,
  follow-requests, story-archive, delete-account), store.
- `routes/api/` — BFF: `[...path]` (proxy generik), `external/locations`, `external/music`,
  `ranking`. Plus `routes/logout/+server.ts`.
- Konvensi SvelteKit: `+page.svelte` (UI) + `+page.server.ts` (load/actions BFF) berpasangan.

## Dokumentasi (`docs/`)

- `api-contract.md` — method/path/auth/response shape/pagination/error.
- `contract-gaps.md` — ketidaksesuaian Flutter vs Laravel, endpoint eksternal, UI-only.
- `feature-parity-matrix.md` — halaman Flutter → route Svelte + status.
- `information-architecture.md` — sitemap & navigasi (mobile bottom nav, tablet rail, desktop sidebar+right rail).
- `deployment.md`, `security.md`, `definition-of-done.md`.

## Perintah kualitas (jalankan dari `frontend-svelte/`)

```sh
npm run format        # prettier --write
npm run check         # svelte-kit sync + svelte-check
npm run lint          # prettier --check + eslint
npm run test:unit -- --run
npm run test:e2e      # Playwright (unduh chromium pertama kali)
npm audit --omit=dev
npm run build         # adapter-node
```

Target gate: 0 error/warning Svelte, lint bersih, test hijau, 0 vuln production, build sukses.

## Aturan kerja wajib

- Kerjakan HANYA di `frontend-svelte`; jangan rusak Flutter atau Laravel.
- Jangan modif backend kecuali diminta eksplisit; kalau perlu, dokumentasikan patch terpisah.
- Kalau Flutter ≠ backend: ikuti backend, catat di `docs/contract-gaps.md`, buat fallback UI jujur.
  Jangan bikin tombol yang terlihat jalan tapi tak ada implementasi.
- Selesaikan tiap domain vertikal: UI, fetch, validasi, loading, error, empty state,
  optimistic update bila aman, dan test. Jangan berhenti di scaffolding.
- Hindari `any`; semua data dinamis dari API nyata (tidak ada fixture di route production).
- Setelah tiap fase: format, typecheck, lint, test — perbaiki error sebelum lanjut.

## Status saat ini (per definition-of-done, semua ✔)

Auth BFF, feed/pagination/likes/bookmarks/comments/stories/explore/profile/follow/upload/
clips/announcements, DM/group + realtime + polling fallback, settings kritis, portfolio,
ranking, store allowlist, PWA static-only, composer (crop/progress/cancel/draft IndexedDB),
CI workflow (`../.github/workflows/frontend-ci.yml`), dan a11y axe gate — sudah terpasang.
