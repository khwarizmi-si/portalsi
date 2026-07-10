import { describe, expect, it } from 'vitest';
import { relativeTimeId } from './time';

describe('relativeTimeId', () => {
	const now = new Date('2026-07-04T12:00:00Z');
	it('keeps older timestamps descriptive', () => {
		expect(relativeTimeId('2026-06-20T12:00:00Z', now)).toContain('minggu');
		expect(relativeTimeId('2026-03-04T12:00:00Z', now)).toContain('bulan');
		expect(relativeTimeId('2024-07-04T12:00:00Z', now)).toContain('tahun');
	});
});
