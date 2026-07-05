import { env } from '$env/dynamic/public';
import { storyViewerResponseSchema } from '$lib/schemas/story';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { relativeTimeId } from '$lib/utils/time';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, params, url }) => {
	if (!locals.token || !locals.user) error(401, 'Sesi Anda tidak tersedia.');
	const userId = Number.parseInt(params.userId, 10);
	if (!Number.isSafeInteger(userId) || userId < 1) error(404, 'Cerita tidak ditemukan.');
	const storyOrder = [
		...new Set(
			(url.searchParams.get('order') ?? '')
				.split(',')
				.map((value) => Number.parseInt(value, 10))
				.filter((value) => Number.isSafeInteger(value) && value > 0)
		)
	].slice(0, 30);
	const validOrder = storyOrder.includes(userId) ? storyOrder : [];
	const response = await backendRequest(`stories/feed/user/${userId}`, {
		token: locals.token,
		requestId: locals.requestId,
		schema: storyViewerResponseSchema,
		query: validOrder.length > 0 ? { order: validOrder.join(',') } : undefined
	});
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	const orderIndex = validOrder.indexOf(userId);
	return {
		user: {
			id: response.current_user.user_id,
			username: response.current_user.username,
			fullName: response.current_user.full_name?.trim() || response.current_user.username,
			role: response.current_user.role,
			badgeVerified: response.current_user.is_verified,
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
			albumArtUrl: normalizeMediaUrl(story.music_album_art_url, mediaBaseUrl),
			musicStartSeconds: (story.music_start_position_ms ?? 0) / 1000,
			musicDurationSeconds: (story.music_clip_duration_ms ?? 15_000) / 1000
		})),
		// Hanya home yang mengirim `order`. Entry point lain (profil, post,
		// komentar, dst.) harus tetap berada di rangkaian story pemilik ini.
		previousUserId: orderIndex > 0 ? validOrder[orderIndex - 1] : null,
		nextUserId:
			orderIndex >= 0 && orderIndex < validOrder.length - 1 ? validOrder[orderIndex + 1] : null,
		storyOrder: validOrder.join(',')
	};
};
