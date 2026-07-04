import { ApiError } from '$lib/api/errors';
import { backendRequest } from '$lib/server/api';
import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { profileResponseSchema } from '$lib/schemas/profile';
export const load: PageServerLoad = ({ locals }) => ({ username: locals.user?.username ?? '' });
export const actions: Actions = {
	default: async ({ request, locals }) => {
		if (!locals.token || !locals.user) return fail(401, { message: 'Sesi tidak tersedia.' });
		if (!(['teacher', 'dev'].includes(locals.user.role) || locals.user.badgeVerified))
			return fail(403, {
				message: 'Backend hanya mengizinkan guru, dev, atau akun dengan badge verifikasi.'
			});
		const source = await request.formData();
		const body = new FormData();
		for (const field of ['aspect', 'title', 'description', 'year']) {
			const value = String(source.get(field) ?? '').trim();
			if (value) body.set(field, value);
		}
		const targetUsername =
			String(source.get('target_username') ?? '').trim() || locals.user.username;
		let targetId = locals.user.id;
		if (targetUsername.toLowerCase() !== locals.user.username.toLowerCase()) {
			try {
				const target = await backendRequest(`profile/${encodeURIComponent(targetUsername)}`, {
					token: locals.token,
					requestId: locals.requestId,
					schema: profileResponseSchema
				});
				targetId = target.user_id;
			} catch (error) {
				if (error instanceof ApiError)
					return fail(error.status, { message: 'Pengguna tujuan tidak ditemukan.' });
				throw error;
			}
		}
		body.set('user_id', String(targetId));
		const media = source.get('media');
		if (media instanceof File && media.size > 0) {
			if (media.size > 50 * 1024 * 1024) return fail(422, { message: 'Media maksimal 50 MB.' });
			body.set('media', media);
		}
		try {
			await backendRequest('portfolios', {
				method: 'POST',
				token: locals.token,
				requestId: locals.requestId,
				body
			});
		} catch (error) {
			if (error instanceof ApiError)
				return fail(error.status, { message: error.message, errors: error.fieldErrors });
			throw error;
		}
		redirect(303, '/portfolio');
	}
};
