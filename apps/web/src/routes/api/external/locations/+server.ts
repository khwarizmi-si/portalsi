import { env } from '$env/dynamic/private';
import { z } from 'zod';
import type { RequestHandler } from './$types';

const resultSchema = z.array(
	z
		.object({
			place_id: z.coerce.number().int(),
			display_name: z.string(),
			lat: z.string(),
			lon: z.string(),
			type: z.string().optional()
		})
		.passthrough()
);
const cache = new Map<string, { expires: number; value: unknown }>();

export const GET: RequestHandler = async ({ locals, url, request }) => {
	if (!locals.token) return Response.json({ message: 'Sesi tidak tersedia.' }, { status: 401 });
	const query = (url.searchParams.get('q') ?? '').trim().slice(0, 100);
	if (query.length < 3) return Response.json({ locations: [] });
	const key = query.toLocaleLowerCase('id-ID');
	const cached = cache.get(key);
	if (cached && cached.expires > Date.now()) return privateResponse(cached.value);
	try {
		const target = new URL(env.NOMINATIM_API_URL?.trim() || 'https://nominatim.openstreetmap.org');
		if (target.protocol !== 'https:' || target.hostname !== 'nominatim.openstreetmap.org')
			throw new Error('Origin not allowed');
		target.pathname = `${target.pathname.replace(/\/$/, '')}/search`;
		target.searchParams.set('q', query);
		target.searchParams.set('format', 'jsonv2');
		target.searchParams.set('addressdetails', '0');
		target.searchParams.set('limit', '6');
		const upstream = await fetch(target, {
			headers: {
				Accept: 'application/json',
				'User-Agent': `Portal-SI-Web/1.0 (${new URL(request.url).origin})`
			},
			signal: AbortSignal.timeout(7_000)
		});
		if (!upstream.ok) throw new Error('Upstream failed');
		const parsed = resultSchema.parse(await upstream.json());
		const value = {
			locations: parsed.map((place) => ({
				id: place.place_id,
				label: place.display_name,
				latitude: Number(place.lat),
				longitude: Number(place.lon),
				type: place.type ?? null
			}))
		};
		cache.set(key, { expires: Date.now() + 10 * 60_000, value });
		return privateResponse(value);
	} catch {
		return Response.json({ message: 'Pencarian lokasi sedang tidak tersedia.' }, { status: 503 });
	}
};

function privateResponse(value: unknown) {
	return Response.json(value, { headers: { 'Cache-Control': 'private, max-age=300' } });
}
