import { env } from '$env/dynamic/public';
import { followingResponseSchema, profileResponseSchema } from '$lib/schemas/profile';
import { storyFeedResponseSchema } from '$lib/schemas/story';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, params }) => {
	if (locals.user && params.username.toLowerCase() === locals.user.username.toLowerCase())
		redirect(303, '/profile');

	const [profileResult, followingResult, storyResult] = await Promise.allSettled([
		backendRequest(`profile/${encodeURIComponent(params.username)}`, {
			token: locals.token ?? undefined,
			requestId: locals.requestId,
			schema: profileResponseSchema
		}),
		locals.token && locals.user
			? backendRequest(`users/${locals.user.id}/following`, {
					token: locals.token,
					requestId: locals.requestId,
					query: { per_page: 1000 },
					schema: followingResponseSchema
				})
			: Promise.resolve(null),
		locals.token
			? backendRequest('stories/feed', {
					token: locals.token,
					requestId: locals.requestId,
					schema: storyFeedResponseSchema
				})
			: Promise.resolve(null)
	]);
	if (profileResult.status === 'rejected') throw profileResult.reason;

	const profile = profileResult.value;
	const profileStory =
		storyResult.status === 'fulfilled'
			? storyResult.value?.stories.find((group) => group.user_id === profile.user_id)
			: null;
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
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
			isPrivate: profile.is_private,
			followersCount: profile.followers_count,
			followingCount: profile.following_count,
			postsCount: profile.posts_count,
			message: profile.message ?? null,
			hasStory: Boolean(profileStory),
			storyViewed: profileStory?.is_viewed ?? false
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
		),
		isFollowing:
			followingResult.status === 'fulfilled' &&
			Boolean(followingResult.value?.following.some((user) => user.user_id === profile.user_id)),
		connectionUnavailable: Boolean(locals.user && followingResult.status === 'rejected'),
		canFollow: locals.user?.emailVerified ?? false,
		isAuthenticated: Boolean(locals.user)
	};
};
