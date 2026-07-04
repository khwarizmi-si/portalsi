import { env } from '$env/dynamic/private';
import { rankingStudentsSchema } from '$lib/schemas/ranking';
import type { RequestHandler } from './$types';

const freshForMs = 5 * 60_000;
const staleForMs = 24 * 60 * 60_000;
let cache: { students: ReturnType<typeof rankingStudentsSchema.parse>; fetchedAt: number } | null =
	null;

export const GET: RequestHandler = async ({ locals, url }) => {
	if (!locals.token) return Response.json({ message: 'Sesi tidak tersedia.' }, { status: 401 });
	const now = Date.now();
	const force = url.searchParams.get('refresh') === '1';
	if (!force && cache && now - cache.fetchedAt < freshForMs)
		return response(cache.students, false, cache.fetchedAt);

	try {
		const target = new URL(
			env.RANKING_API_URL?.trim() || 'https://santriboard.vercel.app/api/student/leaderboard'
		);
		if (target.protocol !== 'https:') throw new Error('Ranking URL must use HTTPS.');
		const upstream = await fetch(target, {
			headers: { Accept: 'application/json' },
			signal: AbortSignal.timeout(8_000)
		});
		if (!upstream.ok) throw new Error(`Ranking upstream returned ${upstream.status}.`);
		const students = rankingStudentsSchema.parse(await upstream.json());
		cache = { students, fetchedAt: now };
		return response(students, false, now);
	} catch {
		if (cache && now - cache.fetchedAt < staleForMs)
			return response(cache.students, true, cache.fetchedAt);
		return Response.json(
			{ message: 'Ranking belum dapat dimuat dan cache belum tersedia.' },
			{ status: 503, headers: { 'Cache-Control': 'private, no-store' } }
		);
	}
};

function response(
	students: ReturnType<typeof rankingStudentsSchema.parse>,
	stale: boolean,
	fetchedAt: number
) {
	return Response.json(
		{ students, stale, fetchedAt: new Date(fetchedAt).toISOString() },
		{ headers: { 'Cache-Control': 'private, no-store' } }
	);
}
