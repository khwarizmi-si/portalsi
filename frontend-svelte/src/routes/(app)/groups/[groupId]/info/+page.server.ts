import { env } from '$env/dynamic/public';
import { ApiError } from '$lib/api/errors';
import {
	groupDetailResponseSchema,
	groupMembersResponseSchema,
	groupRoleResponseSchema
} from '$lib/schemas/chat';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { error, fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

function numericId(value: string | null | undefined) {
	const id = Number.parseInt(value ?? '', 10);
	return Number.isSafeInteger(id) && id > 0 ? id : null;
}

function apiFailure(cause: unknown) {
	if (cause instanceof ApiError)
		return fail(cause.status, { message: cause.message, errors: cause.fieldErrors });
	throw cause;
}

type ActionEvent = Parameters<Actions[string]>[0];

async function memberMutation(
	event: ActionEvent,
	operation: 'promote' | 'demote' | 'mute' | 'unmute' | 'remove'
) {
	if (!event.locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
	const groupId = numericId(event.params.groupId);
	const userId = numericId(event.url.searchParams.get('userId'));
	if (!groupId || !userId)
		return fail(400, { message: 'Identitas grup atau anggota tidak valid.' });
	try {
		await backendRequest(
			`groups/${groupId}/members/${userId}${operation === 'remove' ? '' : `/${operation}`}`,
			{
				method: operation === 'remove' ? 'DELETE' : 'POST',
				token: event.locals.token,
				requestId: event.locals.requestId
			}
		);
		return { success: true, message: 'Keanggotaan berhasil diperbarui.' };
	} catch (cause) {
		return apiFailure(cause);
	}
}

export const load: PageServerLoad = async ({ locals, params }) => {
	if (!locals.token || !locals.user) error(401, 'Sesi tidak tersedia.');
	const groupId = numericId(params.groupId);
	if (!groupId) error(404, 'Grup tidak ditemukan.');
	const [detail, groupedMembers, role] = await Promise.all([
		backendRequest(`groups/${groupId}`, {
			token: locals.token,
			requestId: locals.requestId,
			schema: groupDetailResponseSchema
		}),
		backendRequest(`groups/${groupId}/members`, {
			token: locals.token,
			requestId: locals.requestId,
			schema: groupMembersResponseSchema
		}),
		backendRequest(`groups/${groupId}/role`, {
			token: locals.token,
			requestId: locals.requestId,
			schema: groupRoleResponseSchema
		})
	]);
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	const members = [
		...groupedMembers.me,
		...groupedMembers.following,
		...groupedMembers.not_following
	].map((member) => ({
		...member,
		fullName: member.full_name?.trim() || member.username,
		avatarUrl: normalizeMediaUrl(member.profile_picture_url, mediaBaseUrl)
	}));
	return {
		group: {
			...detail.group,
			avatarUrl: normalizeMediaUrl(detail.group.avatar_url, mediaBaseUrl),
			coverUrl: normalizeMediaUrl(detail.group.cover_url, mediaBaseUrl)
		},
		members,
		role: role.role,
		currentUserId: locals.user.id,
		isOwner: detail.group.owner.user_id === locals.user.id
	};
};

export const actions: Actions = {
	update: async ({ request, locals, params }) => {
		if (!locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
		const groupId = numericId(params.groupId);
		if (!groupId) return fail(400, { message: 'Grup tidak valid.' });
		const source = await request.formData();
		const name = String(source.get('name') ?? '').trim();
		if (!name || name.length > 100)
			return fail(422, { message: 'Nama grup wajib diisi dan maksimal 100 karakter.' });
		const body = new FormData();
		body.set('name', name);
		body.set('description', String(source.get('description') ?? '').trim());
		for (const field of ['avatar', 'cover'] as const) {
			const file = source.get(field);
			if (!(file instanceof File) || file.size === 0) continue;
			if (file.size > 10 * 1024 * 1024)
				return fail(422, { message: 'Avatar dan sampul maksimal 10 MB.' });
			if (!['image/jpeg', 'image/png'].includes(file.type))
				return fail(422, { message: 'Avatar dan sampul harus berupa JPG atau PNG.' });
			body.set(field, file);
		}
		try {
			await backendRequest(`groups/${groupId}`, {
				method: 'POST',
				token: locals.token,
				requestId: locals.requestId,
				body
			});
			return { success: true, message: 'Info grup berhasil disimpan.' };
		} catch (cause) {
			return apiFailure(cause);
		}
	},
	add: async ({ request, locals, params }) => {
		if (!locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
		const groupId = numericId(params.groupId);
		const source = await request.formData();
		const identifier = String(source.get('identifier') ?? '')
			.trim()
			.replace(/^@/, '');
		const role = source.get('role') === 'admin' ? 'admin' : 'member';
		if (!groupId || !identifier) return fail(422, { message: 'Username atau email wajib diisi.' });
		try {
			await backendRequest(`groups/${groupId}/members`, {
				method: 'POST',
				token: locals.token,
				requestId: locals.requestId,
				body: { identifier, role }
			});
			return { success: true, message: 'Anggota berhasil ditambahkan.' };
		} catch (cause) {
			return apiFailure(cause);
		}
	},
	promote: (event) => memberMutation(event, 'promote'),
	demote: (event) => memberMutation(event, 'demote'),
	mute: (event) => memberMutation(event, 'mute'),
	unmute: (event) => memberMutation(event, 'unmute'),
	remove: (event) => memberMutation(event, 'remove'),
	leave: async ({ locals, params }) => {
		if (!locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
		const groupId = numericId(params.groupId);
		if (!groupId) return fail(400, { message: 'Grup tidak valid.' });
		try {
			await backendRequest(`groups/${groupId}/leave`, {
				method: 'POST',
				token: locals.token,
				requestId: locals.requestId
			});
		} catch (cause) {
			return apiFailure(cause);
		}
		redirect(303, '/messages');
	},
	delete: async ({ locals, params }) => {
		if (!locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
		const groupId = numericId(params.groupId);
		if (!groupId) return fail(400, { message: 'Grup tidak valid.' });
		try {
			await backendRequest(`groups/${groupId}`, {
				method: 'DELETE',
				token: locals.token,
				requestId: locals.requestId
			});
		} catch (cause) {
			return apiFailure(cause);
		}
		redirect(303, '/messages');
	}
};
