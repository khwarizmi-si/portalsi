import { env } from '$env/dynamic/private';
import { z } from 'zod';
import type { RequestHandler } from './$types';

// GIPHY GIF/Sticker API. Butuh GIPHY_API_KEY di environment.
// (Tenor resmi dimatikan 30 Juni 2026; GIPHY adalah penggantinya.)
const imageSchema = z
	.object({
		url: z.string().url().optional(),
		width: z.coerce.number().optional(),
		height: z.coerce.number().optional()
	})
	.partial();

const resultSchema = z.object({
	data: z
		.array(
			z
				.object({
					id: z.union([z.string(), z.number()]).transform(String),
					title: z.string().optional(),
					images: z.record(z.string(), imageSchema).optional()
				})
				.passthrough()
		)
		.catch([])
});

const cache = new Map<string, { expires: number; value: unknown }>();

export const GET: RequestHandler = async ({ locals, url }) => {
	if (!locals.token) return Response.json({ message: 'Sesi tidak tersedia.' }, { status: 401 });

	const apiKey = env.GIPHY_API_KEY?.trim();
	if (!apiKey) return Response.json({ results: [], message: 'GIF belum dikonfigurasi.' });

	const query = (url.searchParams.get('q') ?? '').trim().slice(0, 60);
	const type = url.searchParams.get('type') === 'sticker' ? 'stickers' : 'gifs';
	const key = `${type}:${query.toLocaleLowerCase('id-ID')}`;
	const cached = cache.get(key);
	if (cached && cached.expires > Date.now()) return privateResponse(cached.value);

	try {
		const endpoint = query.length >= 2 ? 'search' : 'trending';
		const target = new URL(`https://api.giphy.com/v1/${type}/${endpoint}`);
		target.searchParams.set('api_key', apiKey);
		target.searchParams.set('limit', '24');
		target.searchParams.set('rating', 'g');
		target.searchParams.set('bundle', 'messaging_non_clips');
		if (endpoint === 'search') target.searchParams.set('q', query);

		const upstream = await fetch(target, {
			headers: { Accept: 'application/json' },
			signal: AbortSignal.timeout(8_000)
		});
		if (!upstream.ok) throw new Error('Upstream failed');
		const parsed = resultSchema.parse(await upstream.json());
		const results = parsed.data
			.map((item) => {
				const images = item.images ?? {};
				const full = images.downsized?.url ?? images.original?.url ?? images.fixed_width?.url;
				const preview =
					images.fixed_width?.url ?? images.fixed_width_small?.url ?? images.downsized?.url ?? full;
				const dims = images.fixed_width ?? images.original ?? {};
				if (!full || !preview) return null;
				return {
					id: item.id,
					url: full,
					preview,
					width: dims.width ?? 1,
					height: dims.height ?? 1,
					alt: item.title ?? 'GIF'
				};
			})
			.filter((item): item is NonNullable<typeof item> => item !== null);

		const value = { results };
		cache.set(key, { expires: Date.now() + 10 * 60_000, value });
		return privateResponse(value);
	} catch {
		return Response.json({ message: 'Pencarian GIF sedang tidak tersedia.' }, { status: 503 });
	}
};

function privateResponse(value: unknown) {
	return Response.json(value, { headers: { 'Cache-Control': 'private, max-age=300' } });
}
