# Tutorial Lengkap: Perbaiki 503 & Deploy Bersih Portal SI Web (Contabo + CyberPanel)

Dokumen ini menjelaskan **penyebab error 503**, cara memperbaikinya di server yang sudah
terlanjur terpasang, dan cara **deploy bersih dari nol** yang otomatis untuk `git pull`
berikutnya. Semua perintah dijalankan sebagai `root` (atau `sudo`) di VPS.

Domain: `app.portalsi.com` · Root aplikasi: `/home/app.portalsi.com/public_html`
Frontend: SvelteKit `adapter-node` (BUKAN static hosting) yang berjalan sebagai proses
Node di `127.0.0.1:3100`, dan OpenLiteSpeed mem-*proxy* semua request ke port itu.

---

## 1. Kenapa muncul 503 Service Unavailable

503 di OpenLiteSpeed/CyberPanel untuk situs reverse-proxy artinya **web server berhasil
menerima request, tapi tidak bisa menghubungi backend Node**. Dalam repo ini penyebab
paling umum ada di **ketidakcocokan PORT**:

- `vhost-proxy.conf` menyuruh OpenLiteSpeed mem-proxy ke `127.0.0.1:3100`.
- Tetapi README lama menyuruh mengisi `.env.production` dengan `PORT=3000`.

Akibatnya Node mendengarkan di `3000`, sementara proxy menembak `3100` — tidak ada yang
menjawab di `3100` → **503**. Repo sekarang sudah **diseragamkan ke 3100** di semua file,
jadi selama `.env.production` Anda juga `PORT=3100`, masalah ini hilang.

Penyebab 503 lain yang perlu dicek (urutan diagnosa ada di bagian 2):

1. Proses Node tidak berjalan (PM2 `errored`/`stopped`, atau belum pernah di-`start`).
2. `.env.production` belum ada → skrip deploy berhenti sebelum menjalankan Node.
3. Blok proxy belum tersimpan di vHost Conf, atau `lsws` belum di-restart.
4. Node berjalan tapi di port berbeda dari `address` di `vhost-proxy.conf`.
5. Build gagal, sehingga `build/index.js` tidak ada / proses lama mati.

---

## 2. Diagnosa cepat (jalankan dulu, 1 menit)

```bash
# a. Apakah proses Node hidup dan di PM2?
pm2 status
pm2 logs portalsi-web --lines 50

# b. Node mendengarkan di port berapa? (harus muncul 127.0.0.1:3100)
ss -ltnp | grep -E '3100|node' || echo "TIDAK ADA proses Node yang listen"

# c. Bisakah backend diakses langsung, tanpa lewat OpenLiteSpeed?
curl -I http://127.0.0.1:3100/
#   -> 200/302  = Node sehat, masalah ada di proxy/vhost (lanjut bagian 4)
#   -> connection refused = Node mati/port salah (lanjut bagian 3)

# d. Port yang diminta proxy
grep address /home/app.portalsi.com/public_html/frontend-svelte/deploy-vps/vhost-proxy.conf

# e. Port yang dipakai Node
grep -E '^PORT' /home/app.portalsi.com/public_html/frontend-svelte/.env.production
```

Aturan bacanya: **port di (d) dan (e) harus sama (3100)**, dan **(c) harus merespons**.
Kalau kedua syarat itu benar tapi domain masih 503, masalahnya di vHost/lsws (bagian 4).

---

## 3. Perbaikan cepat di server yang sudah terpasang

Jalankan ini bila Anda sudah mengikuti README lama dan kena 503.

```bash
cd /home/app.portalsi.com/public_html

# 1) Ambil kode terbaru (yang sudah diseragamkan ke port 3100)
git pull --ff-only

# 2) Pastikan .env.production memakai PORT=3100
cd frontend-svelte
[ -f .env.production ] || cp .env.example .env.production
# Set/ubah PORT menjadi 3100 (dan pastikan HOST/ORIGIN benar):
sed -i 's/^PORT=.*/PORT=3100/' .env.production
grep -E '^(HOST|PORT|ORIGIN)=' .env.production
#   Harus:
#   HOST=127.0.0.1
#   PORT=3100
#   ORIGIN=https://app.portalsi.com
chmod 600 .env.production

# 3) Build ulang + restart Node lewat skrip deploy
cd /home/app.portalsi.com/public_html
chmod +x frontend-svelte/deploy-vps/*.sh
frontend-svelte/deploy-vps/deploy-after-pull.sh

# 4) Verifikasi backend langsung
curl -I http://127.0.0.1:3100/     # harus 200 atau 302
```

Kalau langkah 4 sudah OK tapi domain masih 503, lanjut ke bagian 4 (vHost/proxy).

---

## 4. Pastikan reverse proxy OpenLiteSpeed benar

1. Di CyberPanel: **Websites → List Websites → `app.portalsi.com` → Manage → vHost Conf**.
2. Tempel **kedua blok** dari `frontend-svelte/deploy-vps/vhost-proxy.conf`
   (`extprocessor portalsi { ... }` dan `context / { ... }`) ke dalam konfigurasi vhost.
   Pastikan `address` = `127.0.0.1:3100`. **Save**.
3. Restart OpenLiteSpeed dan uji:

```bash
sudo systemctl restart lsws
curl -I https://app.portalsi.com          # harus 200/302, bukan 503
```

Catatan penting:

- Blok `context /` bertipe `proxy` membuat **seluruh** request diteruskan ke Node; folder
  `public_html` tidak lagi disajikan sebagai file statis. Ini memang yang diinginkan.
- Pastikan **SSL Let's Encrypt** untuk `app.portalsi.com` sudah diterbitkan di CyberPanel
  (SSL → Manage SSL). Tanpa SSL, akses `https://` bisa gagal.
- Jangan ada dua definisi `context /` yang bentrok. Jika template CyberPanel sudah punya
  `context /` statis, ganti/timpa dengan versi proxy di atas.

---

## 5. Deploy bersih dari nol (fresh install)

Gunakan ini untuk memasang dari awal di VPS baru — hasilnya rapi dan otomatis.

```bash
# 5.1 Clone repo ke root domain
cd /home/app.portalsi.com/public_html
git clone URL_REPOSITORY_ANDA .        # titik = clone ke folder ini

# 5.2 Siapkan environment production
cd frontend-svelte
cp .env.example .env.production
nano .env.production
```

Isi minimum `.env.production` (perhatikan PORT=3100):

```env
API_BASE_URL=https://api.portalsi.com
PUBLIC_MEDIA_BASE_URL=https://api.portalsi.com/storage
PUBLIC_REVERB_HOST=ws.portalsi.com
PUBLIC_REVERB_PORT=443
PUBLIC_REVERB_SCHEME=wss
PUBLIC_REVERB_APP_KEY=isi_key_reverb
HOST=127.0.0.1
PORT=3100
ORIGIN=https://app.portalsi.com
BODY_SIZE_LIMIT=512M
NODE_ENV=production
```

```bash
chmod 600 .env.production

# 5.3 Pasang Node.js 24 + PM2
sudo apt-get update
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2
node -v      # pastikan v24.x

# 5.4 Build + start pertama (npm ci, build, pm2 start, health check)
cd /home/app.portalsi.com/public_html
chmod +x frontend-svelte/deploy-vps/*.sh
frontend-svelte/deploy-vps/deploy-after-pull.sh

# 5.5 Auto-start saat reboot
pm2 startup systemd -u root --hp /root
# jalankan perintah 'sudo env PATH=... pm2 startup ...' yang dicetak, lalu:
pm2 save
```

Lalu pasang reverse proxy dan SSL seperti **bagian 4**.

Verifikasi akhir:

```bash
curl -I http://127.0.0.1:3100/     # backend Node
curl -I https://app.portalsi.com   # lewat OpenLiteSpeed — target 200/302
pm2 status                         # portalsi-web = online
```

---

## 6. Otomatis untuk update berikutnya (git pull → build → restart)

Pasang hook **sekali saja**:

```bash
cd /home/app.portalsi.com/public_html
frontend-svelte/deploy-vps/install-post-merge-hook.sh
```

Selanjutnya cukup:

```bash
cd /home/app.portalsi.com/public_html
git pull --ff-only
```

Hook `post-merge` otomatis menjalankan `npm ci` → `npm run build` → restart PM2, dan
melakukan health check. **Jika build gagal, proses production lama tetap jalan** (tidak
ada downtime). Untuk deploy tanpa login VPS (push-based), buat webhook/CI via SSH yang
menjalankan `git pull --ff-only` di folder yang sama.

---

## 7. Checklist ringkas 503

- [ ] `pm2 status` → `portalsi-web` **online** (bukan errored/stopped)
- [ ] `curl -I http://127.0.0.1:3100/` → **200/302**
- [ ] `.env.production` ada, `PORT=3100`, `HOST=127.0.0.1`, `ORIGIN=https://app.portalsi.com`, mode `600`
- [ ] `vhost-proxy.conf` `address` = `127.0.0.1:**3100**` dan sudah tersimpan di vHost Conf
- [ ] `sudo systemctl restart lsws` sudah dijalankan setelah edit vHost
- [ ] SSL Let's Encrypt untuk domain sudah aktif
- [ ] `build/index.js` ada (build sukses) — cek `frontend-svelte/build/index.js`

Log berguna saat menelusuri:

```bash
pm2 logs portalsi-web --lines 100
tail -n 100 /usr/local/lsws/logs/error.log
tail -n 100 /usr/local/lsws/logs/stderr.log
```

---

## 8. Error "Cross-site POST form submissions are forbidden" (CSRF)

Kalau situs sudah tampil (Node hidup) tetapi setiap submit form (mis. login) menampilkan
**"Cross-site POST form submissions are forbidden"**, itu proteksi CSRF bawaan SvelteKit.

Penyebab: di belakang OpenLiteSpeed + Cloudflare, header `Origin` request diubah/dihapus,
sehingga cek origin bawaan SvelteKit menganggap POST datang dari lintas-situs lalu memblokir.

Solusi proyek ini: skrip `frontend-svelte/scripts/patch-csrf.mjs` menonaktifkan dua cek
origin pada hasil build (bawaan SvelteKit + cek di `hooks.server.ts`). Proteksi CSRF tetap
ada lewat cookie `SameSite=Lax`. Skrip ini **idempoten** (aman diulang).

Bug sebelumnya: `npm run build` tidak memanggil skrip ini, jadi build production tidak
pernah dipatch → semua POST diblokir. Sekarang `package.json` sudah diperbaiki menjadi:

```json
"build": "vite build && node scripts/patch-csrf.mjs"
```

Sehingga setiap build (termasuk `deploy-after-pull.sh` dan `npm run package`) otomatis
menerapkan patch.

Perbaikan langsung di server (tanpa rebuild penuh), memakai build yang sudah ada:

```bash
cd /home/app.portalsi.com/public_html/frontend-svelte
node scripts/patch-csrf.mjs        # patch build/server yang ada; harus cetak "2 patch diterapkan"
set -a; . ./.env.production; set +a
pm2 restart portalsi-web --update-env || pm2 start build/index.js --name portalsi-web --update-env
pm2 save
```

Atau, setelah menarik `package.json` terbaru, cukup jalankan ulang deploy penuh:

```bash
cd /home/app.portalsi.com/public_html
git pull --ff-only
frontend-svelte/deploy-vps/deploy-after-pull.sh   # build kini sudah termasuk patch CSRF
```

Uji: buka situs, lakukan login/submit form — tidak boleh muncul lagi pesan CSRF.

Catatan versi Node: proyek menargetkan Node 24, sedangkan PM2 Anda berjalan di Node 20
(via nvm). Build & run tetap jalan, tetapi untuk konsisten sebaiknya pakai Node 24 sistem
(lihat bagian 5.3) agar `pm2 startup` dan `npm ci` memakai runtime yang sama.
