import { describe, expect, it } from 'vitest';
import { parseBackendError } from './errors';

describe('parseBackendError', () => {
	it('normalizes Laravel validation errors', () => {
		const error = parseBackendError(422, {
			message: 'Validation failed',
			errors: { email: ['Format email tidak valid.'], username: 'Username wajib diisi.' }
		});

		expect(error.status).toBe(422);
		expect(error.fieldErrors).toEqual({
			email: ['Format email tidak valid.'],
			username: ['Username wajib diisi.']
		});
	});

	it('preserves verification and cooldown metadata', () => {
		const error = parseBackendError(403, {
			code: 2002,
			message: 'Akun belum diverifikasi.',
			verification_email_status: 'cooldown',
			resend_cooldown_seconds: 42
		});

		expect(error.code).toBe(2002);
		expect(error.verificationStatus).toBe('cooldown');
		expect(error.retryAfterSeconds).toBe(42);
	});
});
