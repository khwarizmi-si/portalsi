# Deployment Portal SI Web

## Runtime

- Node.js 24/LTS, `npm ci`, lalu `npm run build`.
- Jalankan `node build/index.js` di belakang reverse proxy HTTPS. Contoh environment runtime: `HOST=127.0.0.1`, `PORT=3000`, `ORIGIN=https://portalsi.com`.
- Health check dapat memakai `GET /welcome`; jangan memakai route authenticated karena route tersebut memanggil Laravel.

## Environment

| Variabel                                 | Sifat       | Keterangan                                                                   |
| ---------------------------------------- | ----------- | ---------------------------------------------------------------------------- |
| `API_BASE_URL`                           | server-only | Origin Laravel tanpa suffix `/api`.                                          |
| `PUBLIC_MEDIA_BASE_URL`                  | public      | Base URL storage media.                                                      |
| `PUBLIC_REVERB_HOST/PORT/SCHEME/APP_KEY` | public      | Kredensial public Reverb/Pusher protocol; secret tidak pernah masuk browser. |
| `RANKING_API_URL`                        | server-only | Endpoint leaderboard HTTPS yang diakses BFF.                                 |

## Reverse proxy

- Terminasi TLS; teruskan `Host`, `X-Forwarded-Proto`, dan alamat client yang tepercaya.
- Set batas request setidaknya 500 MB bila upload maksimum backend memang ingin dipertahankan. BFF meneruskan body sebagai stream; proxy dan Laravel tetap menjadi penegak batas final.
- Timeout upload perlu lebih panjang dari request JSON biasa. WebSocket Reverb harus mengizinkan HTTP upgrade pada host yang dikonfigurasi.
- Jangan cache response ber-cookie, `/api/*`, HTML authenticated, atau response dengan `Cache-Control: private, no-store`.

## Release dan rollback

1. Jalankan `npm ci`, check, lint, unit, E2E, audit production dependency, dan build.
2. Deploy direktori `build` serta `static` secara atomik.
3. Smoke test welcome, login redirect, BFF 401, login nyata di staging, upload kecil, DM, dan private-channel auth.
4. Rollback dengan mengganti symlink/image ke build sebelumnya; tidak ada migrasi database dari frontend ini.
