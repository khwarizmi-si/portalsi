import { env } from '$env/dynamic/public';
import { ApiError } from '$lib/api/errors';
import { portfoliosResponseSchema } from '$lib/schemas/portfolio';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { error, fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
const aspects = new Set(['quran', 'it', 'bahasa', 'karakter']);
export const load: PageServerLoad = async ({ locals, url }) => {
	if (!locals.token || !locals.user) error(401, 'Sesi tidak tersedia.');
	if (!locals.user.emailVerified)
		error(403, 'Verifikasi email diperlukan untuk membuka portfolio.');
	const requested = url.searchParams.get('aspect') || '';
	const aspect = aspects.has(requested) ? requested : '';
	const response = await backendRequest('portfolios', {
		token: locals.token,
		requestId: locals.requestId,
		query: aspect ? { aspect } : undefined,
		schema: portfoliosResponseSchema
	});
	const media = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	return {
		aspect,
		canCreate: ['teacher', 'dev'].includes(locals.user.role) || locals.user.badgeVerified,
		items: response.portfolios.map((item) => ({
			...item,
			mediaUrl: normalizeMediaUrl(item.media_url, media)
		}))
	};
};

function allowed(user: App.Locals['user']) {
	return Boolean(user && (['teacher', 'dev'].includes(user.role) || user.badgeVerified));
}

function actionFailure(cause: unknown) {
	if (cause instanceof ApiError)
		return fail(cause.status, { message: cause.message, errors: cause.fieldErrors });
	throw cause;
}

export const actions: Actions = {
	update: async ({ request, locals, url }) => {
		if (!locals.token || !allowed(locals.user)) return fail(403, { message: 'Akses ditolak.' });
		const id = Number.parseInt(url.searchParams.get('id') ?? '', 10);
		if (!Number.isSafeInteger(id) || id < 1)
			return fail(400, { message: 'Portfolio tidak valid.' });
		const source = await request.formData();
		const aspect = String(source.get('aspect') ?? '');
		const title = String(source.get('title') ?? '').trim();
		const year = String(source.get('year') ?? '').trim();
		if (!aspects.has(aspect) || !title || title.length > 255)
			return fail(422, { message: 'Kategori dan judul yang valid wajib diisi.' });
		const currentYear = new Date().getFullYear();
		if (year && (!/^\d{4}$/.test(year) || Number(year) < 2000 || Number(year) > currentYear))
			return fail(422, { message: `Tahun harus antara 2000 dan ${currentYear}.` });
		const body = new FormData();
		body.set('aspect', aspect);
		body.set('title', title);
		body.set('description', String(source.get('description') ?? '').trim());
		if (year) body.set('year', year);
		const media = source.get('media');
		if (media instanceof File && media.size > 0) {
			if (media.size > 50 * 1024 * 1024) return fail(422, { message: 'Media maksimal 50 MB.' });
			if (!['image/jpeg', 'image/png', 'application/pdf'].includes(media.type))
				return fail(422, { message: 'Media harus berupa JPG, PNG, atau PDF.' });
			body.set('media', media);
		}
		try {
			await backendRequest(`portfolios/${id}`, {
				method: 'POST',
				token: locals.token,
				requestId: locals.requestId,
				body
			});
			return { success: true, message: 'Portfolio berhasil diperbarui.' };
		} catch (cause) {
			return actionFailure(cause);
		}
	},
	delete: async ({ locals, url }) => {
		if (!locals.token || !allowed(locals.user)) return fail(403, { message: 'Akses ditolak.' });
		const id = Number.parseInt(url.searchParams.get('id') ?? '', 10);
		if (!Number.isSafeInteger(id) || id < 1)
			return fail(400, { message: 'Portfolio tidak valid.' });
		try {
			await backendRequest(`portfolios/${id}`, {
				method: 'DELETE',
				token: locals.token,
				requestId: locals.requestId
			});
			return { success: true, message: 'Portfolio berhasil dihapus.' };
		} catch (cause) {
			return actionFailure(cause);
		}
	}
};
