import { describe, expect, it } from 'vitest';
import { backendUserSchema, toSessionUser } from './user';

describe('backend user mapping', () => {
	it('keeps badge verification separate from email verification', () => {
		const backendUser = backendUserSchema.parse({
			user_id: 17,
			username: 'naila.putri',
			full_name: 'Naila Putri',
			email: 'naila@example.test',
			role: 'student',
			is_verified: 1,
			is_private: 0,
			email_verified: false
		});
		const user = toSessionUser(backendUser);

		expect(user.badgeVerified).toBe(true);
		expect(user.emailVerified).toBe(false);
		expect(user.fullName).toBe('Naila Putri');
	});

	it('uses email_verified_at when the explicit response flag is absent', () => {
		const user = toSessionUser(
			backendUserSchema.parse({
				user_id: 8,
				username: 'guru.rina',
				role: 'teacher',
				is_verified: false,
				is_private: false,
				email_verified_at: '2026-07-03T08:00:00Z'
			})
		);

		expect(user.emailVerified).toBe(true);
		expect(user.fullName).toBe('guru.rina');
	});
});
