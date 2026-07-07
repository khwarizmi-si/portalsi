import { ApiError } from '$lib/api/errors';
import { backendRequest } from '$lib/server/api';
import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = ({ locals }) => {
	if (!locals.user) redirect(303, '/login');
	return {
		email: locals.user.email,
		emailVerified: locals.user.emailVerified
	};
};

export const actions: Actions = {
	default: async ({ request, locals }) => {
		if (!locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
		const data = await request.formData();
		const email = String(data.get('email') ?? '')
			.trim()
			.toLowerCase();
		if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
			return fail(422, { message: 'Masukkan alamat email yang valid.', values: { email } });
		try {
			const response = await backendRequest<{ message: string; pending_email?: string }>(
				'account/email/change',
				{
					method: 'POST',
					token: locals.token,
					requestId: locals.requestId,
					body: { email }
				}
			);
			return { success: true, message: response.message, pendingEmail: response.pending_email };
		} catch (error) {
			if (error instanceof ApiError)
				return fail(error.status, {
					message: error.message,
					errors: error.fieldErrors,
					values: { email }
				});
			throw error;
		}
	}
};
