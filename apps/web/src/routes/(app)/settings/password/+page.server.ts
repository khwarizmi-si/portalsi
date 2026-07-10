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
		if (next.length < 8)
			return fail(422, {
				message: 'Kata sandi baru minimal 8 karakter.',
				errors: { new_password: ['Kata sandi baru minimal 8 karakter.'] }
			});
		if (next !== confirmation)
			return fail(422, {
				message: 'Konfirmasi kata sandi tidak cocok.',
				errors: { confirmation: ['Konfirmasi kata sandi tidak sama.'] }
			});
		if (next === current)
			return fail(422, {
				message: 'Kata sandi baru harus berbeda dari kata sandi lama.',
				errors: { new_password: ['Kata sandi baru harus berbeda dari kata sandi lama.'] }
			});
		try {
			await backendRequest('account/password', {
				method: 'PUT',
				token: locals.token,
				requestId: locals.requestId,
				body: {
					current_password: current,
					new_password: next,
					new_password_confirmation: confirmation
				}
			});
			return { success: true, message: 'Kata sandi berhasil diperbarui.' };
		} catch (error) {
			if (error instanceof ApiError)
				return fail(error.status, { message: error.message, errors: error.fieldErrors });
			throw error;
		}
	}
};
