#!/usr/bin/env bash
# Build setelah `git pull`, lalu restart proses Node hanya bila build sukses.
set -euo pipefail

APP_ROOT="${APP_ROOT:-/home/app.portalsi.com/public_html}"
FRONTEND_DIR="${FRONTEND_DIR:-${APP_ROOT}/apps/web}"
APP_NAME="${APP_NAME:-portalsi-web}"
ENV_FILE="${ENV_FILE:-${FRONTEND_DIR}/.env.production}"
LOCK_FILE="${LOCK_FILE:-/tmp/${APP_NAME}-deploy.lock}"

exec 9>"${LOCK_FILE}"
if ! flock -n 9; then
	echo "Deploy ${APP_NAME} lain masih berjalan; proses ini dilewati."
	exit 0
fi

if [ ! -f "${FRONTEND_DIR}/package-lock.json" ]; then
	echo "Frontend tidak ditemukan di ${FRONTEND_DIR}." >&2
	exit 1
fi
if [ ! -f "${ENV_FILE}" ]; then
	echo "${ENV_FILE} belum ada. Salin dari .env.example dan isi konfigurasi production." >&2
	exit 1
fi

cd "${FRONTEND_DIR}"
echo "==> Install dependency dari lockfile"
# --include=dev WAJIB: build butuh vite & svelte-kit (devDependencies). Tanpa flag ini,
# jika NODE_ENV=production ter-export di shell, npm ci melewati devDependencies dan build
# gagal ("vite: not found"). NODE_ENV untuk runtime di-set setelah build (lihat bawah).
unset NODE_ENV
npm ci --include=dev --no-audit --no-fund
echo "==> Build SvelteKit production"
npm run build
test -f build/index.js

set -a
# shellcheck disable=SC1090
. "${ENV_FILE}"
set +a
export NODE_ENV="${NODE_ENV:-production}"
export HOST="${HOST:-127.0.0.1}"
export PORT="${PORT:-3100}"
export BODY_SIZE_LIMIT="${BODY_SIZE_LIMIT:-512M}"

echo "==> Restart ${APP_NAME}"
if pm2 describe "${APP_NAME}" >/dev/null 2>&1; then
	pm2 restart "${APP_NAME}" --update-env
else
	pm2 start build/index.js --name "${APP_NAME}" --cwd "${FRONTEND_DIR}" --update-env
fi
pm2 save >/dev/null

echo "==> Health check"
for attempt in 1 2 3 4 5; do
	if curl --fail --silent --show-error --max-time 8 "http://${HOST}:${PORT}/" >/dev/null; then
		echo "Deploy selesai dan server merespons di ${HOST}:${PORT}."
		exit 0
	fi
	sleep 2
done

echo "Build selesai, tetapi health check gagal. Periksa: pm2 logs ${APP_NAME}" >&2
exit 1
