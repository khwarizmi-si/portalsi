import { env } from '$env/dynamic/public';
import { archivedStoriesResponseSchema } from '$lib/schemas/story';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { relativeTimeId } from '$lib/utils/time';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
export const load: PageServerLoad = async ({ locals, url }) => {
	if (!locals.token) error(401, 'Sesi tidak tersedia.');
	const page = Math.max(1, Number.parseInt(url.searchParams.get('page') || '1', 10) || 1);
	const response = await backendRequest('stories/my/archived', {
		token: locals.token,
		requestId: locals.requestId,
		query: { page, per_page: 12 },
		schema: archivedStoriesResponseSchema
	});
	const media = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	return {
		page: response.current_page,
		hasNext: Boolean(response.next_page_url),
		stories: response.stories.map((story) => ({
			id: story.story_id,
			type: story.type,
			caption: story.caption || '',
			mediaUrl: normalizeMediaUrl(story.media_url, media),
			thumbUrl: normalizeMediaUrl(story.media_url || story.music_album_art_url, media),
			createdLabel: relativeTimeId(story.created_at),
			musicTitle: story.music_track_name ?? null,
			musicArtist: story.music_artist_name ?? null,
			musicPreviewUrl: normalizeMediaUrl(story.music_preview_url, media),
			albumArtUrl: normalizeMediaUrl(story.music_album_art_url, media),
			musicStartSeconds: (story.music_start_position_ms ?? 0) / 1000,
			musicDurationSeconds: (story.music_clip_duration_ms ?? 15_000) / 1000
		}))
	};
};
