import { redirect, type RequestHandler } from '@sveltejs/kit';
import { backendRequest } from '$lib/server/api';
import { clearSessionCookie } from '$lib/server/session';

const doLogout: RequestHandler = async ({ locals, cookies }) => {
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

// POST dipakai form logout biasa; GET dipakai saat pengalihan langsung dari halaman
// (mencabut sesi saat ini / logout semua perangkat) agar tidak berujung ke error 405.
export const POST: RequestHandler = doLogout;
export const GET: RequestHandler = doLogout;
