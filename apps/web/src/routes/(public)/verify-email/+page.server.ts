import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { ApiError } from '$lib/api/errors';
import { backendRequest } from '$lib/server/api';

export const load: PageServerLoad = ({ locals }) => {
	if (!locals.token || !locals.user) redirect(303, '/login');
	if (locals.user.emailVerified) redirect(303, '/home');
	return { user: locals.user };
};

export const actions: Actions = {
	resend: async ({ locals }) => {
		if (!locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
		try {
			const response = await backendRequest<{
				message?: string;
				verification_email_status?: string;
			}>('email/verification-notification', {
				method: 'POST',
				token: locals.token,
				requestId: locals.requestId
			});
			return { success: true, message: response.message ?? 'Email verifikasi telah dikirim.' };
		} catch (error) {
			if (error instanceof ApiError) return fail(error.status, { message: error.message });
			throw error;
		}
	},
	bind: async ({ request, locals }) => {
		if (!locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
		const formData = await request.formData();
		const email = String(formData.get('email') ?? '').trim();
		if (!email) return fail(422, { message: 'Email wajib diisi.' });
		try {
			const response = await backendRequest<{ message?: string }>('bind-email', {
				method: 'POST',
				token: locals.token,
				body: { email },
				requestId: locals.requestId
			});
			return { success: true, message: response.message ?? 'Email berhasil ditambahkan.' };
		} catch (error) {
			if (error instanceof ApiError) return fail(error.status, { message: error.message });
			throw error;
		}
	}
};
