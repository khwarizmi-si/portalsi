import { z } from 'zod';
import { profilePaginationSchema } from './profile';

const booleanish = z.union([z.boolean(), z.literal(0), z.literal(1)]).transform(Boolean);

export const notificationPreferencesSchema = z
	.object({
		new_post_reminders: z.enum(['all', 'mutual', 'off']).catch('all'),
		likes: booleanish.catch(true),
		comments: booleanish.catch(true),
		mentions: booleanish.catch(true),
		follows: booleanish.catch(true)
	})
	.passthrough();

export const notificationPreferencesResponseSchema = z
	.object({ preferences: notificationPreferencesSchema })
	.passthrough();

export type NotificationPreferences = z.infer<typeof notificationPreferencesSchema>;

export const notificationsResponseSchema = z.object({
	notifications: z.array(
		z.object({
			notification_id: z.coerce.number().int().positive(),
			type: z.string().min(1),
			message: z.string(),
			sender: z
				.object({
					user_id: z.coerce.number().int().positive(),
					username: z.string().min(1),
					full_name: z.string().nullish(),
					profile_picture_url: z.string().nullish(),
					role: z.enum(['student', 'parent', 'teacher', 'dev', 'other']).catch('other'),
					is_verified: booleanish.catch(false)
				})
				.nullable(),
			related_post_id: z.coerce.number().int().positive().nullish(),
			related_story_id: z.coerce.number().int().positive().nullish(),
			is_read: booleanish.catch(false),
			created_at: z.string()
		})
	),
	pagination: profilePaginationSchema
});
