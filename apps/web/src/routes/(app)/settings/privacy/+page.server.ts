import { ApiError } from '$lib/api/errors';
import { backendRequest } from '$lib/server/api';
import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = ({ locals }) => ({
	isPrivate: locals.user?.isPrivate ?? false
});
export const actions: Actions = {
	default: async ({ request, locals }) => {
		if (!locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
		const source = await request.formData();
		const body = new FormData();
		body.set('is_private', source.get('is_private') === 'on' ? '1' : '0');
		try {
			await backendRequest('account/settings', {
				method: 'POST',
				token: locals.token,
				requestId: locals.requestId,
				body
			});
			return { success: true, message: 'Privasi akun diperbarui.' };
		} catch (error) {
			if (error instanceof ApiError) return fail(error.status, { message: error.message });
			throw error;
		}
	}
};
