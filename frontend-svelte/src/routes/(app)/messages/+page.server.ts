import { env } from '$env/dynamic/public';
import { chatListSchema, specialGroupsSchema } from '$lib/schemas/chat';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { relativeTimeId } from '$lib/utils/time';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	if (!locals.token) error(401, 'Sesi Anda tidak tersedia.');
	const response = await backendRequest('messages/chat-list', {
		token: locals.token,
		requestId: locals.requestId,
		schema: chatListSchema
	});
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	const specialGroups = ['parent', 'teacher'].includes(locals.user?.role ?? '')
		? await backendRequest('special-groups', {
				token: locals.token,
				requestId: locals.requestId,
				schema: specialGroupsSchema
			}).catch(() => [])
		: [];
	// Ringkas pesan yang berisi tautan postingan menjadi label ramah (bukan URL mentah).
	const previewText = (raw: string | null | undefined, hasMedia: boolean) => {
		const value = (raw ?? '').trim();
		if (/https?:\/\/[^\s]*\/posts\/\d+/i.test(value)) {
			const note = value.replace(/https?:\/\/[^\s]*\/posts\/\d+/gi, '').trim();
			return note ? `📷 ${note}` : '📷 Membagikan postingan';
		}
		return value || (hasMedia ? 'Media' : 'Belum ada pesan');
	};

	// Urutkan berdasarkan waktu pesan terakhir (grup & pribadi bercampur, terbaru di atas).
	const lastAt = (item: (typeof response)[number]) =>
		item.type === 'user' ? item.last_chat.sent_at : item.sent_at;
	const sorted = [...response].sort((a, b) => {
		const ta = lastAt(a);
		const tb = lastAt(b);
		return (tb ? new Date(tb).getTime() : 0) - (ta ? new Date(ta).getTime() : 0);
	});
	return {
		specialGroups: specialGroups.map((group) => ({
			...group,
			avatarUrl: normalizeMediaUrl(group.avatar_url, mediaBaseUrl)
		})),
		chats: sorted.map((item) =>
			item.type === 'user'
				? {
						type: 'direct' as const,
						id: item.conversation.id,
						name: item.conversation.name || item.conversation.username || 'Pengguna Portal SI',
						handle: item.conversation.username
							? `@${item.conversation.username}`
							: 'Pesan langsung',
						avatarUrl: normalizeMediaUrl(item.conversation.profile_picture_url, mediaBaseUrl),
						text: previewText(item.last_chat.content, Boolean(item.last_chat.media)),
						time: item.last_chat.sent_at ? relativeTimeId(item.last_chat.sent_at) : '',
						unread: !item.last_chat.is_read,
						unreadCount: 0
					}
				: {
						type: 'group' as const,
						id: item.id,
						name: item.name,
						handle: item.description || 'Grup Portal SI',
						avatarUrl: normalizeMediaUrl(item.avatar_url, mediaBaseUrl),
						text: previewText(item.last_message, Boolean(item.last_media)),
						time: item.sent_at ? relativeTimeId(item.sent_at) : '',
						unread: item.unread_count > 0,
						unreadCount: item.unread_count
					}
		)
	};
};
