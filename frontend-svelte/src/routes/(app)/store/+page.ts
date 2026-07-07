import { redirect } from '@sveltejs/kit';
import type { PageLoad } from './$types';

// "Store" kini bernama "Marketplace". Alihkan URL lama ke yang baru.
export const load: PageLoad = () => {
	redirect(308, '/marketplace');
};
