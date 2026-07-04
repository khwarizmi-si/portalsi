#!/usr/bin/env bash
# setup-vps.sh — Install Node.js + pm2 dan jalankan Portal SI Web di Contabo VPS (CyberPanel).
# Jalankan sebagai root di server, dari dalam folder deploy (yang berisi build/index.js).
#
#   sudo bash setup-vps.sh
#
# Override opsional lewat environment:
#   DOMAIN=app.portalsi.com PORT=3000 APP_NAME=portalsi-web sudo -E bash setup-vps.sh
set -euo pipefail

# ==== Konfigurasi default — boleh diubah lewat env ====
DOMAIN="${DOMAIN:-app.portalsi.com}"
PORT="${PORT:-3000}"
APP_NAME="${APP_NAME:-portalsi-web}"
NODE_MAJOR="${NODE_MAJOR:-24}"
# ======================================================

ORIGIN="https://${DOMAIN}"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

if [ "$(id -u)" -ne 0 ]; then
	echo "Harus dijalankan sebagai root (pakai sudo)." >&2
	exit 1
fi

if [ ! -f "${APP_DIR}/build/index.js" ]; then
	echo "build/index.js tidak ditemukan di ${APP_DIR}." >&2
	echo "Upload folder deploy (hasil 'npm run package') dulu, lalu jalankan skrip ini dari dalamnya." >&2
	exit 1
fi

log "Install Node.js ${NODE_MAJOR} (bila belum ada)"
need_node=1
if command -v node >/dev/null 2>&1; then
	current="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
	[ "${current:-0}" -ge "${NODE_MAJOR}" ] && need_node=0
fi
if [ "${need_node}" -eq 1 ]; then
	curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
	apt-get install -y nodejs
fi
echo "Node: $(node -v)"

log "Install pm2 (global)"
npm install -g pm2 >/dev/null 2>&1 || npm install -g pm2

cd "${APP_DIR}"

log "Siapkan .env"
if [ ! -f .env ]; then
	if [ -f .env.example ]; then
		cp .env.example .env
		echo "!! .env dibuat dari .env.example — WAJIB diedit nilainya."
	else
		touch .env
	fi
fi
# Pastikan HOST/PORT/ORIGIN ada (append bila belum).
grep -q '^HOST='   .env || echo "HOST=127.0.0.1"      >> .env
grep -q '^PORT='   .env || echo "PORT=${PORT}"         >> .env
grep -q '^ORIGIN=' .env || echo "ORIGIN=${ORIGIN}"     >> .env
grep -q '^BODY_SIZE_LIMIT=' .env || echo "BODY_SIZE_LIMIT=512M" >> .env
chmod 600 .env

log "Pastikan start.sh executable"
[ -f start.sh ] && chmod +x start.sh

log "Jalankan app via pm2 (${APP_NAME})"
if [ -f start.sh ]; then
	pm2 delete "${APP_NAME}" >/dev/null 2>&1 || true
	pm2 start ./start.sh --name "${APP_NAME}"
else
	pm2 delete "${APP_NAME}" >/dev/null 2>&1 || true
	HOST=127.0.0.1 PORT="${PORT}" ORIGIN="${ORIGIN}" NODE_ENV=production \
		pm2 start build/index.js --name "${APP_NAME}" --update-env
fi

log "Simpan & aktifkan auto-start saat reboot"
pm2 save
pm2 startup systemd -u root --hp /root >/dev/null 2>&1 || pm2 startup || true

cat <<DONE

✔ Selesai. App berjalan di http://127.0.0.1:${PORT} (dikelola pm2 sebagai '${APP_NAME}').

Langkah terakhir (sekali saja):
  1. Edit nilai environment bila perlu:   nano ${APP_DIR}/.env   lalu  pm2 restart ${APP_NAME}
  2. Pasang reverse proxy: tempel isi vhost-proxy.conf ke CyberPanel > Websites >
     ${DOMAIN} > Manage > vHost Conf, lalu:  sudo systemctl restart lsws
  3. Terbitkan SSL Let's Encrypt di CyberPanel untuk ${DOMAIN}.

Cek status:  pm2 status   |   pm2 logs ${APP_NAME}
DONE
