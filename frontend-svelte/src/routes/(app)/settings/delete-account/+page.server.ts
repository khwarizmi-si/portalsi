import { ApiError } from '$lib/api/errors';
import { backendRequest } from '$lib/server/api';
import { clearSessionCookie } from '$lib/server/session';
import { fail, redirect } from '@sveltejs/kit';
import type { Actions } from './$types';
export const actions: Actions = {
	default: async ({ request, locals, cookies }) => {
		if (!locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
		const data = await request.formData();
		if (String(data.get('confirmation') ?? '') !== 'HAPUS')
			return fail(422, { message: 'Ketik HAPUS untuk mengonfirmasi.' });
		try {
			await backendRequest('account/delete', {
				method: 'DELETE',
				token: locals.token,
				requestId: locals.requestId
			});
			clearSessionCookie(cookies);
		} catch (error) {
			if (error instanceof ApiError) return fail(error.status, { message: error.message });
			throw error;
		}
		redirect(303, '/welcome');
	}
};
