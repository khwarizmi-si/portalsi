import type { RequestHandler } from './$types';
import { buildBackendUrl } from '$lib/server/api';
import { clearSessionCookie } from '$lib/server/session';

const supportedMethods = new Set(['GET', 'POST', 'PUT', 'PATCH', 'DELETE']);

const proxy: RequestHandler = async ({ request, params, url, locals, cookies }) => {
	const isPublicProfileRead =
		request.method === 'GET' && Boolean(params.path?.match(/^profile\/[^/]+$/));
	if (!locals.token && !isPublicProfileRead) {
		return Response.json({ message: 'Sesi tidak tersedia.' }, { status: 401 });
	}
	if (
		!params.path ||
		params.path.includes('://') ||
		params.path.includes('\\') ||
		params.path.split('/').some((segment) => segment === '.' || segment === '..') ||
		!supportedMethods.has(request.method)
	) {
		return Response.json({ message: 'Endpoint BFF tidak valid.' }, { status: 400 });
	}

	const target = buildBackendUrl(params.path);
	target.search = url.search;
	const headers = new Headers({ Accept: 'application/json', 'X-Request-ID': locals.requestId });
	if (locals.token) headers.set('Authorization', `Bearer ${locals.token}`);
	const contentType = request.headers.get('content-type');
	if (contentType) headers.set('Content-Type', contentType);
	const isUpload = contentType?.toLowerCase().startsWith('multipart/form-data') ?? false;

	let backendResponse: Response;
	try {
		const requestInit: RequestInit & { duplex?: 'half' } = {
			method: request.method,
			headers,
			signal: AbortSignal.timeout(isUpload ? 10 * 60_000 : 30_000),
			redirect: 'manual'
		};
		if (!['GET', 'HEAD'].includes(request.method) && request.body) {
			requestInit.body = request.body;
			requestInit.duplex = 'half';
		}
		backendResponse = await fetch(target, requestInit);
	} catch {
		return Response.json(
			{ message: 'Tidak dapat terhubung ke layanan Portal SI.', request_id: locals.requestId },
			{ status: 503 }
		);
	}

	if (backendResponse.status === 401) clearSessionCookie(cookies);
	const responseHeaders = new Headers({ 'Cache-Control': 'private, no-store' });
	for (const name of ['content-type', 'retry-after', 'x-request-id']) {
		const value = backendResponse.headers.get(name);
		if (value) responseHeaders.set(name, value);
	}

	return new Response(backendResponse.body, {
		status: backendResponse.status,
		statusText: backendResponse.statusText,
		headers: responseHeaders
	});
};

export const GET = proxy;
export const POST = proxy;
export const PUT = proxy;
export const PATCH = proxy;
export const DELETE = proxy;
