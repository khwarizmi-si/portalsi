import type { ZodError } from 'zod';

export function formFieldErrors(error: ZodError): Record<string, string[]> {
	const result: Record<string, string[]> = {};
	for (const issue of error.issues) {
		const field = String(issue.path[0] ?? 'form');
		(result[field] ??= []).push(issue.message);
	}
	return result;
}

export function safeRedirectTarget(value: string | null, fallback = '/home'): string {
	if (!value?.startsWith('/') || value.startsWith('//') || value.includes('\\')) return fallback;
	return value;
}
