import { z } from 'zod';
import { userRoleSchema } from './user';
import { compactUserSchema } from './post';

const booleanish = z.union([z.boolean(), z.literal(0), z.literal(1)]).transform(Boolean);

export const profilePostSchema = z
	.object({
		post_id: z.coerce.number().int().positive(),
		caption: z.string().nullish(),
		media_url: z.string().min(1),
		thumbnail_url: z.string().nullish(),
		is_video: booleanish.catch(false),
		created_at: z.string()
	})
	.passthrough();

export const profilePaginationSchema = z.object({
	current_page: z.coerce.number().int().positive(),
	last_page: z.coerce.number().int().positive(),
	per_page: z.coerce.number().int().positive(),
	total: z.coerce.number().int().nonnegative(),
	next_page_url: z.string().nullable()
});

export const profileResponseSchema = z
	.object({
		user_id: z.coerce.number().int().positive(),
		username: z.string().min(1),
		full_name: z.string().nullish(),
		bio: z.string().nullish(),
		email: z.string().email().nullish(),
		email_verified: z.boolean().optional(),
		profile_picture_url: z.string().nullish(),
		banner_url: z.string().nullish(),
		is_verified: booleanish.catch(false),
		role: userRoleSchema.catch('other'),
		is_private: booleanish.catch(false),
		followers_count: z.coerce.number().int().nonnegative().catch(0),
		following_count: z.coerce.number().int().nonnegative().catch(0),
		posts_count: z.coerce.number().int().nonnegative().catch(0),
		recent_posts: z.array(profilePostSchema),
		pagination: profilePaginationSchema.nullable(),
		message: z.string().nullish().optional()
	})
	.passthrough();

export const followingResponseSchema = z.object({
	following_count: z.coerce.number().int().nonnegative(),
	following: z.array(compactUserSchema),
	pagination: profilePaginationSchema
});

export const followersResponseSchema = z.object({
	followers_count: z.coerce.number().int().nonnegative(),
	followers: z.array(compactUserSchema),
	pagination: profilePaginationSchema
});

export const pendingFollowersResponseSchema = z.object({
	pending_requests_count: z.coerce.number().int().nonnegative(),
	pending_requests: z.array(
		z.object({
			user_id: z.coerce.number().int().positive(),
			username: z.string().min(1),
			full_name: z.string().nullish(),
			profile_picture_url: z.string().nullish(),
			role: z.enum(['student', 'parent', 'teacher', 'dev', 'other']).catch('other'),
			is_verified: booleanish.catch(false)
		})
	)
});

export type ProfileResponse = z.infer<typeof profileResponseSchema>;
