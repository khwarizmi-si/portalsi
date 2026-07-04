import { env } from '$env/dynamic/private';
import { z } from 'zod';
import type { RequestHandler } from './$types';

const resultSchema = z.object({
	resultCount: z.coerce.number().int().nonnegative(),
	results: z.array(
		z
			.object({
				trackId: z.coerce.number().int(),
				trackName: z.string(),
				artistName: z.string(),
				previewUrl: z.string().url().optional(),
				artworkUrl100: z.string().url().optional()
			})
			.passthrough()
	)
});
const cache = new Map<string, { expires: number; value: unknown }>();

export const GET: RequestHandler = async ({ locals, url }) => {
	if (!locals.token) return Response.json({ message: 'Sesi tidak tersedia.' }, { status: 401 });
	const query = (url.searchParams.get('q') ?? '').trim().slice(0, 80);
	if (query.length < 2) return Response.json({ tracks: [] });
	const key = query.toLocaleLowerCase('id-ID');
	const cached = cache.get(key);
	if (cached && cached.expires > Date.now()) return privateResponse(cached.value);
	try {
		const target = new URL(env.ITUNES_API_URL?.trim() || 'https://itunes.apple.com/search');
		if (target.protocol !== 'https:' || target.hostname !== 'itunes.apple.com')
			throw new Error('Origin not allowed');
		target.searchParams.set('term', query);
		target.searchParams.set('media', 'music');
		target.searchParams.set('entity', 'song');
		target.searchParams.set('limit', '8');
		const upstream = await fetch(target, {
			headers: { Accept: 'application/json' },
			signal: AbortSignal.timeout(7_000)
		});
		if (!upstream.ok) throw new Error('Upstream failed');
		const parsed = resultSchema.parse(await upstream.json());
		const value = {
			tracks: parsed.results.map((track) => ({
				id: track.trackId,
				title: track.trackName,
				artist: track.artistName,
				previewUrl: track.previewUrl ?? null,
				artworkUrl: track.artworkUrl100 ?? null
			}))
		};
		cache.set(key, { expires: Date.now() + 10 * 60_000, value });
		return privateResponse(value);
	} catch {
		return Response.json({ message: 'Pencarian musik sedang tidak tersedia.' }, { status: 503 });
	}
};

function privateResponse(value: unknown) {
	return Response.json(value, { headers: { 'Cache-Control': 'private, max-age=300' } });
}
