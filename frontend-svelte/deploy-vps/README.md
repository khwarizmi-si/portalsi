# Deploy Portal SI di Contabo + CyberPanel

Frontend ini memakai SvelteKit `adapter-node`, bukan static hosting. Semua request domain
harus diteruskan OpenLiteSpeed ke proses Node di `127.0.0.1:3000`.

## Instalasi pertama

```bash
cd /home/app.portalsi.com/public_html
git clone URL_REPOSITORY_ANDA .
cd frontend-svelte
cp .env.example .env.production
nano .env.production
```

Nilai production minimum:

```env
API_BASE_URL=https://api.portalsi.com
PUBLIC_MEDIA_BASE_URL=https://api.portalsi.com/storage
HOST=127.0.0.1
PORT=3000
ORIGIN=https://app.portalsi.com
BODY_SIZE_LIMIT=512M
NODE_ENV=production
```

Pasang Node.js 24 dan PM2, lalu deploy pertama:

```bash
sudo apt-get update
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2
cd /home/app.portalsi.com/public_html
chmod +x frontend-svelte/deploy-vps/*.sh
frontend-svelte/deploy-vps/deploy-after-pull.sh
pm2 startup
# Jalankan perintah sudo yang dicetak PM2, lalu:
pm2 save
```

Di CyberPanel, buka **Websites → List Websites → Manage → vHost Conf** untuk
`app.portalsi.com`, lalu tambahkan isi `vhost-proxy.conf`. Restart OpenLiteSpeed:

```bash
sudo systemctl restart lsws
curl -I https://app.portalsi.com
```

Pastikan SSL domain sudah diterbitkan dari CyberPanel.

## Otomatis setelah git pull

Pasang hook satu kali:

```bash
cd /home/app.portalsi.com/public_html
frontend-svelte/deploy-vps/install-post-merge-hook.sh
```

Berikutnya cukup:

```bash
cd /home/app.portalsi.com/public_html
git pull --ff-only
```

Hook menjalankan `npm ci`, build, lalu restart PM2 hanya bila build berhasil. Jika build
gagal, proses production lama tetap berjalan. Log dapat diperiksa dengan:

```bash
pm2 status
pm2 logs portalsi-web --lines 100
```

Hook `post-merge` berjalan untuk pull yang menghasilkan merge atau fast-forward. Untuk
deployment berbasis push tanpa login VPS, gunakan webhook/CI dengan SSH yang menjalankan
perintah `git pull --ff-only` di atas.
