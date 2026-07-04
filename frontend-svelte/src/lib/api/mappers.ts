import type { AnnouncementPreview, PortalUser, PostPreview, StoryPreview } from '$lib/types/domain';
import type { BackendPost, CompactUser } from '$lib/schemas/post';
import type { StoryFeedResponse } from '$lib/schemas/story';
import type { SessionUser } from '$lib/schemas/user';
import { normalizeMediaUrl } from '$lib/utils/media';
import { relativeTimeId } from '$lib/utils/time';

export function mapCompactUser(user: CompactUser, mediaBaseUrl?: string): PortalUser {
	return {
		id: user.user_id,
		username: user.username,
		fullName: user.full_name?.trim() || user.username,
		avatarUrl: mediaBaseUrl
			? (normalizeMediaUrl(user.profile_picture_url, mediaBaseUrl) ?? undefined)
			: (user.profile_picture_url ?? undefined),
		role: user.role,
		badgeVerified: user.is_verified,
		emailVerified: true,
		isPrivate: user.is_private,
		hasStory: user.has_story ?? false,
		storyViewed: user.story_viewed ?? false
	};
}

export function mapSessionToPortalUser(user: SessionUser): PortalUser {
	return {
		id: user.id,
		username: user.username,
		fullName: user.fullName,
		avatarUrl: user.avatarUrl ?? undefined,
		role: user.role,
		badgeVerified: user.badgeVerified,
		emailVerified: user.emailVerified,
		isPrivate: user.isPrivate,
		hasStory: false,
		storyViewed: false
	};
}

export function mapPost(post: BackendPost, mediaBaseUrl: string): PostPreview {
	return {
		id: post.post_id,
		user: mapCompactUser(post.user, mediaBaseUrl),
		caption: post.caption ?? '',
		mediaUrl: normalizeMediaUrl(post.media_url, mediaBaseUrl) ?? '/assets/logo.png',
		thumbnailUrl: normalizeMediaUrl(post.thumbnail_url, mediaBaseUrl) ?? undefined,
		isVideo: post.is_video,
		mediaAlt: post.caption?.trim() || `Postingan oleh ${post.user.username}`,
		location: post.location ?? undefined,
		createdLabel: relativeTimeId(post.created_at),
		likesCount: post.likes_count,
		commentsCount: post.comments_count,
		isLiked: post.is_liked,
		isBookmarked: post.is_bookmarked,
		music: post.music_track_name
			? { title: post.music_track_name, artist: post.music_artist_name ?? 'Artis tidak diketahui' }
			: undefined
	};
}

export function mapStoryGroups(
	response: StoryFeedResponse,
	currentUser: SessionUser,
	mediaBaseUrl: string
): StoryPreview[] {
	const ownGroup = response.stories.find((group) => group.user_id === currentUser.id);
	const ownUser = mapSessionToPortalUser(currentUser);
	ownUser.hasStory = Boolean(ownGroup);
	ownUser.storyViewed = ownGroup?.is_viewed ?? false;
	const own: StoryPreview = {
		id: ownGroup?.stories[0]?.story_id ?? 0,
		user: ownUser,
		isOwn: true
	};
	const groups = response.stories
		.filter((group) => group.user_id !== currentUser.id)
		.map<StoryPreview>((group) => ({
			id: group.stories[0].story_id,
			user: {
				id: group.user_id,
				username: group.username,
				fullName: group.username,
				avatarUrl: normalizeMediaUrl(group.profile_picture_url, mediaBaseUrl) ?? undefined,
				role: 'other',
				badgeVerified: false,
				emailVerified: true,
				isPrivate: false,
				hasStory: true,
				storyViewed: group.is_viewed
			}
		}));
	return [own, ...groups];
}

export function mapAnnouncement(announcement: {
	id: number;
	title?: string | null;
	content?: string | null;
	created_at: string;
	pinned: boolean;
}): AnnouncementPreview {
	return {
		id: announcement.id,
		title: announcement.title?.trim() || 'Pengumuman Portal SI',
		content: announcement.content?.trim() || 'Tidak ada rincian tambahan.',
		createdLabel: relativeTimeId(announcement.created_at),
		pinned: announcement.pinned
	};
}
