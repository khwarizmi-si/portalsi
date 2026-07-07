import { z } from 'zod';

const booleanish = z.union([z.boolean(), z.literal(0), z.literal(1)]).transform(Boolean);

export const compactUserSchema = z
	.object({
		user_id: z.coerce.number().int().positive(),
		username: z.string().min(1),
		full_name: z.string().nullish(),
		profile_picture_url: z.string().nullish(),
		role: z.enum(['student', 'parent', 'teacher', 'dev', 'other']).catch('other'),
		is_verified: booleanish.catch(false),
		is_private: booleanish.catch(false),
		has_story: booleanish.optional().catch(false),
		story_viewed: booleanish.optional().catch(false),
		is_following: booleanish.optional().catch(false),
		is_requested: booleanish.optional().catch(false),
		is_self: booleanish.optional().catch(false)
	})
	.passthrough();

export const postSchema = z
	.object({
		type: z.literal('post').default('post'),
		post_id: z.coerce.number().int().positive(),
		caption: z.string().nullish(),
		media_url: z.string().min(1),
		thumbnail_url: z.string().nullish(),
		location: z.string().nullish(),
		is_video: booleanish.catch(false),
		created_at: z.string(),
		likes_count: z.coerce.number().int().nonnegative().catch(0),
		comments_count: z.coerce.number().int().nonnegative().catch(0),
		is_liked: booleanish.catch(false),
		is_bookmarked: booleanish.catch(false),
		music_track_name: z.string().nullish(),
		music_artist_name: z.string().nullish(),
		music_preview_url: z.string().nullish(),
		music_start_position_ms: z.coerce.number().int().nonnegative().nullish(),
		music_clip_duration_ms: z.coerce.number().int().positive().nullish(),
		user: compactUserSchema
	})
	.passthrough();

export const feedSuggestionSchema = z.object({
	type: z.literal('suggestion'),
	users: z.array(compactUserSchema)
});

export const feedResponseSchema = z
	.object({
		current_page: z.coerce.number().int().positive(),
		per_page: z.coerce.number().int().positive(),
		total: z.coerce.number().int().nonnegative(),
		next_page_url: z.string().nullable(),
		prev_page_url: z.string().nullable().optional(),
		last_page_url: z.string().optional(),
		feed: z.array(z.union([postSchema, feedSuggestionSchema]))
	})
	.passthrough();

export const suggestionsResponseSchema = z
	.object({
		count: z.coerce.number().int().nonnegative(),
		users: z.array(compactUserSchema)
	})
	.passthrough();

export const exploreResponseSchema = z
	.object({
		current_page: z.coerce.number().int().positive(),
		data: z.array(postSchema),
		last_page: z.coerce.number().int().positive(),
		per_page: z.coerce.number().int().positive(),
		total: z.coerce.number().int().nonnegative(),
		next_page_url: z.string().nullable()
	})
	.passthrough();

export const userSearchResponseSchema = z
	.object({
		current_page: z.coerce.number().int().positive(),
		data: z.array(compactUserSchema),
		last_page: z.coerce.number().int().positive(),
		per_page: z.coerce.number().int().positive(),
		total: z.coerce.number().int().nonnegative()
	})
	.passthrough();

export const createdPostResponseSchema = z.object({
	message: z.string(),
	post: postSchema
});

export const bookmarksResponseSchema = z.array(postSchema);

export const onlineFollowersResponseSchema = z.object({
	count: z.coerce.number().int().nonnegative(),
	followers: z.array(compactUserSchema)
});

export const postLikesSchema = z.array(
	z.object({
		id: z.coerce.number().int().positive(),
		post_id: z.coerce.number().int().positive(),
		user: compactUserSchema,
		created_at: z.string(),
		is_following_status: booleanish.catch(false)
	})
);

export const clipSchema = postSchema.omit({ type: true }).extend({ type: z.literal('clip') });
export const clipsResponseSchema = z.object({
	clip: clipSchema,
	next_clips: z.array(clipSchema),
	next_page_url: z.string().nullable()
});

export type BackendPost = z.infer<typeof postSchema>;
export type CompactUser = z.infer<typeof compactUserSchema>;
export type FeedResponse = z.infer<typeof feedResponseSchema>;
