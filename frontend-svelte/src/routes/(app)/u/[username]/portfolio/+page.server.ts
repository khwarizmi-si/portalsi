import { env } from '$env/dynamic/public';
import { portfoliosResponseSchema } from '$lib/schemas/portfolio';
import { profileResponseSchema } from '$lib/schemas/profile';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
export const load: PageServerLoad = async ({ locals, params }) => {
	if (!locals.token) error(401, 'Sesi tidak tersedia.');
	const profile = await backendRequest(`profile/${encodeURIComponent(params.username)}`, {
		token: locals.token,
		requestId: locals.requestId,
		schema: profileResponseSchema
	});
	const response = await backendRequest('portfolios', {
		token: locals.token,
		requestId: locals.requestId,
		query: { user_id: profile.user_id },
		schema: portfoliosResponseSchema
	});
	const base = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	return {
		user: { username: profile.username, fullName: profile.full_name?.trim() || profile.username },
		items: response.portfolios.map((item) => ({
			...item,
			mediaUrl: normalizeMediaUrl(item.media_url, base)
		}))
	};
};
