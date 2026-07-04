import { env } from '$env/dynamic/public';
import { mapCompactUser } from '$lib/api/mappers';
import type { CompactUser } from '$lib/schemas/post';
import { followersResponseSchema, followingResponseSchema } from '$lib/schemas/profile';
import { backendRequest } from '$lib/server/api';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
export const load: PageServerLoad = async ({ locals, params }) => {
	if (!locals.token || !locals.user) error(401, 'Sesi tidak tersedia.');
	if (!['followers', 'following'].includes(params.connection))
		error(404, 'Halaman tidak ditemukan.');
	const followers = params.connection === 'followers';
	let raw: CompactUser[];
	if (followers) {
		const response = await backendRequest(`users/${locals.user.id}/followers`, {
			token: locals.token,
			requestId: locals.requestId,
			query: { per_page: 100 },
			schema: followersResponseSchema
		});
		raw = response.followers;
	} else {
		const response = await backendRequest(`users/${locals.user.id}/following`, {
			token: locals.token,
			requestId: locals.requestId,
			query: { per_page: 100 },
			schema: followingResponseSchema
		});
		raw = response.following;
	}
	const media = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	return {
		title: followers ? 'Pengikut' : 'Mengikuti',
		users: raw.map((user) => mapCompactUser(user, media))
	};
};
