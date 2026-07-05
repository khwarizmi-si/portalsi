const absoluteHttpPattern = /^https?:\/\//i;

export function normalizeMediaUrl(
	value: string | null | undefined,
	mediaBaseUrl: string
): string | null {
	if (!value?.trim()) return null;

	const raw = value.trim();
	// URL yang rusak/tidak wajar tidak boleh menjatuhkan seluruh halaman (mis. saat SSR
	// me-render daftar pesan). Kembalikan null agar media itu saja yang tidak tampil.
	try {
		if (absoluteHttpPattern.test(raw)) {
			const url = new URL(raw);
			if (url.protocol !== 'https:' && url.protocol !== 'http:') return null;
			return url.toString();
		}

		const base = mediaBaseUrl.endsWith('/') ? mediaBaseUrl : `${mediaBaseUrl}/`;
		const cleanPath = raw.replace(/^\/+/, '').replace(/^storage\//, '');
		return new URL(cleanPath, base).toString();
	} catch {
		return null;
	}
}

export function isAllowedExternalUrl(value: string, allowedOrigins: readonly string[]): boolean {
	try {
		const url = new URL(value);
		return url.protocol === 'https:' && allowedOrigins.includes(url.origin);
	} catch {
		return false;
	}
}
