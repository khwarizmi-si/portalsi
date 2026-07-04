import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { ApiError } from '$lib/api/errors';
import { loginInputSchema, loginResponseSchema } from '$lib/schemas/auth';
import { backendRequest } from '$lib/server/api';
import { formFieldErrors, safeRedirectTarget } from '$lib/server/forms';
import { setSessionCookie } from '$lib/server/session';

export const load: PageServerLoad = ({ locals }) => {
	if (locals.user) redirect(303, '/home');
	return {};
};

export const actions: Actions = {
	default: async ({ request, cookies, locals, url }) => {
		const formData = await request.formData();
		const parsed = loginInputSchema.safeParse({
			login: formData.get('login'),
			password: formData.get('password'),
			remember: formData.get('remember') === 'on'
		});
		const values = { login: String(formData.get('login') ?? '') };
		if (!parsed.success) {
			return fail(422, {
				message: 'Periksa kembali data yang Anda masukkan.',
				errors: formFieldErrors(parsed.error),
				values
			});
		}

		try {
			const response = await backendRequest('login', {
				method: 'POST',
				body: { login: parsed.data.login, password: parsed.data.password },
				schema: loginResponseSchema,
				requestId: locals.requestId
			});
			setSessionCookie(cookies, response.token, parsed.data.remember);
		} catch (error) {
			if (error instanceof ApiError) {
				return fail(error.status, {
					message: error.message,
					errors: error.fieldErrors,
					verificationStatus: error.verificationStatus,
					retryAfterSeconds: error.retryAfterSeconds,
					requestId: error.requestId,
					values
				});
			}
			throw error;
		}

		redirect(303, safeRedirectTarget(url.searchParams.get('next')));
	}
};
