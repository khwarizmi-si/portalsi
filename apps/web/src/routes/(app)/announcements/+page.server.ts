import { env } from '$env/dynamic/public';
import { ApiError } from '$lib/api/errors';
import { pinnedAnnouncementsSchema } from '$lib/schemas/announcement';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { relativeTimeId } from '$lib/utils/time';
import { error, fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
export const load: PageServerLoad = async ({ locals }) => {
	if (!locals.token || !locals.user) error(401, 'Sesi tidak tersedia.');
	const items = await backendRequest('announcements', {
		token: locals.token,
		requestId: locals.requestId,
		schema: pinnedAnnouncementsSchema
	});
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	return {
		canManage: ['teacher', 'dev'].includes(locals.user.role),
		currentUserId: locals.user.id,
		items: items.map((item) => ({
			id: item.id,
			title: item.title?.trim() || 'Pengumuman Portal SI',
			content: item.content?.trim() || 'Tidak ada rincian tambahan.',
			imageUrl: normalizeMediaUrl(item.image_url, mediaBaseUrl),
			pinned: item.pinned,
			createdLabel: relativeTimeId(item.created_at),
			createdBy: item.created_by ?? item.creator?.user_id ?? null,
			creatorName: item.creator?.full_name?.trim() || item.creator?.username || 'Portal SI'
		}))
	};
};

function parseAnnouncementForm(source: FormData) {
	const body = new FormData();
	const title = String(source.get('title') ?? '').trim();
	const content = String(source.get('content') ?? '').trim();
	if (title) body.set('title', title);
	if (content) body.set('content', content);
	body.set('pinned', source.get('pinned') === '1' ? '1' : '0');
	const image = source.get('image');
	if (image instanceof File && image.size > 0) body.set('image', image);
	return { body, title, content, image };
}

function failure(cause: unknown) {
	if (cause instanceof ApiError)
		return fail(cause.status, { message: cause.message, errors: cause.fieldErrors });
	throw cause;
}

export const actions: Actions = {
	create: async ({ request, locals }) => {
		if (!locals.token || !locals.user) return fail(401, { message: 'Sesi tidak tersedia.' });
		if (!['teacher', 'dev'].includes(locals.user.role))
			return fail(403, { message: 'Hanya guru dan dev yang dapat membuat pengumuman.' });
		const parsed = parseAnnouncementForm(await request.formData());
		if (!parsed.title && !parsed.content)
			return fail(422, { message: 'Isi judul atau konten pengumuman.' });
		if (parsed.title.length > 255) return fail(422, { message: 'Judul maksimal 255 karakter.' });
		if (parsed.image instanceof File && parsed.image.size > 50 * 1024 * 1024)
			return fail(422, { message: 'Gambar maksimal 50 MB.' });
		try {
			await backendRequest('announcements', {
				method: 'POST',
				token: locals.token,
				requestId: locals.requestId,
				body: parsed.body
			});
			return { success: true, message: 'Pengumuman berhasil diterbitkan.' };
		} catch (cause) {
			return failure(cause);
		}
	},
	update: async ({ request, locals, url }) => {
		if (!locals.token || !locals.user) return fail(401, { message: 'Sesi tidak tersedia.' });
		if (!['teacher', 'dev'].includes(locals.user.role))
			return fail(403, { message: 'Akses pengelolaan pengumuman ditolak.' });
		const id = Number.parseInt(url.searchParams.get('id') ?? '', 10);
		if (!Number.isSafeInteger(id) || id < 1)
			return fail(400, { message: 'Pengumuman tidak valid.' });
		const parsed = parseAnnouncementForm(await request.formData());
		if (!parsed.title && !parsed.content)
			return fail(422, { message: 'Isi judul atau konten pengumuman.' });
		if (parsed.title.length > 255) return fail(422, { message: 'Judul maksimal 255 karakter.' });
		if (parsed.image instanceof File && parsed.image.size > 50 * 1024 * 1024)
			return fail(422, { message: 'Gambar maksimal 50 MB.' });
		try {
			await backendRequest(`announcements/${id}`, {
				method: 'POST',
				token: locals.token,
				requestId: locals.requestId,
				body: parsed.body
			});
			return { success: true, message: 'Pengumuman berhasil diperbarui.' };
		} catch (cause) {
			return failure(cause);
		}
	},
	delete: async ({ locals, url }) => {
		if (!locals.token || !locals.user) return fail(401, { message: 'Sesi tidak tersedia.' });
		if (!['teacher', 'dev'].includes(locals.user.role))
			return fail(403, { message: 'Akses pengelolaan pengumuman ditolak.' });
		const id = Number.parseInt(url.searchParams.get('id') ?? '', 10);
		if (!Number.isSafeInteger(id) || id < 1)
			return fail(400, { message: 'Pengumuman tidak valid.' });
		try {
			await backendRequest(`announcements/${id}`, {
				method: 'DELETE',
				token: locals.token,
				requestId: locals.requestId
			});
			return { success: true, message: 'Pengumuman dihapus.' };
		} catch (cause) {
			return failure(cause);
		}
	}
};
