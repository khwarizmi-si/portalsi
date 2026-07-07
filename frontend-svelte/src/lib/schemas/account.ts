import { z } from 'zod';

export const loginHistorySchema = z.object({
	id: z.coerce.number().int().positive(),
	ip_address: z.string().nullish(),
	user_agent: z.string().nullish(),
	device: z.string().nullish(),
	browser: z.string().nullish(),
	platform: z.string().nullish(),
	location: z.string().nullish(),
	login_at: z.string(),
	is_current: z.boolean().optional().default(false)
});

export const loginHistoriesSchema = z.array(loginHistorySchema);
