import { ApiError } from '$lib/api/errors';
import { backendRequest } from '$lib/server/api';
import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
export const load: PageServerLoad = ({ url }) => ({
	token: url.searchParams.get('token') || '',
	email: url.searchParams.get('email') || ''
});
export const actions: Actions = {
	default: async ({ request, locals }) => {
		const data = await request.formData();
		const token = String(data.get('token') ?? '');
		const email = String(data.get('email') ?? '').trim();
		const password = String(data.get('password') ?? '');
		const confirmation = String(data.get('password_confirmation') ?? '');
		if (!token || !email) return fail(422, { message: 'Token atau email reset tidak lengkap.' });
		if (password.length < 6) return fail(422, { message: 'Kata sandi minimal 6 karakter.' });
		if (password !== confirmation)
			return fail(422, { message: 'Konfirmasi kata sandi tidak cocok.' });
		try {
			await backendRequest('reset-password', {
				method: 'POST',
				requestId: locals.requestId,
				body: { token, email, password, password_confirmation: confirmation }
			});
		} catch (error) {
			if (error instanceof ApiError) return fail(error.status, { message: error.message });
			throw error;
		}
		redirect(303, '/login?reset=success');
	}
};
