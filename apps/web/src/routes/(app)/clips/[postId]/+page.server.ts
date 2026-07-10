import { env } from '$env/dynamic/public';
import { mapPost } from '$lib/api/mappers';
import { clipsResponseSchema } from '$lib/schemas/post';
import { backendRequest } from '$lib/server/api';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
export const load: PageServerLoad = async ({ locals, params }) => {
	if (!locals.token) error(401, 'Sesi tidak tersedia.');
	const id = Number.parseInt(params.postId, 10);
	if (!Number.isSafeInteger(id) || id < 1) error(404, 'Clips tidak ditemukan.');
	const response = await backendRequest(`clips/${id}`, {
		token: locals.token,
		requestId: locals.requestId,
		schema: clipsResponseSchema
	});
	const media = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	return {
		clip: mapPost({ ...response.clip, type: 'post' }, media),
		nextId: response.next_clips[0]?.post_id ?? null
	};
};
