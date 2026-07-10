import type { ZodType } from 'zod';
import { finishProgress, startProgress } from '$lib/ui/progress';

export class ClientApiError extends Error {
	constructor(
		message: string,
		readonly status: number
	) {
		super(message);
		this.name = 'ClientApiError';
	}
}

export async function clientRequest<T = unknown>(
	path: string,
	options: RequestInit & { schema?: ZodType<T> } = {}
): Promise<T> {
	const cleanPath = path.replace(/^\/+/, '');
	if (
		!cleanPath ||
		cleanPath.includes('://') ||
		cleanPath.includes('\\') ||
		cleanPath.split('/').some((segment) => segment === '.' || segment === '..')
	)
		throw new Error('BFF path harus relatif dan tidak boleh mengandung traversal.');

	const { schema, ...requestOptions } = options;
	let succeeded = false;
	startProgress();
	try {
		const response = await fetch(`/api/${cleanPath}`, {
			...requestOptions,
			headers: { Accept: 'application/json', ...requestOptions.headers }
		});
		const payload = await readPayload(response);
		if (!response.ok) {
			const message =
				payload && typeof payload === 'object' && 'message' in payload
					? String(payload.message)
					: 'Permintaan tidak dapat diproses.';
			throw new ClientApiError(message, response.status);
		}
		if (!schema) {
			succeeded = true;
			return payload as T;
		}
		const parsed = schema.safeParse(payload);
		if (!parsed.success) throw new ClientApiError('Respons layanan tidak sesuai kontrak.', 502);
		succeeded = true;
		return parsed.data;
	} finally {
		finishProgress(succeeded);
	}
}

async function readPayload(response: Response): Promise<unknown> {
	const text = await response.text();
	if (!text) return null;
	try {
		return JSON.parse(text) as unknown;
	} catch {
		return text;
	}
}
