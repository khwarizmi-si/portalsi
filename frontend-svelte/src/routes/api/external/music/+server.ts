import { env } from '$env/dynamic/private';
import { z } from 'zod';
import type { RequestHandler } from './$types';

// Apple Music / iTunes Search API. Preview resmi 30 detik.
const resultSchema = z.object({
	results: z.array(
		z
			.object({
				trackId: z.coerce.number(),
				trackName: z.string().min(1),
				artistName: z.string().min(1),
				previewUrl: z.string().url().optional(),
				artworkUrl100: z.string().url().optional(),
				trackTimeMillis: z.coerce.number().optional()
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
		target.searchParams.set('limit', '12');
		const upstream = await fetch(target, {
			headers: { Accept: 'application/json' },
			signal: AbortSignal.timeout(8_000)
		});
		if (!upstream.ok) throw new Error('Upstream failed');
		const parsed = resultSchema.parse(await upstream.json());
		const value = {
			tracks: parsed.results
				.filter((track) => Boolean(track.previewUrl))
				.slice(0, 8)
				.map((track) => ({
					id: String(track.trackId),
					title: track.trackName,
					artist: track.artistName,
					// Preview iTunes = 30 detik.
					durationSeconds: 30,
					previewUrl: track.previewUrl as string,
					artworkUrl: track.artworkUrl100
						? track.artworkUrl100.replace('100x100bb', '300x300bb').replace('100x100', '300x300')
						: null
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
