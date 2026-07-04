import { env } from '$env/dynamic/public';
import { notificationsResponseSchema } from '$lib/schemas/notification';
import { pendingFollowersResponseSchema } from '$lib/schemas/profile';
import { storyFeedResponseSchema } from '$lib/schemas/story';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { relativeTimeId } from '$lib/utils/time';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	if (!locals.token) error(401, 'Sesi Anda tidak tersedia.');
	const page = Math.max(1, Number.parseInt(url.searchParams.get('page') || '1', 10) || 1);
	const [response, storyFeed, pending] = await Promise.all([
		backendRequest('notifications', {
			token: locals.token,
			requestId: locals.requestId,
			query: { page, per_page: 15 },
			schema: notificationsResponseSchema
		}),
		backendRequest('stories/feed', {
			token: locals.token,
			requestId: locals.requestId,
			schema: storyFeedResponseSchema
		}).catch(() => null),
		backendRequest('followers/pending', {
			token: locals.token,
			requestId: locals.requestId,
			schema: pendingFollowersResponseSchema
		}).catch(() => null)
	]);
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	const storyStatus = new Map(storyFeed?.stories.map((group) => [group.user_id, group]) ?? []);
	return {
		items: response.notifications.map((item) => ({
			id: item.notification_id,
			type: item.type,
			message: item.message,
			read: item.is_read,
			time: relativeTimeId(item.created_at),
			postId: item.related_post_id,
			user: item.sender
				? {
						id: item.sender.user_id,
						username: item.sender.username,
						fullName: item.sender.full_name?.trim() || item.sender.username,
						avatarUrl: normalizeMediaUrl(item.sender.profile_picture_url, mediaBaseUrl),
						role: item.sender.role,
						badgeVerified: item.sender.is_verified,
						hasStory: storyStatus.has(item.sender.user_id),
						storyViewed: storyStatus.get(item.sender.user_id)?.is_viewed ?? false
					}
				: null
		})),
		requests:
			pending?.pending_requests.map((user) => ({
				id: user.user_id,
				username: user.username,
				fullName: user.full_name?.trim() || user.username,
				avatarUrl: normalizeMediaUrl(user.profile_picture_url, mediaBaseUrl),
				role: user.role,
				badgeVerified: user.is_verified
			})) ?? [],
		page: response.pagination.current_page,
		hasNext: response.pagination.current_page < response.pagination.last_page
	};
};
