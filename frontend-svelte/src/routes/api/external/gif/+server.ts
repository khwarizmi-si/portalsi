import { env } from '$env/dynamic/private';
import { z } from 'zod';
import type { RequestHandler } from './$types';

// Tenor (Google) GIF/Sticker Search API. Butuh TENOR_API_KEY di environment.
const mediaFormat = z.object({ url: z.string().url(), dims: z.array(z.number()).optional() });
const resultSchema = z.object({
	results: z
		.array(
			z
				.object({
					id: z.union([z.string(), z.number()]).transform(String),
					content_description: z.string().optional(),
					media_formats: z.record(z.string(), mediaFormat.partial()).optional()
				})
				.passthrough()
		)
		.catch([])
});

const cache = new Map<string, { expires: number; value: unknown }>();

export const GET: RequestHandler = async ({ locals, url }) => {
	if (!locals.token) return Response.json({ message: 'Sesi tidak tersedia.' }, { status: 401 });

	const apiKey = env.TENOR_API_KEY?.trim();
	if (!apiKey) return Response.json({ results: [], message: 'GIF belum dikonfigurasi.' });

	const query = (url.searchParams.get('q') ?? '').trim().slice(0, 60);
	const type = url.searchParams.get('type') === 'sticker' ? 'sticker' : 'gif';
	const key = `${type}:${query.toLocaleLowerCase('id-ID')}`;
	const cached = cache.get(key);
	if (cached && cached.expires > Date.now()) return privateResponse(cached.value);

	try {
		const endpoint = query.length >= 2 ? 'search' : 'featured';
		const target = new URL(`https://tenor.googleapis.com/v2/${endpoint}`);
		target.searchParams.set('key', apiKey);
		target.searchParams.set('client_key', 'portalsi');
		target.searchParams.set('limit', '24');
		target.searchParams.set('contentfilter', 'high');
		target.searchParams.set('media_filter', 'gif,tinygif');
		if (type === 'sticker') target.searchParams.set('searchfilter', 'sticker');
		if (endpoint === 'search') target.searchParams.set('q', query);

		const upstream = await fetch(target, {
			headers: { Accept: 'application/json' },
			signal: AbortSignal.timeout(8_000)
		});
		if (!upstream.ok) throw new Error('Upstream failed');
		const parsed = resultSchema.parse(await upstream.json());
		const results = parsed.results
			.map((item) => {
				const formats = item.media_formats ?? {};
				const full = formats.gif?.url ?? formats.mediumgif?.url ?? formats.tinygif?.url;
				const preview = formats.tinygif?.url ?? formats.nanogif?.url ?? full;
				const dims = formats.tinygif?.dims ?? formats.gif?.dims ?? [1, 1];
				if (!full || !preview) return null;
				return {
					id: item.id,
					url: full,
					preview,
					width: dims[0] ?? 1,
					height: dims[1] ?? 1,
					alt: item.content_description ?? 'GIF'
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
