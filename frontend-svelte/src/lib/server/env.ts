import { env } from '$env/dynamic/private';

export function apiBaseUrl(): URL {
	const configured = env.API_BASE_URL?.trim() || 'https://api.portalsi.com';
	const url = new URL(configured);
	url.pathname = url.pathname.replace(/\/+$/, '').replace(/\/api$/, '');
	url.search = '';
	url.hash = '';
	return url;
}
