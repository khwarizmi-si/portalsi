import { redirect, type RequestHandler } from '@sveltejs/kit';
import { backendRequest } from '$lib/server/api';
import { clearSessionCookie } from '$lib/server/session';

export const POST: RequestHandler = async ({ locals, cookies }) => {
	if (locals.token) {
		try {
			await backendRequest('logout', {
				method: 'POST',
				token: locals.token,
				requestId: locals.requestId
			});
		} catch {
			// A local logout must still succeed if the upstream session endpoint is unavailable.
		} finally {
			clearSessionCookie(cookies);
		}
	} else {
		clearSessionCookie(cookies);
	}
	redirect(303, '/login');
};
