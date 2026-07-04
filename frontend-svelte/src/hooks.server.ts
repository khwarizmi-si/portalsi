import { dev } from '$app/environment';
import type { Handle } from '@sveltejs/kit';
import { ApiError } from '$lib/api/errors';
import { clearSessionCookie, fetchSessionUser, readSessionToken } from '$lib/server/session';

const unsafeMethods = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);

export const handle: Handle = async ({ event, resolve }) => {
	event.locals.requestId = event.request.headers.get('x-request-id') ?? crypto.randomUUID();
	event.locals.token = readSessionToken(event.cookies);
	event.locals.user = null;
	event.locals.sessionUnavailable = false;

	if (unsafeMethods.has(event.request.method)) {
		const origin = event.request.headers.get('origin');
		if (origin && origin !== event.url.origin) {
			return new Response('Origin tidak diizinkan.', { status: 403 });
		}
	}

	const requiresSessionUser =
		!event.url.pathname.startsWith('/api/') && event.url.pathname !== '/logout';
	if (event.locals.token && requiresSessionUser) {
		try {
			event.locals.user = await fetchSessionUser(event.locals.token, event.locals.requestId);
		} catch (error) {
			if (error instanceof ApiError && error.status === 401) {
				clearSessionCookie(event.cookies);
				event.locals.token = null;
			} else {
				event.locals.sessionUnavailable = true;
			}
		}
	}

	const response = await resolve(event);
	response.headers.set('X-Request-ID', event.locals.requestId);
	response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
	response.headers.set('X-Content-Type-Options', 'nosniff');
	response.headers.set('X-Frame-Options', 'DENY');
	response.headers.set('Permissions-Policy', 'camera=(self), microphone=(), geolocation=(self)');
	response.headers.set('Content-Security-Policy', contentSecurityPolicy(dev));
	if (event.locals.token || event.url.pathname.startsWith('/api/')) {
		response.headers.set('Cache-Control', 'private, no-store');
	}
	return response;
};

function contentSecurityPolicy(isDevelopment: boolean): string {
	const scriptSource = isDevelopment ? "'self' 'unsafe-inline' 'unsafe-eval'" : "'self'";
	const connectSource = isDevelopment
		? "'self' ws: wss: http: https:"
		: "'self' https://api.portalsi.com wss://ws.portalsi.com";
	return [
		"default-src 'self'",
		`script-src ${scriptSource}`,
		"style-src 'self' 'unsafe-inline'",
		"img-src 'self' data: blob: https:",
		"media-src 'self' blob: https:",
		"font-src 'self'",
		`connect-src ${connectSource}`,
		"frame-src 'none'",
		"frame-ancestors 'none'",
		"base-uri 'self'",
		"form-action 'self'",
		"object-src 'none'"
	].join('; ');
}
