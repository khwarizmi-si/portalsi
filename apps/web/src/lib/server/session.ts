import { dev } from '$app/environment';
import type { Cookies } from '@sveltejs/kit';
import { backendUserSchema, toSessionUser, type SessionUser } from '$lib/schemas/user';
import { backendRequest } from './api';

export const SESSION_COOKIE = 'portal_si_session';

export function readSessionToken(cookies: Cookies): string | null {
	return cookies.get(SESSION_COOKIE) ?? null;
}

export function setSessionCookie(cookies: Cookies, token: string, remember: boolean): void {
	cookies.set(SESSION_COOKIE, token, {
		path: '/',
		httpOnly: true,
		secure: !dev,
		sameSite: 'lax',
		maxAge: 60 * 60 * 24 * (remember ? 90 : 30)
	});
}

export function clearSessionCookie(cookies: Cookies): void {
	cookies.delete(SESSION_COOKIE, { path: '/' });
}

export async function fetchSessionUser(token: string, requestId: string): Promise<SessionUser> {
	const user = await backendRequest('user', {
		token,
		requestId,
		schema: backendUserSchema,
		timeoutMs: 6_000
	});
	return toSessionUser(user);
}
