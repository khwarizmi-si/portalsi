#!/usr/bin/env node
/**
 * package-deploy.mjs — Build Portal SI Web dan rakit satu folder siap deploy.
 *
 * Jalankan dari root apps/web:
 *   node scripts/package-deploy.mjs
 * atau: npm run package
 *
 * Hasil: folder `deploy/` yang berisi build adapter-node + dependency produksi,
 * sehingga cukup dijalankan dengan `node build/index.js`.
 */
import { execSync } from 'node:child_process';
import {
	cpSync,
	rmSync,
	mkdirSync,
	existsSync,
	writeFileSync,
	copyFileSync,
	chmodSync
} from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const deployDir = path.join(root, 'deploy');

function run(cmd, cwd = root) {
	console.log(`\n→ ${cmd}   (${cwd})`);
	execSync(cmd, { cwd, stdio: 'inherit' });
}

// 0. Pastikan dependency ada.
if (!existsSync(path.join(root, 'node_modules', 'vite'))) {
	console.log('node_modules belum lengkap, menjalankan npm install...');
	run('npm install --no-audit --no-fund');
}

// 1. Build produksi (adapter-node).
run('npm run build');
if (!existsSync(path.join(root, 'build', 'index.js'))) {
	console.error('✗ Build tidak menghasilkan build/index.js. Batalkan.');
	process.exit(1);
}

// 2. Reset folder deploy.
rmSync(deployDir, { recursive: true, force: true });
mkdirSync(deployDir, { recursive: true });

// 3. Salin artefak build dan manifest.
cpSync(path.join(root, 'build'), path.join(deployDir, 'build'), { recursive: true });
copyFileSync(path.join(root, 'package.json'), path.join(deployDir, 'package.json'));
const lock = path.join(root, 'package-lock.json');
if (existsSync(lock)) copyFileSync(lock, path.join(deployDir, 'package-lock.json'));

// 4. Pasang dependency produksi agar folder ini mandiri.
run(
	existsSync(path.join(deployDir, 'package-lock.json'))
		? 'npm ci --omit=dev'
		: 'npm install --omit=dev --no-audit --no-fund',
	deployDir
);

// 5. Contoh environment.
const envExample = path.join(root, '.env.example');
if (existsSync(envExample)) copyFileSync(envExample, path.join(deployDir, '.env.example'));

// 6. Skrip start, Dockerfile, dan README deploy.
writeFileSync(
	path.join(deployDir, 'start.sh'),
	`#!/usr/bin/env sh
# Muat .env bila ada, lalu jalankan server adapter-node.
set -a
[ -f .env ] && . ./.env
set +a
export HOST="\${HOST:-0.0.0.0}"
export PORT="\${PORT:-3100}"
exec node build/index.js
`
);
chmodSync(path.join(deployDir, 'start.sh'), 0o755);

writeFileSync(
	path.join(deployDir, 'start.bat'),
	`@echo off
if not defined HOST set HOST=0.0.0.0
if not defined PORT set PORT=3100
node build\\index.js
`
);

writeFileSync(
	path.join(deployDir, 'Dockerfile'),
	`# Menjalankan folder deploy yang sudah berisi build/ dan node_modules produksi.
FROM node:24-slim
WORKDIR /app
COPY . .
ENV HOST=0.0.0.0 PORT=3100 NODE_ENV=production
EXPOSE 3100
CMD ["node", "build/index.js"]
`
);

writeFileSync(
	path.join(deployDir, 'README.md'),
	`# Portal SI Web — folder deploy

Folder ini mandiri. Isi: build adapter-node (\`build/\`), dependency produksi
(\`node_modules/\`), dan \`package.json\`.

## Jalankan

1. Salin \`.env.example\` menjadi \`.env\` lalu isi nilainya (minimal API_BASE_URL,
   PUBLIC_MEDIA_BASE_URL, PUBLIC_REVERB_*, dan RANKING/ITUNES/NOMINATIM URL).
2. Set juga \`ORIGIN\` ke URL publik (mis. \`https://web.portalsi.com\`) agar CSRF
   dan form actions bekerja di belakang reverse proxy.
3. Start:

   \`\`\`sh
   ./start.sh          # Linux/macOS
   start.bat           # Windows
   # atau langsung:
   HOST=0.0.0.0 PORT=3100 ORIGIN=https://web.portalsi.com node build/index.js
   \`\`\`

Butuh Node.js 24+. Server default mendengarkan di 0.0.0.0:3100.

## Reverse proxy (produksi)

Terminasi HTTPS, teruskan \`X-Forwarded-For\`/\`X-Forwarded-Proto\`, dukung upgrade
WebSocket (Reverb), dan samakan batas upload dengan Laravel.

## Docker

\`\`\`sh
docker build -t portalsi-web .
docker run --env-file .env -p 3100:3100 portalsi-web
\`\`\`
`
);

// 7. Sertakan helper VPS (CyberPanel) bila ada.
const vpsDir = path.join(root, 'deploy-vps');
if (existsSync(vpsDir)) {
	for (const file of [
		'setup-vps.sh',
		'vhost-proxy.conf',
		'deploy-after-pull.sh',
		'install-post-merge-hook.sh',
		'README.md'
	]) {
		const from = path.join(vpsDir, file);
		if (existsSync(from)) {
			const target = path.join(deployDir, file);
			copyFileSync(from, target);
			if (file.endsWith('.sh')) chmodSync(target, 0o755);
		}
	}
}

console.log('\n✔ Folder deploy siap: ' + deployDir);
console.log('  Uji lokal: cd deploy && HOST=127.0.0.1 PORT=3100 node build/index.js');
