import { afterEach, describe, expect, it, vi } from 'vitest';
import { z } from 'zod';
import { ClientApiError, clientRequest } from './client';

afterEach(() => vi.unstubAllGlobals());

describe('clientRequest', () => {
	it('routes requests through the same-origin BFF and validates responses', async () => {
		const fetchMock = vi.fn().mockResolvedValue(
			new Response(JSON.stringify({ id: 4 }), {
				status: 200,
				headers: { 'Content-Type': 'application/json' }
			})
		);
		vi.stubGlobal('fetch', fetchMock);

		await expect(
			clientRequest('posts/4', { schema: z.object({ id: z.number() }) })
		).resolves.toEqual({ id: 4 });
		expect(fetchMock).toHaveBeenCalledWith(
			'/api/posts/4',
			expect.objectContaining({ headers: expect.any(Object) })
		);
	});

	it('surfaces sanitized BFF errors with their status', async () => {
		vi.stubGlobal(
			'fetch',
			vi.fn().mockResolvedValue(Response.json({ message: 'Tidak diizinkan.' }, { status: 403 }))
		);
		await expect(clientRequest('posts/4', { method: 'DELETE' })).rejects.toMatchObject({
			status: 403,
			message: 'Tidak diizinkan.'
		} satisfies Partial<ClientApiError>);
	});

	it('refuses absolute URLs before issuing a request', async () => {
		const fetchMock = vi.fn();
		vi.stubGlobal('fetch', fetchMock);
		await expect(clientRequest('https://attacker.example/data')).rejects.toThrow('harus relatif');
		expect(fetchMock).not.toHaveBeenCalled();
	});
});
