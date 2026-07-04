import { env } from '$env/dynamic/public';
import { mapCompactUser, mapPost } from '$lib/api/mappers';
import {
	exploreResponseSchema,
	suggestionsResponseSchema,
	userSearchResponseSchema
} from '$lib/schemas/post';
import { storyFeedResponseSchema } from '$lib/schemas/story';
import { backendRequest } from '$lib/server/api';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

const validSorts = new Set(['random', 'newest', 'popular']);

export const load: PageServerLoad = async ({ locals, url }) => {
	if (!locals.token || !locals.user) error(401, 'Sesi Anda tidak tersedia.');
	const requestedSort = url.searchParams.get('sort') || 'random';
	const sort = validSorts.has(requestedSort) ? requestedSort : 'random';
	const page = Math.max(1, Number.parseInt(url.searchParams.get('page') || '1', 10) || 1);
	const query = (url.searchParams.get('q') || '').trim().slice(0, 80);
	const requestOptions = { token: locals.token, requestId: locals.requestId };

	const [postResult, suggestionResult, searchResult, storyResult] = await Promise.allSettled([
		backendRequest('explore', {
			...requestOptions,
			query: { sort, page, per_page: 15 },
			schema: exploreResponseSchema
		}),
		locals.user.emailVerified
			? backendRequest('suggestions', { ...requestOptions, schema: suggestionsResponseSchema })
			: Promise.resolve(null),
		query
			? backendRequest('users/search', {
					...requestOptions,
					query: { username: query, full_name: query, per_page: 12 },
					schema: userSearchResponseSchema
				})
			: Promise.resolve(null),
		backendRequest('stories/feed', { ...requestOptions, schema: storyFeedResponseSchema })
	]);

	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	const suggestedUsers =
		suggestionResult.status === 'fulfilled' && suggestionResult.value
			? suggestionResult.value.users
			: [];
	const searchedUsers =
		searchResult.status === 'fulfilled' && searchResult.value ? searchResult.value.data : [];
	const storyStatus = new Map(
		storyResult.status === 'fulfilled'
			? storyResult.value.stories.map((group) => [
					group.user_id,
					{ hasStory: true, storyViewed: group.is_viewed }
				])
			: []
	);
	const people = [...searchedUsers, ...suggestedUsers].map((user) => ({
		...mapCompactUser(user, mediaBaseUrl),
		...(storyStatus.get(user.user_id) ?? {})
	}));
	const postPage = postResult.status === 'fulfilled' ? postResult.value : null;

	return {
		posts: postPage?.data.map((post) => mapPost(post, mediaBaseUrl)) ?? [],
		people: [...new Map(people.map((user) => [user.id, user])).values()].slice(0, 12),
		sort,
		page: postPage?.current_page ?? page,
		hasNext: postPage ? postPage.current_page < postPage.last_page : false,
		query,
		exploreUnavailable: postResult.status === 'rejected',
		peopleUnavailable:
			suggestionResult.status === 'rejected' ||
			(Boolean(query) && searchResult.status === 'rejected')
	};
};
