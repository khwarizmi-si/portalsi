# Master Prompt — Frontend Portal SI dengan Svelte

Salin seluruh prompt di bawah ini ke agen coding yang akan mengerjakan frontend.

---

## Peran dan tujuan utama

Anda adalah lead frontend engineer, product designer, dan QA engineer. Bangun frontend web baru **Portal SI** yang lengkap, production-ready, responsif, dan memakai **SvelteKit + TypeScript**. Frontend harus mengambil fitur, alur bisnis, model data, dan perilaku dari aplikasi Flutter yang sudah ada, lalu mengintegrasikannya dengan backend Laravel yang tersedia di repository ini.

Jangan membuat demo statis, mock-only, atau sekadar kumpulan halaman. Hasil akhir harus berupa aplikasi web yang benar-benar terhubung ke API, dapat dibangun, diuji, dan dideploy.

## Lokasi source of truth

Working directory repository: `D:\Projects\psi-app`

Gunakan sumber berikut dengan urutan prioritas:

1. `api-portalsi/routes/api.php`, controller, model, event, dan channel Laravel adalah sumber kebenaran utama untuk kontrak API dan otorisasi.
2. `lib/services`, `lib/controllers`, `lib/models`, dan `lib/providers` adalah referensi perilaku client, mapping data, cache, pagination, serta realtime.
3. `lib/pages`, `lib/components`, dan `lib/widgets` adalah referensi fitur, navigasi, state UI, serta interaksi aplikasi Flutter.
4. `assets` adalah sumber logo, ilustrasi, font, background, emoji, dan media visual yang boleh dipakai ulang.

Jika Flutter dan backend berbeda, jangan menebak. Ikuti backend yang benar-benar tersedia, catat perbedaannya di `docs/contract-gaps.md`, dan buat fallback UI yang jujur. Jangan membuat tombol yang terlihat berfungsi tetapi tidak punya implementasi.

## Aturan kerja wajib

- Kerjakan frontend baru di folder `frontend-svelte` tanpa merusak Flutter atau backend Laravel.
- Jangan mengubah backend kecuali diminta secara eksplisit. Jika perubahan backend diperlukan, dokumentasikan usulan patch secara terpisah.
- Gunakan SvelteKit, TypeScript strict, semantic HTML, dan komponen Svelte idiomatis. Jangan membawa pola Flutter mentah ke web.
- Gunakan package versi stabil yang kompatibel pada saat implementasi. Jangan memakai dependency eksperimental tanpa alasan kuat.
- Hindari `any`; definisikan DTO dan schema runtime untuk seluruh respons penting.
- Seluruh teks UI utama memakai Bahasa Indonesia yang natural dan konsisten dengan aplikasi lama.
- Semua data dinamis harus berasal dari API nyata. Mock hanya boleh dipakai pada tahap prototype desain dan harus mudah diganti/dihapus.
- Jangan berhenti pada scaffolding. Selesaikan setiap domain secara vertikal: UI, fetch, validasi, loading, error, empty state, optimistic update bila aman, dan test.
- Setelah setiap fase, jalankan formatter, typecheck, lint, dan test terkait; perbaiki error sebelum lanjut.

## Fase 0 — audit sebelum menulis UI

Sebelum implementasi, lakukan audit repository dan buat:

- `docs/feature-parity-matrix.md`: semua halaman Flutter, tujuan, route Svelte, endpoint, role, status implementasi, dan catatan gap.
- `docs/api-contract.md`: method, path, auth, verified-only, query/body/form-data, response shape, pagination, dan error code.
- `docs/contract-gaps.md`: ketidaksesuaian Flutter versus Laravel, endpoint eksternal, UI-only, atau fitur backend yang belum lengkap.
- `docs/information-architecture.md`: sitemap dan alur navigasi desktop/mobile.

Jangan hanya membaca nama file. Baca controller Laravel untuk validasi input dan bentuk respons, model/event untuk field dan realtime, serta service/model Flutter untuk normalisasi data.

Gap yang sudah terlihat dan wajib diverifikasi:

- Flutter memiliki pemanggilan FCM `/device-tokens`, sedangkan backend yang tampak tersedia memiliki `POST /api/fcm/register`.
- Beberapa pengaturan Story/Close Friends/Camera tampak local atau UI-only dan mungkin belum punya endpoint.
- Ranking memakai API eksternal `https://santriboard.vercel.app/api/student/leaderboard`.
- Music picker memakai iTunes Search API dan lokasi memakai Nominatim/OpenStreetMap.
- Store adalah konten eksternal/WebView menuju `https://store.portalsi.com/`; buat pengalaman web yang aman dan jangan menyalin URL dari input pengguna.
- Akun RG SSO di Flutter mengandung alur client yang tidak boleh menaruh client secret di browser. Tandai sebagai kebutuhan backend/BFF bila belum aman.

## Fase 1 — desain harus dibuat terlebih dahulu

Sebelum menghubungkan seluruh API, buat design foundation dan prototype halaman inti dengan data fixture yang typed. Desain harus terasa seperti media sosial modern yang hangat, bersih, premium, dan khas Portal SI—bukan clone mentah Instagram.

### Arah visual

- Light mode saja untuk versi awal.
- Latar utama off-white hangat, surface putih, teks charcoal, aksen amber/oranye sebagai primary, teal/hijau sebagai secondary, merah hanya untuk destructive/error.
- Gunakan font Alan Sans dari `assets/fonts/AlanSans-VariableFont_wght.ttf` bila lisensi dan rendering sesuai; siapkan system fallback.
- Gunakan logo Portal SI yang sudah tersedia di `assets`.
- Hindari gradient berlebihan, glassmorphism berat, shadow pekat, dan border-radius raksasa di semua elemen.
- Gunakan spacing 4/8-point, radius konsisten, border halus, shadow lembut, dan hierarchy tipografi yang jelas.
- Ikon harus konsisten dari satu icon set dan memiliki accessible label/tooltip.
- Animasi singkat 150–250 ms, halus, tidak menghambat, dan mematuhi `prefers-reduced-motion`.

### Design tokens minimum

Buat CSS custom properties untuk warna, typography, spacing, radius, shadow, z-index, breakpoint, focus ring, container width, dan safe-area. Jangan menyebar magic values.

Contoh arah warna yang boleh disempurnakan setelah cek logo:

- canvas: `#FFFDF8`
- surface: `#FFFFFF`
- text: `#1F2933`
- muted: `#667085`
- border: `#E8E6E1`
- primary: amber/oranye Portal SI
- secondary: teal Portal SI
- danger: `#D92D20`

Pastikan rasio kontras WCAG AA.

### Layout responsif

- Mobile `< 768px`: top bar ringkas, bottom navigation fixed dengan safe-area, tombol create di tengah, full-width feed, sheet untuk aksi sekunder.
- Tablet `768–1199px`: sidebar ikon atau nav kompak, content column terpusat, panel sekunder opsional.
- Desktop `>= 1200px`: sidebar kiri sticky, kolom konten utama maksimal sekitar 680 px, right rail untuk pengumuman, saran pengguna, status online, atau konteks halaman.
- Jangan sekadar memperbesar tampilan mobile. Gunakan layout yang memang nyaman untuk mouse, keyboard, dan viewport lebar.
- Media feed menjaga aspect ratio; images memakai responsive `srcset` jika tersedia dan video tidak menyebabkan layout shift.

### Navigasi utama

Pertahankan konsep Flutter: Beranda, Jelajah, Create, Store, Profil. Tambahkan akses jelas ke Pesan dan Notifikasi. Pada desktop gunakan sidebar; pada mobile gunakan bottom nav. Tombol Create membuka menu sesuai role:

- Buat Postingan
- Upload Clips
- Upload Cerita
- Buat Pengumuman hanya untuk `dev` atau `teacher`

### Prototype desain wajib

Buat terlebih dahulu route dan komponen visual untuk:

1. Login/register/forgot password.
2. App shell desktop, tablet, mobile.
3. Beranda dengan story rail, pinned announcement, feed post, suggestion, skeleton/loading/error/empty state.
4. Jelajah dengan search/filter dan responsive media grid.
5. Post detail dan comment thread.
6. Story viewer.
7. Clips viewer vertikal.
8. Inbox, direct chat, dan group chat.
9. Profil sendiri dan profil pengguna lain.
10. Composer create post/story/clips.
11. Notifikasi.
12. Pengaturan akun.

Ambil screenshot viewport mobile 390×844, tablet 820×1180, dan desktop 1440×1000. Periksa overflow, focus state, empty state, loading state, dan konsistensi. Setelah design foundation matang, baru lanjutkan integrasi seluruh domain.

## Arsitektur teknis

### Stack

- SvelteKit + TypeScript strict.
- Styling dengan Tailwind CSS atau CSS modules/global tokens; pilih satu pendekatan dan konsisten. Design tokens tetap memakai CSS variables.
- Runtime schema validation dengan Zod atau library setara.
- Form handling dengan SvelteKit actions dan progressive enhancement bila cocok.
- Test unit/component dengan Vitest dan Testing Library; browser/E2E dengan Playwright.
- ESLint, Prettier, dan pemeriksaan aksesibilitas Svelte aktif.
- Adapter deployment yang sesuai target production; default aman adalah adapter Node dengan reverse proxy/BFF.

### Struktur yang diharapkan

```text
frontend-svelte/
  src/
    lib/
      api/
      auth/
      components/
        ui/
        layout/
        feed/
        story/
        chat/
        profile/
      features/
      schemas/
      stores/
      realtime/
      utils/
      types/
    routes/
      (public)/
      (app)/
      api/               # BFF/proxy bila digunakan
    app.css
  static/
  tests/
  docs/
  .env.example
```

### Konfigurasi environment

Sediakan dan dokumentasikan paling tidak:

```env
PUBLIC_APP_NAME=Portal SI
API_BASE_URL=https://api.portalsi.com
PUBLIC_MEDIA_BASE_URL=https://api.portalsi.com/storage
PUBLIC_REVERB_HOST=ws.portalsi.com
PUBLIC_REVERB_PORT=443
PUBLIC_REVERB_SCHEME=wss
PUBLIC_REVERB_APP_KEY=...
```

Jangan commit secret. Jangan mengekspos Laravel/Reverb secret atau Akun RG client secret sebagai `PUBLIC_*`.

### Authentication dan keamanan

Backend login mengembalikan Laravel Sanctum personal access token. Gunakan arsitektur BFF SvelteKit bila target deployment mendukung server runtime: simpan token di cookie `HttpOnly`, `Secure`, `SameSite=Lax`, lalu proxy request API dari server. Jangan menyimpan access token mentah di localStorage untuk mode production.

Implementasikan:

- register, login username/email, logout;
- bootstrap session dengan `GET /api/user`;
- resend verification dan pesan cooldown;
- bind email bila akun belum punya email;
- forgot/reset password;
- route guard public/authenticated/verified-only;
- role guard untuk `student`, `parent`, `teacher`, `dev`;
- penanganan 401 menghapus session dan menuju login;
- 403 verified-only menampilkan CTA verifikasi, bukan error generik;
- 422 memetakan validation errors ke field;
- 429 menampilkan retry/cooldown;
- open redirect, XSS, file upload, dan URL media harus divalidasi.

Jika harus mendukung static hosting tanpa BFF, dokumentasikan tradeoff dan buat adapter auth terpisah. Jangan diam-diam menurunkan keamanan.

### API client

Buat satu typed API client, bukan `fetch` acak di setiap komponen. Client harus menangani:

- base URL dan path normalization;
- `Accept: application/json`, bearer/session auth, JSON dan multipart;
- query serialization;
- timeout/abort dengan `AbortController`;
- error object konsisten berisi status, code, message, field errors, dan request id bila ada;
- pagination Laravel termasuk `current_page`, `last_page`, `next_page_url`, dan variasi response yang benar-benar ditemukan;
- deduplication/cancellation request saat search;
- retry terbatas hanya untuk request idempotent dan network error;
- media URL absolut/relatif serta placeholder rusak;
- optimistic update dengan rollback untuk like, bookmark, follow, dan read state;
- tidak melakukan retry otomatis pada mutation non-idempotent.

## Route dan fitur yang wajib tercakup

Nama URL Svelte boleh dirapikan, tetapi semua kemampuan berikut harus ada.

### Public dan onboarding

- Splash/session bootstrap dan welcome.
- Login username atau email.
- Register dengan username, nama lengkap, email, password, role yang diizinkan.
- Verifikasi email, resend verification, cooldown, missing-email state.
- Forgot password dan reset password dari token/link.
- Public profile dari `GET /api/profile/{username}` dengan aturan privasi backend.
- Halaman verified success yang sesuai redirect backend.

### Beranda dan postingan

- Feed paginated/infinite scroll, pull/explicit refresh, dedupe item, restore scroll.
- Story rail termasuk own story/create state dan seen/unseen indicator.
- Pinned announcements dan daftar pengumuman.
- Post image/video/clips, multiple media bila respons API mendukung, caption, mention, tag, lokasi, musik, timestamp, verified badge.
- Like/unlike toggle dan daftar liker.
- Bookmark/unbookmark dan daftar saved posts.
- Comment/reply bertingkat, mention, edit/delete milik sendiri, like/unlike komentar.
- Share post memakai Web Share API dan copy link fallback.
- Detail post yang deep-linkable.
- Edit/delete post sesuai pemilik.
- Create post multipart dengan preview, reorder/crop seperlunya, caption, tag user, lokasi, musik, upload progress, cancel, dan validation.
- Draft composer lokal dengan IndexedDB; beri label jelas karena draft bukan endpoint backend.

### Story

- Feed story per pengguna, story milik sendiri, dan archive.
- Viewer dengan progress bars, pause saat pointer hold, keyboard navigation, swipe/tap zone di mobile, mute, loading media, dan graceful error.
- Catat view tepat sekali sesuai endpoint.
- Viewers list hanya untuk pemilik bila diizinkan.
- Create image/video story multipart dan field musik/overlay yang benar-benar didukung backend.
- Mention rendering dan navigasi ke profile.
- Delete own story.
- Pengaturan story yang tidak punya endpoint harus ditandai local-only atau tidak ditampilkan; jangan menjanjikan sinkronisasi server.

### Jelajah dan clips

- Explore grid paginated dengan skeleton dan aspect ratio stabil.
- Search pengguna dengan debounce, cancellation, recent search lokal, serta filter yang memang didukung API.
- Preview post dari grid dan navigasi deep link.
- Full-screen clips viewer vertikal, autoplay hanya item aktif, pause saat tab tidak aktif, mute state, play/pause, progress, caption, profile, like, comment, share, bookmark.
- Gunakan IntersectionObserver; jangan menjalankan seluruh video sekaligus.
- Create/upload clips menggunakan kontrak post backend, dengan validasi format/durasi/ukuran dari controller.
- Editor video web tidak boleh pura-pura lengkap: gunakan capability browser yang nyata dan tampilkan batasan bila fitur Flutter native tidak mungkin sama persis.

### Profil dan social graph

- Profil sendiri: avatar, banner, nama, username, bio, role, verified badge, counts, posts grid, clips, dan portfolio bila ada.
- Profil pengguna lain: follow/unfollow, pending request untuk akun privat, mutuals, message, followers/following, post grid, privacy state.
- Pending follower requests: list, accept, reject.
- Suggestions.
- Edit profile multipart termasuk avatar/banner preview dan field backend.
- Account privacy berdasarkan kontrak nyata.
- Share profile dengan Web Share API/copy link; QR/card hanya jika benar-benar diimplementasikan.

### Pesan langsung

- Chat list gabungan direct/group seperti perilaku Flutter, search, unread badge, timestamp, avatar, online indicator.
- Mulai pesan baru dari user search.
- Direct conversation paginated bila API mendukung; load older messages tanpa scroll jump.
- Kirim text/media, story response, mention/link rendering bila relevan, optimistic pending/sent/failed status, retry manual.
- Mark single/conversation read, unread count, delete own message sesuai backend.
- Chat info dan shared media/link yang dapat diturunkan dari data aktual.
- Responsif: desktop memakai split-pane inbox/conversation; mobile memakai route terpisah.

### Grup

- Create group dengan name, description, avatar, cover, dan members.
- Daftar special groups khusus `parent`/`teacher`.
- Join/leave/show/edit/delete group sesuai role.
- Group conversation: text/media, reply, mention, pin/unpin, read info, unread, delete.
- Group info dan members.
- Owner/admin actions: add/remove member, promote, demote, mute, unmute.
- Seluruh tombol harus disembunyikan atau disabled berdasarkan role hasil API, bukan hanya asumsi client.

### Notifikasi dan realtime

- Notification list paginated, unread state, mark one/all read, navigasi berdasarkan type dan entity.
- Laravel Reverb/Pusher protocol terhubung ke host yang dikonfigurasi.
- Auth private/presence channel melalui endpoint broadcasting auth yang benar.
- Tangani channel/event yang ditemukan di `routes/channels.php` dan `app/Events`, termasuk user notifications, direct messages, group messages/member changes, post like/comment, follow, story, online status, announcement, dan chat list update.
- Event realtime harus memperbarui cache/store tanpa duplikasi.
- Reconnect memakai exponential backoff + jitter, resubscribe channel, heartbeat/activity, offline banner, dan cleanup subscription ketika route/component unmount.
- Jangan hardcode event name sebelum membaca `broadcastAs()`.
- Fallback polling boleh digunakan hanya bila realtime gagal dan harus dihentikan saat koneksi pulih.

### Pengumuman

- List dan pinned announcement.
- Detail/media preview.
- Create/edit/delete hanya `teacher` atau `dev` sesuai perilaku dan otorisasi backend.
- Pin state, schedule/time fields, dan media hanya jika ada dalam kontrak controller/model.

### Portfolio dan ranking

- Portfolio kategori `quran`, `it`, `bahasa`, `karakter`.
- List berdasarkan user/aspect.
- Create/update/delete portfolio multipart dengan title, description, year, aspect, media, dan izin berdasarkan backend.
- Ranking dari API eksternal Santriboard, search, refresh, cache dengan stale fallback, loading/error/empty state.
- Kegagalan third-party API tidak boleh menjatuhkan seluruh app.

### Store

- Gunakan URL store aktual dari Flutter: `https://store.portalsi.com/`.
- Pada web, lebih baik tampilkan landing/embed yang aman atau buka origin eksternal dengan indikator yang jelas.
- Terapkan allowlist origin, `rel="noopener noreferrer"`, CSP/frame policy yang sesuai, loading/error state, dan jangan mengeksekusi URL arbitrer.

### Settings

- Account settings dan edit profile.
- Account privacy jika endpoint mendukung update; jika backend hanya menyediakan status read, catat gap dan jangan membuat toggle palsu.
- Change password.
- Login history dan revoke/delete session history sesuai endpoint.
- Saved posts.
- Archived stories.
- Logout.
- Delete account dengan re-auth/confirmation yang kuat sesuai backend.
- Local preferences yang masuk akal: mute default, reduced data/video autoplay, dismissed education dialogs.

## Endpoint inventory minimum yang harus dipetakan

Verifikasi ulang langsung dari `api-portalsi/routes/api.php`; daftar ini adalah baseline, bukan pengganti membaca controller.

### Public

`POST /register`, `POST /login-check`, `POST /register-teachers`, `POST /register-parent`, `POST /login`, `POST /fcm/register`, `GET /email/verify/{id}/{hash}`, `POST /email/verification-notification`, `POST /email/resend-verification`, `POST /forgot-password`, `POST /reset-password`, `POST /bind-email`, `GET /profile/{username}`.

### Authenticated read/common

`POST /logout`, `GET /user`, `GET /account/is-private`, `GET /mutuals`, `GET /posts`, `GET /posts/{id}`, `GET /posts/{post_id}/likes`, `GET /posts/{post_id}/comments`, `GET /users/{id}/followers`, `GET /users/{id}/following`, `GET /users/search`, `GET /stories/feed`, `GET /stories/feed/user/{userId}`, `GET /stories/my`, `GET /notifications`, `PATCH /notifications/{id}/read`, `PATCH /notifications/read/all`, `GET /explore`, `GET /circle-avatar/{id}`, `GET /clips/{id}`, `GET /announcements`, `GET /announcements/pinned`.

### Direct message dan history

`GET /messages/conversation/{user_id}`, `POST /messages/send`, `PATCH /messages/{id}/read`, `PATCH /messages/user/{user_id}/read`, `DELETE /messages/{id}`, `GET /messages/chat-list`, `GET /messages/unread/{user_id}`, `GET /messages/conversation-from/{user_id}`, `GET /messages/channels`, `GET /login-histories`, `DELETE /login-histories/{id}`.

### Bookmark, follow request, special group, online

`GET /bookmarks`, `POST /bookmarks/{postId}`, `DELETE /bookmarks/{postId}`, `POST /followers/{follower_id}/accept`, `POST /followers/{follower_id}/reject`, `GET /followers/pending`, `GET /special-groups`, `POST /websocket/authenticate`, `POST /websocket/disconnect`, `GET /websocket/online-status/{userId}`, `GET /websocket/online-followers`, `GET /websocket/online-count`, `POST /websocket/update-activity`.

### Verified-only mutations

`POST /posts`, `POST /posts/{id}/update`, `DELETE /posts/{id}`, `POST /posts/{post_id}/like`, `POST /posts/{post_id}/comments`, `PUT /comments/{id}`, `DELETE /comments/{id}`, `POST /comments/{comment_id}/like`, `DELETE /comments/{comment_id}/like`, `POST /follow/{id}`, `DELETE /unfollow/{id}`, `POST /stories`, `DELETE /stories/{id}`, `POST /stories/{id}/view`, `GET /stories/{id}/viewers`, `GET /stories/user/{userId}`, `GET /stories/my/archived`, `GET /suggestions`, `POST /account/settings`, `PUT /account/password`, `DELETE /account/delete`, announcement CRUD, group CRUD/membership/message actions, dan portfolio CRUD.

Perhatikan bahwa update group memakai `Route::match(['put','post'], 'groups/{group}', ...)` dan beberapa update media memakai POST karena multipart method handling. Ikuti backend, jangan “merapikan” method dari sisi client tanpa dukungan server.

## State dan UX standar setiap fitur

Setiap data surface harus memiliki:

- initial loading skeleton yang menyerupai layout akhir;
- empty state yang spesifik dan actionable;
- inline error yang ramah + retry;
- offline/stale indicator bila menampilkan cache;
- pagination end state;
- disabled/loading state pada tombol mutation;
- toast untuk hasil global, field error untuk validasi form;
- confirmation dialog untuk destructive action;
- optimistic update hanya ketika rollback aman;
- pencegahan double-submit;
- preservasi focus dan scroll saat modal/sheet ditutup;
- URL yang deep-linkable untuk profile, post, clips, dan conversation bila aman.

Gunakan IndexedDB untuk draft/cache media ringan bila diperlukan, bukan localStorage untuk payload besar. Bersihkan object URL dan listener untuk mencegah memory leak.

## Accessibility

- Target WCAG 2.2 AA.
- Semua fitur inti dapat dipakai dengan keyboard.
- Focus ring terlihat; modal memiliki focus trap dan mengembalikan focus ke trigger.
- Feed/story/clips memiliki label dan kontrol yang dapat dibaca screen reader.
- Alt text dan fallback media masuk akal.
- Jangan mengandalkan warna saja untuk status.
- Minimum touch target sekitar 44×44 px.
- Gunakan `aria-live` secara hemat untuk upload, error, dan pesan baru.
- Caption/video control tersedia bila sumber data mendukung.

## Performance

- Route-level code splitting dan lazy-load fitur berat.
- Lazy-load image/video di luar viewport; preload hanya konten yang benar-benar berikutnya.
- Virtualisasi list hanya bila data besar dan aksesibilitas tetap baik.
- Hindari waterfall request; paralelkan request independen.
- Batasi store global; state server/cache tidak dicampur dengan transient UI state.
- Gunakan responsive image, kompresi client sebelum upload bila kualitas tetap aman, dan tampilkan upload progress.
- Tidak boleh ada CLS besar, autoplay semua video, event listener bocor, atau fetch berulang akibat reactive loop.
- Tetapkan budget dan cek hasil build: bundle route awal, LCP, CLS, INP, dan penggunaan network di koneksi lambat.

## SEO dan PWA

- Public profile dan halaman publik yang memang diizinkan harus memiliki title, description, canonical, dan Open Graph yang aman.
- Halaman private diberi `noindex` dan tidak membocorkan data lewat SSR cache.
- Sediakan manifest, icon dari aset yang ada, theme color, dan install metadata.
- Service worker hanya meng-cache app shell dan aset aman. Jangan cache respons private lintas user.
- Offline mutation queue tidak wajib; jangan mengirim mutation lama secara mengejutkan tanpa persetujuan user.

## Security hardening

- Terapkan CSP, frame-ancestors, referrer policy, permissions policy, dan secure headers di layer yang sesuai.
- Sanitasi rich text/mention/link. Caption dan chat default sebagai text, bukan raw HTML.
- Allowlist tipe MIME dan ukuran file berdasarkan controller; jangan percaya extension.
- Jangan memasukkan token, secret, data akun, atau isi chat ke log/error analytics.
- Hindari SSR cache untuk respons authenticated.
- Proteksi CSRF pada BFF action dan cookie session.
- Validasi seluruh external URL dan media origin.
- Dependency audit harus bersih dari kerentanan high/critical yang relevan.

## Testing wajib

### Unit/component

- API client error mapping, pagination, URL media, dan auth expiry.
- DTO/schema parsing untuk user, post, story, comment, notification, chat, group, portfolio.
- Role/verified guards.
- Optimistic like/bookmark/follow rollback.
- Mention/link formatter dan waktu relatif.
- Komponen post card, comment thread, story progress, upload form, chat composer.

### Integration/E2E

Gunakan API nyata untuk smoke test environment yang aman atau intercept kontrak dari fixture yang berasal dari response nyata. Cakup:

1. Register/login/logout dan invalid credential.
2. Unverified user terblokir mutation dan mendapat CTA tepat.
3. Feed load/pagination/detail.
4. Like, comment/reply, bookmark.
5. Follow public/private dan accept/reject request.
6. Create/edit/delete post dengan upload.
7. Story create/view/viewers/delete.
8. Direct message send/read/delete dan reconnect realtime.
9. Group create/member role/chat/pin/read info.
10. Notification mark one/all.
11. Profile edit avatar/banner.
12. Portfolio CRUD.
13. Password change, login history, logout.
14. Responsive navigation di mobile dan desktop.
15. Keyboard-only smoke test dan automated accessibility scan.

Test tidak boleh bergantung pada urutan data production. Jangan menjalankan destructive test terhadap akun/data production.

## Observability dan error handling

- Sediakan global error boundary yang tidak membocorkan stack trace ke user.
- Log client secara terstruktur di development; production hanya metadata aman.
- Integrasi error monitoring opsional melalui env, dengan scrub data sensitif.
- Tampilkan request/correlation id jika backend memberikannya.
- Ukur Web Vitals tanpa merekam caption, chat, token, atau PII.

## Dokumentasi dan deployment

Sediakan:

- `README.md` berisi prerequisites, install, env, dev, test, build, preview, dan deploy.
- `.env.example` tanpa secret.
- Penjelasan arsitektur auth/BFF dan realtime.
- `docs/feature-parity-matrix.md` dengan seluruh baris berstatus selesai, gap sah, atau ditunda beserta alasan.
- `docs/api-contract.md` hasil verifikasi controller, bukan hasil tebakan.
- `docs/deployment.md` untuk reverse proxy, HTTPS, WebSocket upgrade, CORS/cookie, CSP, dan rollback.
- Health/readiness strategy dan smoke test setelah deploy.

Build production harus reproducible dari lockfile. CI minimum menjalankan install bersih, format check, lint, Svelte check/typecheck, unit/component test, build, dan E2E smoke.

## Definition of Done

Pekerjaan hanya boleh dinyatakan selesai bila:

- Semua halaman dan alur aktif Flutter sudah masuk parity matrix.
- Semua route backend yang relevan sudah dipetakan; tidak ada endpoint karangan.
- Desain light-mode konsisten dan sudah diverifikasi pada tiga viewport.
- Seluruh fitur inti memakai API nyata, bukan fixture.
- Auth, verified-only, role permission, upload, pagination, error, dan realtime berfungsi.
- Tidak ada tombol mati, TODO utama, placeholder API, hardcoded user/token, atau secret client.
- Refresh browser pada deep link tetap berfungsi.
- Typecheck, lint, test, dan production build lulus tanpa error.
- E2E jalur kritis lulus.
- Audit aksesibilitas tidak memiliki pelanggaran critical/serious pada jalur utama.
- Tidak ada kerentanan high/critical yang relevan dan belum dijelaskan.
- README dan deployment docs cukup untuk engineer lain menjalankan aplikasi dari nol.

## Format laporan selama pengerjaan

Pada setiap milestone, laporkan secara singkat:

1. Apa yang selesai.
2. File/route yang berubah.
3. Endpoint yang sudah terhubung.
4. Test/check yang dijalankan dan hasilnya.
5. Contract gap atau risiko yang ditemukan.
6. Langkah berikutnya.

Mulai sekarang dari Fase 0. Setelah audit, bangun Fase 1 desain terlebih dahulu. Jangan langsung membuat semua halaman generik sebelum app shell, design tokens, dan prototype inti tervalidasi secara visual.

---

## Catatan untuk pemberi tugas

Prompt ini sengaja menjadikan backend Laravel sebagai kontrak utama, karena beberapa service/layar Flutter tidak sepenuhnya sejalan dengan route backend. Dengan demikian hasil Svelte dituntut setara secara fitur, tetapi tidak mengabadikan bug atau endpoint lama yang sudah tidak tersedia.
