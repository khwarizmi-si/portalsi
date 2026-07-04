import { env } from '$env/dynamic/public';
import { chatListSchema, directConversationSchema } from '$lib/schemas/chat';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { relativeTimeId } from '$lib/utils/time';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, params, url }) => {
	if (!locals.token || !locals.user) error(401, 'Sesi Anda tidak tersedia.');
	const peerId = Number.parseInt(params.userId, 10);
	if (!Number.isSafeInteger(peerId) || peerId < 1 || peerId === locals.user.id)
		error(404, 'Percakapan tidak ditemukan.');
	const [messages, chatList] = await Promise.all([
		backendRequest(`messages/conversation/${peerId}`, {
			token: locals.token,
			requestId: locals.requestId,
			schema: directConversationSchema
		}),
		backendRequest('messages/chat-list', {
			token: locals.token,
			requestId: locals.requestId,
			schema: chatListSchema
		})
	]);
	const existing = chatList.find((item) => item.type === 'user' && item.conversation.id === peerId);
	const queryName = (url.searchParams.get('name') || '').trim().slice(0, 100);
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	const title =
		existing?.type === 'user'
			? existing.conversation.name || existing.conversation.username
			: queryName;
	return {
		mode: 'direct' as const,
		targetId: peerId,
		title: title || `Pengguna #${peerId}`,
		subtitle:
			existing?.type === 'user' && existing.conversation.username
				? `@${existing.conversation.username}`
				: 'Pesan langsung',
		avatarUrl:
			existing?.type === 'user'
				? normalizeMediaUrl(existing.conversation.profile_picture_url, mediaBaseUrl)
				: null,
		currentUserId: locals.user.id,
		messages: messages.map((message) => ({
			id: message.message_id,
			senderId: message.sender_id,
			senderName:
				message.sender_id === locals.user?.id
					? locals.user.username
					: title || `Pengguna #${peerId}`,
			mine: message.sender_id === locals.user?.id,
			text: message.content || '',
			mediaUrl: normalizeMediaUrl(message.media_url, mediaBaseUrl),
			time: relativeTimeId(message.sent_at),
			isRead: message.is_read,
			isPinned: false
		}))
	};
};
