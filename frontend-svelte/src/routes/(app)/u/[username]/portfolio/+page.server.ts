import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
export const load: PageServerLoad = async ({ params }) => {
	redirect(303, `/u/${encodeURIComponent(params.username)}?tab=portfolio`);
};
