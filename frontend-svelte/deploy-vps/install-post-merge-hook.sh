#!/usr/bin/env bash
# Pasang sekali. Sesudahnya setiap `git pull` yang berhasil akan build + restart app.
set -euo pipefail

APP_ROOT="${APP_ROOT:-/home/app.portalsi.com/public_html}"
HOOK="${APP_ROOT}/.git/hooks/post-merge"
DEPLOY_SCRIPT="${APP_ROOT}/frontend-svelte/deploy-vps/deploy-after-pull.sh"

if [ ! -d "${APP_ROOT}/.git" ]; then
	echo "${APP_ROOT} bukan working tree Git." >&2
	exit 1
fi
if [ ! -f "${DEPLOY_SCRIPT}" ]; then
	echo "Skrip deploy tidak ditemukan: ${DEPLOY_SCRIPT}" >&2
	exit 1
fi

chmod +x "${DEPLOY_SCRIPT}"
cat >"${HOOK}" <<EOF
#!/usr/bin/env bash
set -e
APP_ROOT="${APP_ROOT}" "${DEPLOY_SCRIPT}"
EOF
chmod +x "${HOOK}"
echo "Hook aktif: ${HOOK}"
echo "Mulai sekarang, git pull yang berhasil akan menjalankan build dan restart PM2."
