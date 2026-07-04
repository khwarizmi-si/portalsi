import { env } from '$env/dynamic/public';
import { profileResponseSchema } from '$lib/schemas/profile';
import { storyFeedResponseSchema } from '$lib/schemas/story';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	if (!locals.token) error(401, 'Sesi Anda tidak tersedia.');
	const [profile, storyFeed] = await Promise.all([
		backendRequest('user', {
			token: locals.token,
			requestId: locals.requestId,
			schema: profileResponseSchema
		}),
		backendRequest('stories/feed', {
			token: locals.token,
			requestId: locals.requestId,
			schema: storyFeedResponseSchema
		}).catch(() => null)
	]);
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	const ownStory = storyFeed?.stories.find((group) => group.user_id === profile.user_id);

	return {
		profile: {
			id: profile.user_id,
			username: profile.username,
			fullName: profile.full_name?.trim() || profile.username,
			bio: profile.bio?.trim() || '',
			avatarUrl: normalizeMediaUrl(profile.profile_picture_url, mediaBaseUrl),
			bannerUrl: normalizeMediaUrl(profile.banner_url, mediaBaseUrl),
			role: profile.role,
			badgeVerified: profile.is_verified,
			followersCount: profile.followers_count,
			followingCount: profile.following_count,
			postsCount: profile.posts_count,
			hasStory: Boolean(ownStory),
			storyViewed: ownStory?.is_viewed ?? false
		},
		posts: profile.recent_posts.map((post) => ({
			id: post.post_id,
			caption: post.caption?.trim() || `Postingan ${profile.username}`,
			mediaUrl: normalizeMediaUrl(post.media_url, mediaBaseUrl) || '/assets/logo.png',
			thumbnailUrl: normalizeMediaUrl(post.thumbnail_url, mediaBaseUrl),
			isVideo: post.is_video
		})),
		hasMore: Boolean(
			profile.pagination && profile.pagination.current_page < profile.pagination.last_page
		)
	};
};
