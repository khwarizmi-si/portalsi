import { z } from 'zod';

export const announcementSchema = z
	.object({
		id: z.coerce.number().int().positive(),
		title: z.string().nullish(),
		content: z.string().nullish(),
		image_url: z.string().nullish(),
		pinned: z.boolean().catch(false),
		created_at: z.string(),
		created_by: z.coerce.number().int().positive().nullish(),
		creator: z
			.object({
				user_id: z.coerce.number().int().positive(),
				full_name: z.string().nullish(),
				username: z.string().min(1),
				profile_picture_url: z.string().nullish()
			})
			.nullish()
	})
	.passthrough();

export const pinnedAnnouncementsSchema = z.array(announcementSchema);
