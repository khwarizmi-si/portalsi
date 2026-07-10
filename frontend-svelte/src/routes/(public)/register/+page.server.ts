import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { ApiError } from '$lib/api/errors';
import { registerInputSchema, registerResponseSchema } from '$lib/schemas/auth';
import { backendRequest } from '$lib/server/api';
import { formFieldErrors } from '$lib/server/forms';
import { setSessionCookie } from '$lib/server/session';

export const load: PageServerLoad = ({ locals }) => {
	if (locals.user) redirect(303, locals.user.emailVerified ? '/home' : '/verify-email');
	return {};
};

export const actions: Actions = {
	default: async ({ request, cookies, locals }) => {
		const formData = await request.formData();
		const values = {
			full_name: String(formData.get('full_name') ?? ''),
			username: String(formData.get('username') ?? ''),
			email: String(formData.get('email') ?? '')
		};
		const password = String(formData.get('password') ?? '');
		const passwordConfirmation = String(formData.get('password_confirmation') ?? '');
		const parsed = registerInputSchema.safeParse({
			...values,
			role: 'student',
			password: formData.get('password'),
			terms: formData.get('terms') === 'on'
		});
		if (!parsed.success) {
			return fail(422, {
				message: 'Periksa kembali data pendaftaran.',
				errors: formFieldErrors(parsed.error),
				values
			});
		}
		if (password !== passwordConfirmation) {
			return fail(422, {
				message: 'Konfirmasi kata sandi tidak cocok.',
				errors: { password_confirmation: ['Konfirmasi kata sandi tidak sama.'] },
				values
			});
		}

		try {
			const response = await backendRequest('register', {
				method: 'POST',
				body: {
					username: parsed.data.username,
					full_name: parsed.data.full_name,
					email: parsed.data.email,
					password: parsed.data.password,
					role: 'student'
				},
				schema: registerResponseSchema,
				requestId: locals.requestId
			});
			setSessionCookie(cookies, response.token, false);
		} catch (error) {
			if (error instanceof ApiError) {
				return fail(error.status, {
					message: error.message,
					errors: error.fieldErrors,
					requestId: error.requestId,
					values
				});
			}
			throw error;
		}

		redirect(303, '/verify-email');
	}
};
