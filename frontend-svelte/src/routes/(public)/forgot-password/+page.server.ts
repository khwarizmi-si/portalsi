import { fail } from '@sveltejs/kit';
import type { Actions } from './$types';
import { ApiError } from '$lib/api/errors';
import { forgotPasswordInputSchema, forgotPasswordResponseSchema } from '$lib/schemas/auth';
import { backendRequest } from '$lib/server/api';
import { formFieldErrors } from '$lib/server/forms';

export const actions: Actions = {
	default: async ({ request, locals }) => {
		const formData = await request.formData();
		const values = { email: String(formData.get('email') ?? '') };
		const parsed = forgotPasswordInputSchema.safeParse(values);
		if (!parsed.success) {
			return fail(422, {
				message: 'Periksa alamat email Anda.',
				errors: formFieldErrors(parsed.error),
				values
			});
		}

		try {
			const response = await backendRequest('forgot-password', {
				method: 'POST',
				body: parsed.data,
				schema: forgotPasswordResponseSchema,
				requestId: locals.requestId
			});
			return { success: true, message: response.message, values };
		} catch (error) {
			if (error instanceof ApiError) {
				return fail(error.status, {
					message: error.message,
					errors: error.fieldErrors,
					retryAfterSeconds: error.retryAfterSeconds,
					requestId: error.requestId,
					values
				});
			}
			throw error;
		}
	}
};
