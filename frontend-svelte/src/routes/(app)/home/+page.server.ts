import { env } from '$env/dynamic/public';
import type { PortalUser, PostPreview, StoryPreview } from '$lib/types/domain';
import { mapAnnouncement, mapCompactUser, mapPost, mapStoryGroups } from '$lib/api/mappers';
import { pinnedAnnouncementsSchema } from '$lib/schemas/announcement';
import {
	feedResponseSchema,
	onlineFollowersResponseSchema,
	suggestionsResponseSchema
} from '$lib/schemas/post';
import { storyFeedResponseSchema } from '$lib/schemas/story';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

const defaultMediaBaseUrl = 'https://api.portalsi.com/storage';

export const load: PageServerLoad = async ({ locals }) => {
	if (!locals.token || !locals.user) error(401, 'Sesi Anda tidak tersedia. Silakan masuk kembali.');

	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || defaultMediaBaseUrl;
	const requestOptions = { token: locals.token, requestId: locals.requestId };
	const requests = [
		backendRequest('posts', { ...requestOptions, schema: feedResponseSchema }),
		backendRequest('stories/feed', { ...requestOptions, schema: storyFeedResponseSchema }),
		backendRequest('announcements/pinned', {
			...requestOptions,
			schema: pinnedAnnouncementsSchema
		}),
		locals.user.emailVerified
			? backendRequest('suggestions', { ...requestOptions, schema: suggestionsResponseSchema })
			: Promise.resolve(null),
		backendRequest('websocket/online-followers', {
			...requestOptions,
			schema: onlineFollowersResponseSchema
		})
	] as const;
	const [feedResult, storyResult, announcementResult, suggestionResult, onlineResult] =
		await Promise.allSettled(requests);

	let posts: PostPreview[] = [];
	let embeddedSuggestions: PortalUser[] = [];
	let hasMore = false;
	if (feedResult.status === 'fulfilled') {
		posts = feedResult.value.feed
			.filter((item) => item.type === 'post')
			.map((post) => mapPost(post, mediaBaseUrl));
		embeddedSuggestions = feedResult.value.feed
			.filter((item) => item.type === 'suggestion')
			.flatMap((item) => item.users.map((user) => mapCompactUser(user, mediaBaseUrl)));
		hasMore = feedResult.value.current_page * feedResult.value.per_page < feedResult.value.total;
	}

	let stories: StoryPreview[] = [
		{ id: 0, user: mapCompactSessionUser(locals.user, mediaBaseUrl), isOwn: true }
	];
	if (storyResult.status === 'fulfilled') {
		stories = mapStoryGroups(storyResult.value, locals.user, mediaBaseUrl);
	}
	const storyStatus = new Map(
		storyResult.status === 'fulfilled'
			? storyResult.value.stories.map((group) => [
					group.user_id,
					{ hasStory: true, storyViewed: group.is_viewed }
				])
			: []
	);
	const attachStoryStatus = (user: PortalUser): PortalUser => ({
		...user,
		...(storyStatus.get(user.id) ?? {})
	});

	const announcements =
		announcementResult.status === 'fulfilled'
			? announcementResult.value.map((item) => mapAnnouncement(item))
			: [];
	const announcement = announcements[0] ?? null;
	const suggestions = deduplicateUsers([
		...(suggestionResult.status === 'fulfilled' && suggestionResult.value
			? suggestionResult.value.users.map((user) => mapCompactUser(user, mediaBaseUrl))
			: []),
		...embeddedSuggestions
	])
		.map(attachStoryStatus)
		.slice(0, 6);
	const onlineUsers =
		onlineResult.status === 'fulfilled'
			? onlineResult.value.followers
					.map((user) => mapCompactUser(user, mediaBaseUrl))
					.map(attachStoryStatus)
			: [];

	const unavailable: string[] = [];
	if (feedResult.status === 'rejected') unavailable.push('postingan');
	if (storyResult.status === 'rejected') unavailable.push('cerita');
	if (announcementResult.status === 'rejected') unavailable.push('pengumuman');
	if (suggestionResult.status === 'rejected') unavailable.push('saran teman');

	return {
		user: locals.user,
		dateLabel: new Intl.DateTimeFormat('id-ID', {
			weekday: 'long',
			day: 'numeric',
			month: 'long',
			timeZone: 'Asia/Makassar'
		}).format(new Date()),
		posts,
		stories,
		announcement,
		announcements,
		suggestions,
		onlineUsers,
		onlineCount: onlineResult.status === 'fulfilled' ? onlineResult.value.count : null,
		hasMore,
		unavailable
	};
};

function deduplicateUsers(users: PortalUser[]): PortalUser[] {
	return [...new Map(users.map((user) => [user.id, user])).values()];
}

function mapCompactSessionUser(
	user: NonNullable<App.Locals['user']>,
	mediaBaseUrl: string
): PortalUser {
	return {
		id: user.id,
		username: user.username,
		fullName: user.fullName,
		avatarUrl: user.avatarUrl
			? (normalizeMediaUrl(user.avatarUrl, mediaBaseUrl) ?? undefined)
			: undefined,
		role: user.role,
		badgeVerified: user.badgeVerified,
		emailVerified: user.emailVerified,
		isPrivate: user.isPrivate,
		hasStory: false,
		storyViewed: false
	};
}
