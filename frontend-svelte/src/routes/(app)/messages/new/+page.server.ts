import { env } from '$env/dynamic/public';
import { mapCompactUser } from '$lib/api/mappers';
import { userSearchResponseSchema } from '$lib/schemas/post';
import { storyFeedResponseSchema } from '$lib/schemas/story';
import { backendRequest } from '$lib/server/api';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	if (!locals.token) error(401, 'Sesi Anda tidak tersedia.');
	const [response, storyFeed] = await Promise.all([
		backendRequest('mutuals', {
			token: locals.token,
			requestId: locals.requestId,
			query: { per_page: 30 },
			schema: userSearchResponseSchema
		}),
		backendRequest('stories/feed', {
			token: locals.token,
			requestId: locals.requestId,
			schema: storyFeedResponseSchema
		}).catch(() => null)
	]);
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	const storyStatus = new Map(storyFeed?.stories.map((group) => [group.user_id, group]) ?? []);
	return {
		users: response.data.map((user) => ({
			...mapCompactUser(user, mediaBaseUrl),
			hasStory: storyStatus.has(user.user_id),
			storyViewed: storyStatus.get(user.user_id)?.is_viewed ?? false
		}))
	};
};
