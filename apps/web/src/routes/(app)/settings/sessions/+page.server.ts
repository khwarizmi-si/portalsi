import { loginHistoriesSchema } from '$lib/schemas/account';
import { backendRequest } from '$lib/server/api';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
export const load: PageServerLoad = async ({ locals }) => {
	if (!locals.token) error(401, 'Sesi tidak tersedia.');
	const sessions = await backendRequest('login-histories', {
		token: locals.token,
		requestId: locals.requestId,
		schema: loginHistoriesSchema
	});
	return { sessions };
};
