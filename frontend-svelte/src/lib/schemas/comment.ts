import { z } from 'zod';
import { compactUserSchema } from './post';

const booleanish = z.union([z.boolean(), z.literal(0), z.literal(1)]).transform(Boolean);

export const commentReplySchema = z
	.object({
		comment_id: z.coerce.number().int().positive(),
		post_id: z.coerce.number().int().positive(),
		user_id: z.coerce.number().int().positive(),
		content: z.string(),
		parent_comment_id: z.coerce.number().int().positive().nullable(),
		created_at: z.string(),
		likes_count: z.coerce.number().int().nonnegative().catch(0),
		is_liked: booleanish.catch(false),
		user: compactUserSchema
	})
	.passthrough();

export const commentSchema = commentReplySchema.extend({
	parent_comment_id: z.null(),
	replies: z.array(commentReplySchema).catch([])
});

export const commentsResponseSchema = z.object({
	post_id: z.coerce.number().int().positive(),
	comments: z.array(commentSchema)
});

export const createdCommentResponseSchema = z.object({
	message: z.string(),
	data: z
		.object({
			comment_id: z.coerce.number().int().positive(),
			post_id: z.coerce.number().int().positive(),
			user_id: z.coerce.number().int().positive(),
			content: z.string(),
			parent_comment_id: z.coerce.number().int().positive().nullable(),
			created_at: z.string(),
			user: compactUserSchema
		})
		.passthrough()
});
