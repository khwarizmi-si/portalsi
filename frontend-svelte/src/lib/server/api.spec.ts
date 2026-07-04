import { afterEach, describe, expect, it, vi } from 'vitest';
import { z } from 'zod';
import { ApiError } from '$lib/api/errors';
import { backendRequest, buildBackendUrl } from './api';

afterEach(() => {
	vi.unstubAllGlobals();
});

describe('backendRequest', () => {
	it('adds API headers and validates a successful response', async () => {
		const fetchMock = vi
			.fn<typeof fetch>()
			.mockResolvedValue(
				Response.json({ message: 'ok' }, { headers: { 'x-request-id': 'backend-1' } })
			);
		vi.stubGlobal('fetch', fetchMock);

		const result = await backendRequest('health', {
			token: 'secret-token',
			requestId: 'web-1',
			schema: z.object({ message: z.literal('ok') })
		});

		expect(result).toEqual({ message: 'ok' });
		const [, init] = fetchMock.mock.calls[0];
		const headers = new Headers(init?.headers);
		expect(headers.get('authorization')).toBe('Bearer secret-token');
		expect(headers.get('accept')).toBe('application/json');
	});

	it('maps a backend validation response to ApiError', async () => {
		vi.stubGlobal(
			'fetch',
			vi
				.fn<typeof fetch>()
				.mockResolvedValue(
					Response.json(
						{ message: 'Validation failed', errors: { caption: ['Caption terlalu panjang.'] } },
						{ status: 422 }
					)
				)
		);

		await expect(backendRequest('posts', { method: 'POST', body: {} })).rejects.toMatchObject({
			status: 422,
			fieldErrors: { caption: ['Caption terlalu panjang.'] }
		} satisfies Partial<ApiError>);
	});

	it('fails fast after a network error without duplicating a slow GET', async () => {
		const fetchMock = vi.fn<typeof fetch>().mockRejectedValueOnce(new TypeError('network down'));
		vi.stubGlobal('fetch', fetchMock);

		await expect(
			backendRequest('posts', { schema: z.object({ value: z.number() }) })
		).rejects.toMatchObject({ status: 503 });
		expect(fetchMock).toHaveBeenCalledTimes(1);
	});

	it('rejects absolute and traversing backend paths', () => {
		expect(() => buildBackendUrl('https://attacker.example')).toThrow('harus relatif');
		expect(() => buildBackendUrl('../broadcasting/auth')).toThrow('traversal');
		expect(() => buildBackendUrl('posts\\..\\admin')).toThrow('traversal');
	});
});
