import { env } from '$env/dynamic/private';
import { z } from 'zod';
import type { RequestHandler } from './$types';

const artworkSchema = z
	.object({
		'150x150': z.string().url().optional(),
		'480x480': z.string().url().optional(),
		'1000x1000': z.string().url().optional()
	})
	.nullish();
const resultSchema = z.object({
	data: z.array(
		z
			.object({
				id: z.string().min(1),
				title: z.string().min(1),
				duration: z.coerce.number().positive(),
				is_streamable: z.boolean().optional().default(true),
				user: z.object({ name: z.string().min(1) }),
				artwork: artworkSchema
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
		const target = new URL(env.AUDIUS_API_URL?.trim() || 'https://api.audius.co/v1/tracks/search');
		if (target.protocol !== 'https:' || target.hostname !== 'api.audius.co')
			throw new Error('Origin not allowed');
		const appName = (env.AUDIUS_APP_NAME?.trim() || 'portal-si').slice(0, 40);
		target.searchParams.set('query', query);
		target.searchParams.set('limit', '8');
		target.searchParams.set('app_name', appName);
		const upstream = await fetch(target, {
			headers: { Accept: 'application/json' },
			signal: AbortSignal.timeout(8_000)
		});
		if (!upstream.ok) throw new Error('Upstream failed');
		const parsed = resultSchema.parse(await upstream.json());
		const streamBase = new URL('/v1/tracks/', target.origin);
		const value = {
			tracks: parsed.data
				.filter((track) => track.is_streamable && track.duration >= 5)
				.map((track) => ({
					id: track.id,
					title: track.title,
					artist: track.user.name,
					durationSeconds: Math.max(5, Math.round(track.duration)),
					previewUrl: `${streamBase}${encodeURIComponent(track.id)}/stream?app_name=${encodeURIComponent(appName)}`,
					artworkUrl:
						track.artwork?.['480x480'] ??
						track.artwork?.['150x150'] ??
						track.artwork?.['1000x1000'] ??
						null
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
