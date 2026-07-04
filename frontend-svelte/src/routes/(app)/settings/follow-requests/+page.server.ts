import { ApiError } from '$lib/api/errors';
import { pendingFollowersResponseSchema } from '$lib/schemas/profile';
import { backendRequest } from '$lib/server/api';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
export const load: PageServerLoad = async ({ locals }) => {
	if (!locals.token) error(401, 'Sesi tidak tersedia.');
	try {
		const response = await backendRequest('followers/pending', {
			token: locals.token,
			requestId: locals.requestId,
			schema: pendingFollowersResponseSchema
		});
		return {
			isPrivate: true,
			requests: response.pending_requests.map((user) => ({
				id: user.user_id,
				username: user.username,
				fullName: user.full_name?.trim() || user.username
			}))
		};
	} catch (cause) {
		if (cause instanceof ApiError && cause.status === 403)
			return { isPrivate: false, requests: [] };
		throw cause;
	}
};
