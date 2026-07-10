import { describe, expect, it } from 'vitest';
import { safeRedirectTarget } from './forms';

describe('safeRedirectTarget', () => {
	it('accepts an internal absolute path', () => {
		expect(safeRedirectTarget('/posts/184?from=notification')).toBe('/posts/184?from=notification');
	});

	it('rejects protocol-relative and malformed targets', () => {
		expect(safeRedirectTarget('//evil.test')).toBe('/home');
		expect(safeRedirectTarget('/\\evil.test')).toBe('/home');
		expect(safeRedirectTarget('https://evil.test')).toBe('/home');
	});
});
