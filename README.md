# Portal SI

Workspace Portal SI sekarang dirapikan menjadi folder aplikasi aktif:

- `apps/web/` — frontend SvelteKit.
- `apps/api/` — backend Laravel API. Folder ini tetap memakai repository Git sendiri di dalam `apps/api/.git`.

Folder Flutter lama dan artefak build root sudah dikeluarkan dari workspace aktif supaya struktur proyek lebih jelas.

## Perintah cepat

Frontend:

```sh
cd apps/web
npm ci
npm run check
npm run build
```

Backend API:

```sh
cd apps/api
composer install
php artisan migrate
php artisan route:list --path=api
```

## Deploy

Frontend production memakai hook di:

```sh
apps/web/deploy-vps/deploy-after-pull.sh
```

Alur deploy frontend tetap:

```sh
cd /home/app.portalsi.com/public_html
git pull --ff-only
```

Backend API berada di repository terpisah, jadi update/migrasi API tetap dijalankan dari working tree API production yang sesuai.
