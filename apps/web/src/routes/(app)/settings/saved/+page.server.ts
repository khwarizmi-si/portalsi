import { env } from '$env/dynamic/public';
import { mapPost } from '$lib/api/mappers';
import { bookmarksResponseSchema } from '$lib/schemas/post';
import { backendRequest } from '$lib/server/api';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	if (!locals.token) error(401, 'Sesi tidak tersedia.');
	const response = await backendRequest('bookmarks', {
		token: locals.token,
		requestId: locals.requestId,
		schema: bookmarksResponseSchema
	});
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	return { posts: response.map((post) => mapPost({ ...post, is_bookmarked: true }, mediaBaseUrl)) };
};
