import { ApiError } from '$lib/api/errors';
import { backendRequest } from '$lib/server/api';
import { fail } from '@sveltejs/kit';
import type { Actions } from './$types';
export const actions: Actions = {
	default: async ({ request, locals }) => {
		if (!locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
		const data = await request.formData();
		const current = String(data.get('current_password') ?? '');
		const next = String(data.get('new_password') ?? '');
		const confirmation = String(data.get('confirmation') ?? '');
		if (next.length < 6) return fail(422, { message: 'Kata sandi baru minimal 6 karakter.' });
		if (next !== confirmation) return fail(422, { message: 'Konfirmasi kata sandi tidak cocok.' });
		try {
			await backendRequest('account/password', {
				method: 'PUT',
				token: locals.token,
				requestId: locals.requestId,
				body: { current_password: current, new_password: next }
			});
			return { success: true, message: 'Kata sandi berhasil diperbarui.' };
		} catch (error) {
			if (error instanceof ApiError) return fail(error.status, { message: error.message });
			throw error;
		}
	}
};
