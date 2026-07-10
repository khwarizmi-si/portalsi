import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { ApiError } from '$lib/api/errors';
import { loginInputSchema, loginResponseSchema } from '$lib/schemas/auth';
import { backendRequest } from '$lib/server/api';
import { formFieldErrors, safeRedirectTarget } from '$lib/server/forms';
import { setSessionCookie } from '$lib/server/session';

export const load: PageServerLoad = ({ locals }) => {
	if (locals.user) redirect(303, locals.user.emailVerified ? '/home' : '/verify-email');
	return {};
};

export const actions: Actions = {
	default: async ({ request, cookies, locals, url, getClientAddress }) => {
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
			// Teruskan UA & IP asli browser ke API supaya riwayat login akurat (request ke
			// API datang dari server SSR, bukan langsung dari browser).
			const clientUa = request.headers.get('user-agent') ?? '';
			const clientIp =
				request.headers.get('cf-connecting-ip') ??
				(request.headers.get('x-forwarded-for') ?? '').split(',')[0].trim() ??
				'';
			const response = await backendRequest('login', {
				method: 'POST',
				body: { login: parsed.data.login, password: parsed.data.password },
				schema: loginResponseSchema,
				requestId: locals.requestId,
				headers: {
					'X-Real-Client-Ua': clientUa,
					'X-Real-Client-Ip': clientIp || getClientAddress()
				}
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

		const next = String(formData.get('next') ?? '') || url.searchParams.get('next');
		redirect(303, safeRedirectTarget(next));
	}
};
