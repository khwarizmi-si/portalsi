import { z } from 'zod';

const booleanish = z.union([z.boolean(), z.literal(0), z.literal(1)]).transform(Boolean);

export const storySchema = z
	.object({
		story_id: z.coerce.number().int().positive(),
		type: z.enum(['image', 'video', 'music']),
		media_url: z.string().nullish(),
		caption: z.string().nullish(),
		created_at: z.string(),
		expires_at: z.string(),
		is_viewed: booleanish.catch(false)
	})
	.passthrough();

export const storyGroupSchema = z.object({
	user_id: z.coerce.number().int().positive(),
	username: z.string().min(1),
	profile_picture_url: z.string().nullish(),
	is_viewed: booleanish.catch(false),
	stories: z.array(storySchema).min(1)
});

export const storyFeedResponseSchema = z.object({
	stories: z.array(storyGroupSchema),
	suggestions: z.array(
		z
			.object({
				user_id: z.coerce.number().int().positive(),
				username: z.string().min(1),
				profile_picture_url: z.string().nullish()
			})
			.passthrough()
	)
});

export const storyViewerItemSchema = storySchema.extend({
	music_track_name: z.string().nullish(),
	music_artist_name: z.string().nullish(),
	music_preview_url: z.string().nullish(),
	music_album_art_url: z.string().nullish()
});

export const storyViewerResponseSchema = z.object({
	current_user: z.object({
		user_id: z.coerce.number().int().positive(),
		username: z.string().min(1),
		profile_picture_url: z.string().nullish()
	}),
	stories: z.array(storyViewerItemSchema).min(1),
	prev_user_id: z.coerce.number().int().positive().nullable(),
	next_user_id: z.coerce.number().int().positive().nullable()
});

export const createdStoryResponseSchema = z.object({
	message: z.string(),
	data: storySchema
});

export const storyViewersResponseSchema = z.object({
	story_id: z.coerce.number().int().positive(),
	total_viewers: z.coerce.number().int().nonnegative(),
	viewers: z.array(
		z.object({
			user_id: z.coerce.number().int().positive(),
			username: z.string().min(1),
			profile_picture_url: z.string().nullish(),
			is_verified: booleanish.catch(false),
			viewed_at: z.string()
		})
	)
});

export const archivedStoriesResponseSchema = z.object({
	current_page: z.coerce.number().int().positive(),
	per_page: z.coerce.number().int().positive(),
	total: z.coerce.number().int().nonnegative(),
	next_page_url: z.string().nullable(),
	prev_page_url: z.string().nullable(),
	last_page_url: z.string(),
	stories: z.array(storyViewerItemSchema)
});

export type StoryFeedResponse = z.infer<typeof storyFeedResponseSchema>;
