import { ApiError } from '$lib/api/errors';
import { backendRequest } from '$lib/server/api';
import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = ({ locals }) => ({ user: locals.user });

export const actions: Actions = {
	default: async ({ request, locals }) => {
		if (!locals.token) redirect(303, '/login');
		const source = await request.formData();
		const body = new FormData();
		for (const field of ['username', 'full_name', 'bio'])
			body.set(field, String(source.get(field) ?? '').trim());
		for (const [field, limit] of [
			['profile_picture', 10],
			['banner', 20]
		] as const) {
			const file = source.get(field);
			if (file instanceof File && file.size > 0) {
				const allowed =
					field === 'banner'
						? ['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.type)
						: file.type.startsWith('image/');
				if (!allowed) return fail(422, { message: 'Foto dan banner harus berupa gambar.' });
				if (file.size > limit * 1024 * 1024)
					return fail(422, {
						message: `${field === 'banner' ? 'Banner' : 'Foto'} maksimal ${limit} MB.`
					});
				body.set(field, file);
			}
		}
		try {
			await backendRequest('account/settings', {
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
		redirect(303, '/profile');
	}
};
