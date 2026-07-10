import { describe, expect, it } from 'vitest';
import { isAllowedExternalUrl, normalizeMediaUrl } from './media';

describe('normalizeMediaUrl', () => {
	it('returns null for empty media values', () => {
		expect(normalizeMediaUrl(undefined, 'https://api.portalsi.com/storage')).toBeNull();
		expect(normalizeMediaUrl('  ', 'https://api.portalsi.com/storage')).toBeNull();
	});

	it('keeps an absolute HTTP URL', () => {
		expect(
			normalizeMediaUrl('https://cdn.portalsi.com/posts/a.jpg', 'https://api.portalsi.com/storage')
		).toBe('https://cdn.portalsi.com/posts/a.jpg');
	});

	it('normalizes storage paths against the configured media base', () => {
		expect(
			normalizeMediaUrl('/storage/uploads/posts/a.jpg', 'https://api.portalsi.com/storage')
		).toBe('https://api.portalsi.com/storage/uploads/posts/a.jpg');
	});
});

describe('isAllowedExternalUrl', () => {
	it('only accepts HTTPS URLs from an exact allowed origin', () => {
		const origins = ['https://store.portalsi.com'];
		expect(isAllowedExternalUrl('https://store.portalsi.com/products', origins)).toBe(true);
		expect(isAllowedExternalUrl('https://store.portalsi.com.evil.test', origins)).toBe(false);
		expect(isAllowedExternalUrl('http://store.portalsi.com', origins)).toBe(false);
	});
});
