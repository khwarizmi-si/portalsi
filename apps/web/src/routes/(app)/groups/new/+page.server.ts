import { ApiError } from '$lib/api/errors';
import { createdGroupResponseSchema } from '$lib/schemas/chat';
import { backendRequest } from '$lib/server/api';
import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = ({ locals }) => {
	if (!locals.user?.emailVerified) redirect(303, '/verify-email');
	return {};
};

export const actions: Actions = {
	default: async ({ request, locals }) => {
		if (!locals.token || !locals.user) return fail(401, { message: 'Sesi tidak tersedia.' });
		if (!locals.user.emailVerified)
			return fail(403, { message: 'Verifikasi email diperlukan untuk membuat grup.' });

		const source = await request.formData();
		const name = String(source.get('name') ?? '').trim();
		const description = String(source.get('description') ?? '').trim();
		if (!name) return fail(422, { message: 'Nama grup wajib diisi.', name, description });
		if (name.length > 100)
			return fail(422, { message: 'Nama grup maksimal 100 karakter.', name, description });

		const body = new FormData();
		body.set('name', name);
		if (description) body.set('description', description);
		for (const field of ['avatar', 'cover'] as const) {
			const file = source.get(field);
			if (!(file instanceof File) || file.size === 0) continue;
			if (file.size > 10 * 1024 * 1024)
				return fail(422, {
					message: `${field === 'avatar' ? 'Avatar' : 'Sampul'} maksimal 10 MB.`
				});
			if (!['image/jpeg', 'image/png'].includes(file.type))
				return fail(422, { message: 'Avatar dan sampul harus berupa JPG atau PNG.' });
			body.set(field, file);
		}
		const members = String(source.get('members') ?? '')
			.split(/[\n,]/)
			.map((value) => value.trim().replace(/^@/, ''))
			.filter(Boolean);
		for (const member of [...new Set(members)]) body.append('members[]', member);

		let groupId: number;
		try {
			const response = await backendRequest('groups', {
				method: 'POST',
				token: locals.token,
				requestId: locals.requestId,
				body,
				schema: createdGroupResponseSchema
			});
			groupId = response.group.id;
		} catch (error) {
			if (error instanceof ApiError)
				return fail(error.status, {
					message: error.message,
					errors: error.fieldErrors,
					name,
					description
				});
			throw error;
		}
		redirect(303, `/messages/groups/${groupId}`);
	}
};
