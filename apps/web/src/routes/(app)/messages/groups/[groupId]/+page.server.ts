import { env } from '$env/dynamic/public';
import { groupDetailResponseSchema, groupMessagesResponseSchema } from '$lib/schemas/chat';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { relativeTimeId } from '$lib/utils/time';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, params }) => {
	if (!locals.token || !locals.user) error(401, 'Sesi Anda tidak tersedia.');
	const groupId = Number.parseInt(params.groupId, 10);
	if (!Number.isSafeInteger(groupId) || groupId < 1) error(404, 'Grup tidak ditemukan.');
	const [detail, response] = await Promise.all([
		backendRequest(`groups/${groupId}`, {
			token: locals.token,
			requestId: locals.requestId,
			schema: groupDetailResponseSchema
		}),
		backendRequest(`groups/${groupId}/messages`, {
			token: locals.token,
			requestId: locals.requestId,
			schema: groupMessagesResponseSchema
		})
	]);
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	return {
		mode: 'group' as const,
		targetId: groupId,
		title: detail.group.name,
		subtitle: `${detail.members.length.toLocaleString('id-ID')} anggota`,
		avatarUrl: normalizeMediaUrl(detail.group.avatar_url, mediaBaseUrl),
		currentUserId: locals.user.id,
		canPin: detail.group.owner.user_id === locals.user.id,
		messages: response.messages.map((message) => ({
			id: message.id,
			senderId: message.sender.user_id,
			senderName: message.sender.username,
			mine: message.sender.user_id === locals.user?.id,
			text: message.content || '',
			mediaUrl: normalizeMediaUrl(message.media_url, mediaBaseUrl),
			time: message.sent_at ? relativeTimeId(message.sent_at) : '',
			isRead: message.reads ? true : false,
			isPinned: message.is_pinned
		}))
	};
};
