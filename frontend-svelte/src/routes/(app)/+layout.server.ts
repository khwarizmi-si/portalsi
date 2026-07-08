import { error, redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = ({ locals, url }) => {
	if (locals.sessionUnavailable) {
		error(503, {
			message: 'Layanan sesi sedang tidak dapat dijangkau. Coba muat ulang halaman.',
			requestId: locals.requestId
		});
	}
	const isPublicProfile = /^\/u\/[^/]+\/?$/.test(url.pathname);
	const isLegal = url.pathname.startsWith('/legal');
	const isPost = /^\/posts\/\d+\/?$/.test(url.pathname);
	if (!locals.user && !isPublicProfile && !isLegal && !isPost) {
		const next = `${url.pathname}${url.search}`;
		redirect(303, `/login?next=${encodeURIComponent(next)}`);
	}
	return { user: locals.user };
};
