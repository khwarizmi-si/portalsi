import { env } from '$env/dynamic/public';
import { chatListSchema, directConversationSchema, directPeerSchema } from '$lib/schemas/chat';
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
	const [messages, chatList, peer] = await Promise.all([
		backendRequest(`messages/conversation/${peerId}`, {
			token: locals.token,
			requestId: locals.requestId,
			schema: directConversationSchema
		}),
		backendRequest('messages/chat-list', {
			token: locals.token,
			requestId: locals.requestId,
			schema: chatListSchema
		}),
		backendRequest(`users/${peerId}`, {
			token: locals.token,
			requestId: locals.requestId,
			schema: directPeerSchema
		}).catch(() => null)
	]);
	const existing = chatList.find((item) => item.type === 'user' && item.conversation.id === peerId);
	const queryName = (url.searchParams.get('name') || '').trim().slice(0, 100);
	const queryUsername = (url.searchParams.get('username') || '').trim().slice(0, 50);
	const queryAvatar = (url.searchParams.get('avatar') || '').trim().slice(0, 2048);
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	const title =
		existing?.type === 'user'
			? existing.conversation.name || existing.conversation.username
			: peer?.full_name?.trim() || peer?.username || queryName;
	const username =
		existing?.type === 'user' ? existing.conversation.username : peer?.username || queryUsername;
	return {
		mode: 'direct' as const,
		targetId: peerId,
		title: title || `Pengguna #${peerId}`,
		subtitle: username ? `@${username}` : 'Pesan langsung',
		avatarUrl:
			existing?.type === 'user'
				? normalizeMediaUrl(existing.conversation.profile_picture_url, mediaBaseUrl)
				: normalizeMediaUrl(peer?.profile_picture_url || queryAvatar, mediaBaseUrl),
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
