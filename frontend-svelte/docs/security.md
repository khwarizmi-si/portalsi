# Security notes

## Boundary dan session

- Token Sanctum hanya berada dalam cookie `HttpOnly`, `Secure` (production), `SameSite=Lax`; browser memanggil same-origin BFF dan tidak menerima bearer token.
- Unsafe request menolak `Origin` lintas origin. Cookie SameSite, CSP `form-action 'self'`, dan route BFF same-origin menjadi lapisan CSRF tambahan.
- BFF hanya menerima path relatif, menolak traversal/backslash/absolute URL, meneruskan subset header, memakai timeout, dan tidak mengikuti redirect backend.
- Response authenticated dan semua response BFF memakai `private, no-store`; service worker tidak menyimpan HTML atau API response.

## Browser policy

- CSP membatasi default/script/style/connect/frame/object/base/form; frame embedding ditolak.
- `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, dan request ID dipasang terpusat.
- Media remote hanya dirender sebagai URL HTTP(S) yang dinormalisasi; store external memakai origin tetap dan `noopener noreferrer`.

## Upload dan data

- Client melakukan pemeriksaan tipe/ukuran untuk UX, tetapi Laravel tetap source of truth untuk validasi dan otorisasi.
- BFF meneruskan upload sebagai stream agar file besar tidak dibuffer seluruhnya di heap Node.
- Draft caption dan preferensi lokal tidak berisi token. Chat, caption authenticated, dan response user tidak ditulis ke Cache Storage.

## Realtime

- Private-channel auth menuju `/api/broadcasting/auth` melalui cookie BFF. Channel ditinggalkan dan handler dilepas saat component unmount.
- Connection melakukan heartbeat aktivitas, memakai reconnect Pusher, dedupe entity melalui refresh, dan mengaktifkan polling fallback hanya ketika socket tidak connected.
- `PUBLIC_REVERB_APP_KEY` memang public; `REVERB_APP_SECRET` tidak boleh berada di environment frontend.

## Known backend contract risks

Lihat [contract-gaps.md](contract-gaps.md), khususnya endpoint registrasi khusus, status follow pending yang tidak tersedia di profile response, dan otorisasi portfolio berbasis badge/role.
