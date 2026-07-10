import { expect, test } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('route authenticated mengarahkan pengguna anonim ke login', async ({ page }) => {
	await page.goto('/home');

	await expect(page).toHaveURL(/\/login\?next=%2Fhome$/);
	await expect(page.getByRole('heading', { name: 'Masuk ke Portal SI' })).toBeVisible();
});

test('login menampilkan validasi field tanpa memanggil backend', async ({ page }) => {
	await page.goto('/login');
	await page.getByRole('button', { name: 'Masuk' }).click();

	await expect(page.getByText('Username atau email wajib diisi.')).toBeVisible();
	await expect(page.getByText('Kata sandi wajib diisi.')).toBeVisible();
});

test('pendaftaran selalu menggunakan peran siswa tanpa pilihan role', async ({ page }) => {
	await page.goto('/register');
	await expect(
		page.getByText('Akun baru otomatis terdaftar sebagai siswa Portal SI.')
	).toBeVisible();
	await expect(page.getByLabel('Peran')).toHaveCount(0);
});

test('BFF menolak request API tanpa cookie sesi', async ({ request }) => {
	const response = await request.get('/api/posts');

	expect(response.status()).toBe(401);
	expect(await response.json()).toEqual({ message: 'Sesi tidak tersedia.' });
	expect(response.headers()['cache-control']).toBe('private, no-store');
});

test('BFF eksternal tidak dapat dipakai tanpa sesi', async ({ request }) => {
	for (const path of ['/api/external/music?q=test', '/api/external/locations?q=Denpasar']) {
		const response = await request.get(path);
		expect(response.status()).toBe(401);
		expect(await response.json()).toEqual({ message: 'Sesi tidak tersedia.' });
	}
});

test('hook menolak unsafe request lintas origin', async ({ request }) => {
	const response = await request.post('/api/posts', {
		headers: { Origin: 'https://attacker.example' },
		data: { caption: 'tidak boleh diteruskan' }
	});
	expect(response.status()).toBe(403);
	expect(await response.text()).toBe('Origin tidak diizinkan.');
});

test('response publik membawa header keamanan dan request id', async ({ request }) => {
	const response = await request.get('/welcome');
	expect(response.status()).toBe(200);
	expect(response.headers()['content-security-policy']).toContain("frame-ancestors 'none'");
	expect(response.headers()['x-content-type-options']).toBe('nosniff');
	expect(response.headers()['x-request-id']).toBeTruthy();
});

test('manifest PWA tersedia dan menunjuk ikon lokal', async ({ request }) => {
	const response = await request.get('/manifest.webmanifest');
	expect(response.status()).toBe(200);
	const manifest = await response.json();
	expect(manifest).toMatchObject({ name: 'Portal SI', display: 'standalone' });
	expect(manifest.icons[0].src).toBe('/assets/logo-mark.png');
});

test('favicon Portal SI digunakan pada halaman publik', async ({ page }) => {
	await page.goto('/welcome');
	await expect(page.locator('link[rel="icon"][href="/assets/logo-mark.png"]')).toHaveCount(1);
});

test('surface publik tidak memiliki pelanggaran aksesibilitas serius', async ({ page }) => {
	for (const path of ['/welcome', '/login']) {
		await page.goto(path);
		const results = await new AxeBuilder({ page }).analyze();
		const blocking = results.violations.filter(({ impact }) =>
			['serious', 'critical'].includes(impact ?? '')
		);
		expect(blocking, `${path}: ${blocking.map((item) => item.id).join(', ')}`).toEqual([]);
	}
});
