import { env } from '$env/dynamic/public';
import { mapCompactUser, mapPost, mapSessionToPortalUser } from '$lib/api/mappers';
import { commentsResponseSchema } from '$lib/schemas/comment';
import { ApiError } from '$lib/api/errors';
import { postLikesSchema, postSchema } from '$lib/schemas/post';
import { backendRequest } from '$lib/server/api';
import { normalizeMediaUrl } from '$lib/utils/media';
import { relativeTimeId } from '$lib/utils/time';
import { error, fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, params }) => {
	if (!locals.token || !locals.user) error(401, 'Sesi Anda tidak tersedia.');
	const postId = Number.parseInt(params.postId, 10);
	if (!Number.isSafeInteger(postId) || postId < 1) error(404, 'Postingan tidak ditemukan.');

	const [post, comments, likes] = await Promise.all([
		backendRequest(`posts/${postId}`, {
			token: locals.token,
			requestId: locals.requestId,
			schema: postSchema
		}),
		backendRequest(`posts/${postId}/comments`, {
			token: locals.token,
			requestId: locals.requestId,
			schema: commentsResponseSchema
		}),
		backendRequest(`posts/${postId}/likes`, {
			token: locals.token,
			requestId: locals.requestId,
			schema: postLikesSchema
		})
	]);
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	const mapComment = (comment: (typeof comments.comments)[number]['replies'][number]) => ({
		id: comment.comment_id,
		user: mapCompactUser(comment.user, mediaBaseUrl),
		text: comment.content,
		gifUrl: comment.gif_url ?? null,
		createdLabel: relativeTimeId(comment.created_at),
		likesCount: comment.likes_count,
		isLiked: comment.is_liked,
		parentId: comment.parent_comment_id
	});

	return {
		post: mapPost(post, mediaBaseUrl),
		likers: likes.map((like) => ({
			...mapCompactUser(like.user, mediaBaseUrl),
			isFollowing: like.is_following_status
		})),
		comments: comments.comments.map((comment) => ({
			...mapComment(comment),
			replies: comment.replies.map(mapComment)
		})),
		currentUser: {
			...mapSessionToPortalUser(locals.user),
			avatarUrl: normalizeMediaUrl(locals.user.avatarUrl, mediaBaseUrl) ?? undefined
		}
	};
};

export const actions: Actions = {
	update: async ({ request, locals, params }) => {
		if (!locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
		const postId = Number.parseInt(params.postId, 10);
		if (!Number.isSafeInteger(postId) || postId < 1)
			return fail(400, { message: 'Postingan tidak valid.' });
		const source = await request.formData();
		const caption = String(source.get('caption') ?? '').trim();
		const body = new FormData();
		body.set('caption', caption);
		try {
			await backendRequest(`posts/${postId}/update`, {
				method: 'POST',
				token: locals.token,
				requestId: locals.requestId,
				body
			});
			return { success: true, message: 'Postingan berhasil diperbarui.' };
		} catch (cause) {
			if (cause instanceof ApiError)
				return fail(cause.status, { message: cause.message, errors: cause.fieldErrors });
			throw cause;
		}
	},
	delete: async ({ locals, params }) => {
		if (!locals.token) return fail(401, { message: 'Sesi tidak tersedia.' });
		const postId = Number.parseInt(params.postId, 10);
		if (!Number.isSafeInteger(postId) || postId < 1)
			return fail(400, { message: 'Postingan tidak valid.' });
		try {
			await backendRequest(`posts/${postId}`, {
				method: 'DELETE',
				token: locals.token,
				requestId: locals.requestId
			});
		} catch (cause) {
			if (cause instanceof ApiError)
				return fail(cause.status, { message: cause.message, errors: cause.fieldErrors });
			throw cause;
		}
		redirect(303, '/profile');
	}
};
