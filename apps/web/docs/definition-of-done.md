# Definition of done

## Implementasi

- [x] Backend Laravel dipertahankan sebagai source of truth dan tidak dimodifikasi.
- [x] Phase 0 API contract, gap register, parity matrix, dan IA tersedia.
- [x] Responsive shell dan route utama tersedia untuk mobile/tablet/desktop.
- [x] Auth memakai BFF + cookie HttpOnly; login/register/forgot/verify/logout nyata.
- [x] Feed, pagination, likes, bookmarks, comments/replies, stories, explore, profile, follow, upload, clips, dan announcements memakai API nyata.
- [x] DM/group, attachment, read update, notifications, Reverb cleanup, heartbeat, dan polling fallback tersedia.
- [x] Settings kritis, portfolio, ranking BFF/cache, store allowlist, dan PWA static-only cache tersedia.
- [x] Empty/error/partial-failure state disediakan pada surface utama.
- [x] Group/announcement/post/portfolio owner-management memakai mutasi Laravel nyata.
- [x] Composer memiliki location/music BFF allowlist, crop, progress/cancel, dan draft media IndexedDB.
- [x] Workflow CI menjalankan check, lint, unit, audit, build, dan Chromium E2E.
- [x] Axe memblokir pelanggaran accessibility impact serious/critical pada surface publik utama.

## Gate otomatis

Jalankan dari `apps/web`:

```sh
npm run check
npm run lint
npm run test:unit -- --run
npm run test:e2e
npm audit --omit=dev
npm run build
```

Target: 0 error/warning Svelte, lint bersih, seluruh test hijau, 0 vulnerability production, build adapter-node sukses.

## Gate staging manual

- Login gagal/sukses, verifikasi email, logout ketika backend unavailable.
- Feed partial endpoint failure, pagination, optimistic mutation rollback.
- Upload image/video/story dan upload besar melalui proxy staging.
- Privacy profile, follow accepted/pending, comment/reply, bookmark.
- DM dan group dari dua akun; Reverb disconnect/reconnect dan polling fallback.
- Notification deep link/read-all, portfolio authorization, ranking stale cache.
- Install PWA; pastikan authenticated HTML/API tidak muncul dari offline cache.
- Screen reader labels, keyboard focus, 200% zoom, reduced-motion, dan mobile safe area.

Gate staging memerlukan kredensial/test data dan Reverb key yang tidak disimpan di repository.
