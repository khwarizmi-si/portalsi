import { notificationPreferencesResponseSchema } from '$lib/schemas/notification';
import { backendRequest } from '$lib/server/api';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

const fallback = {
	new_post_reminders: 'all' as const,
	likes: true,
	comments: true,
	mentions: true,
	follows: true
};

export const load: PageServerLoad = async ({ locals }) => {
	if (!locals.token || !locals.user) error(401, 'Sesi Anda tidak tersedia.');
	try {
		const response = await backendRequest('notifications/preferences', {
			token: locals.token,
			requestId: locals.requestId,
			schema: notificationPreferencesResponseSchema
		});
		return { preferences: response.preferences, available: true };
	} catch {
		return { preferences: fallback, available: false };
	}
};
