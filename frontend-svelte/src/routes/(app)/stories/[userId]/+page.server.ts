import { env } from '$env/dynamic/public';
import { storyViewerResponseSchema } from '$lib/schemas/story';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { relativeTimeId } from '$lib/utils/time';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, params }) => {
	if (!locals.token || !locals.user) error(401, 'Sesi Anda tidak tersedia.');
	const userId = Number.parseInt(params.userId, 10);
	if (!Number.isSafeInteger(userId) || userId < 1) error(404, 'Cerita tidak ditemukan.');
	const response = await backendRequest(`stories/feed/user/${userId}`, {
		token: locals.token,
		requestId: locals.requestId,
		schema: storyViewerResponseSchema
	});
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	return {
		user: {
			id: response.current_user.user_id,
			username: response.current_user.username,
			avatarUrl: normalizeMediaUrl(response.current_user.profile_picture_url, mediaBaseUrl)
		},
		isOwn: locals.user.id === response.current_user.user_id,
		stories: response.stories.map((story) => ({
			id: story.story_id,
			type: story.type,
			mediaUrl: normalizeMediaUrl(story.media_url, mediaBaseUrl),
			caption: story.caption ?? '',
			createdLabel: relativeTimeId(story.created_at),
			musicTitle: story.music_track_name ?? null,
			musicArtist: story.music_artist_name ?? null,
			musicPreviewUrl: normalizeMediaUrl(story.music_preview_url, mediaBaseUrl),
			albumArtUrl: normalizeMediaUrl(story.music_album_art_url, mediaBaseUrl)
		})),
		previousUserId: response.prev_user_id,
		nextUserId: response.next_user_id
	};
};
