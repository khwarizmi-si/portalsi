import type { ZodType } from 'zod';
import { ApiContractError, ApiError, parseBackendError } from '$lib/api/errors';
import { apiBaseUrl } from './env';

type RequestBody = BodyInit | Record<string, unknown> | null;

interface BackendRequestOptions<T> {
	method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
	token?: string | null;
	body?: RequestBody;
	query?: Record<string, string | number | boolean | null | undefined>;
	schema?: ZodType<T>;
	timeoutMs?: number;
	requestId?: string;
	signal?: AbortSignal;
}

export async function backendRequest<T = unknown>(
	path: string,
	options: BackendRequestOptions<T> = {}
): Promise<T> {
	const method = options.method ?? 'GET';
	const url = buildBackendUrl(path, options.query);
	const headers = new Headers({ Accept: 'application/json' });
	if (options.token) headers.set('Authorization', `Bearer ${options.token}`);
	if (options.requestId) headers.set('X-Request-ID', options.requestId);

	const body = serializeBody(options.body, headers);
	const attempts = 1;
	let lastError: unknown;

	for (let attempt = 0; attempt < attempts; attempt += 1) {
		const defaultTimeout = body instanceof FormData ? 10 * 60_000 : 8_000;
		const timeout = AbortSignal.timeout(options.timeoutMs ?? defaultTimeout);
		const signal = options.signal ? AbortSignal.any([options.signal, timeout]) : timeout;

		try {
			const response = await fetch(url, { method, headers, body, signal, redirect: 'manual' });
			const requestId = response.headers.get('x-request-id') ?? options.requestId;
			const payload = await readResponse(response);

			if (!response.ok) {
				throw parseBackendError(
					response.status,
					payload,
					requestId,
					response.headers.get('retry-after')
				);
			}

			if (!options.schema) return payload as T;
			const parsed = options.schema.safeParse(payload);
			if (!parsed.success) {
				throw new ApiContractError(
					`Respons backend untuk ${method} ${url.pathname} tidak sesuai kontrak.`,
					requestId
				);
			}
			return parsed.data;
		} catch (error) {
			if (error instanceof ApiError) throw error;
			lastError = error;
			if (attempt + 1 < attempts && !options.signal?.aborted) continue;
		}
	}

	throw new ApiError({
		status: 503,
		message: 'Tidak dapat terhubung ke layanan Portal SI. Coba lagi sebentar.',
		requestId: options.requestId,
		code: lastError instanceof Error ? lastError.name : 'NETWORK_ERROR'
	});
}

export function buildBackendUrl(
	path: string,
	query?: Record<string, string | number | boolean | null | undefined>
): URL {
	const cleanPath = path.replace(/^\/+/, '');
	if (
		cleanPath.includes('://') ||
		cleanPath.includes('\\') ||
		cleanPath.split('/').some((segment) => segment === '.' || segment === '..')
	)
		throw new Error('Backend path harus relatif dan tidak boleh mengandung traversal.');
	const url = new URL(`/api/${cleanPath}`, apiBaseUrl());
	for (const [key, value] of Object.entries(query ?? {})) {
		if (value !== null && value !== undefined) url.searchParams.set(key, String(value));
	}
	return url;
}

function serializeBody(
	body: RequestBody | undefined,
	headers: Headers
): BodyInit | null | undefined {
	if (body === undefined || body === null) return body;
	if (
		typeof body === 'string' ||
		body instanceof FormData ||
		body instanceof URLSearchParams ||
		body instanceof Blob ||
		body instanceof ArrayBuffer
	) {
		return body;
	}
	headers.set('Content-Type', 'application/json');
	return JSON.stringify(body);
}

async function readResponse(response: Response): Promise<unknown> {
	if (response.status === 204) return null;
	const text = await response.text();
	if (!text) return null;
	const contentType = response.headers.get('content-type') ?? '';
	if (!contentType.includes('application/json')) return text;
	try {
		return JSON.parse(text) as unknown;
	} catch {
		throw new ApiContractError('Backend mengembalikan JSON yang tidak valid.');
	}
}
