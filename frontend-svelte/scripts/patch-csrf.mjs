#!/usr/bin/env node
/**
 * patch-csrf.mjs — Matikan cek CSRF berbasis-origin pada hasil build adapter-node.
 *
 * Perlu karena di belakang OpenLiteSpeed header `Origin` diubah/dihapus, sehingga
 * cek origin bawaan SvelteKit + cek di hooks memblokir semua POST form.
 * Proteksi CSRF tetap ada lewat cookie SameSite=Lax.
 *
 * Dijalankan otomatis oleh package-deploy.mjs dan redeploy.sh setelah `vite build`.
 * Aman diulang (idempoten) dan tidak bergantung pada nama file ber-hash.
 */
import { readdirSync, readFileSync, writeFileSync, statSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const serverDir = path.join(root, 'build', 'server');

if (!existsSync(serverDir)) {
	console.error('✗ build/server tidak ada. Jalankan "npm run build" dulu.');
	process.exit(1);
}

const patches = [
	// Cek CSRF form bawaan SvelteKit
	{ find: 'else if (options.csrf_check_origin)', replace: 'else if (false)' },
	// Cek origin tambahan di hooks.server.ts
	{ find: 'if (origin && origin !== event.url.origin)', replace: 'if (false)' }
];

function walk(dir) {
	const out = [];
	for (const name of readdirSync(dir)) {
		const p = path.join(dir, name);
		if (statSync(p).isDirectory()) out.push(...walk(p));
		else if (name.endsWith('.js')) out.push(p);
	}
	return out;
}

let applied = 0;
for (const file of walk(serverDir)) {
	let code = readFileSync(file, 'utf8');
	let changed = false;
	for (const { find, replace } of patches) {
		if (code.includes(find)) {
			code = code.split(find).join(replace);
			changed = true;
			applied++;
			console.log(`  patched ${path.relative(root, file)}`);
		}
	}
	if (changed) writeFileSync(file, code);
}

console.log(
	applied
		? `✔ ${applied} patch CSRF diterapkan.`
		: 'ℹ Tidak ada pola CSRF ditemukan (mungkin sudah dipatch atau versi SvelteKit berbeda — cek manual).'
);
