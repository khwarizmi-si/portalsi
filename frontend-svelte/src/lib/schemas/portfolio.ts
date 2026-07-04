import { z } from 'zod';

export const portfolioSchema = z.object({
	id: z.coerce.number().int().positive(),
	user_id: z.coerce.number().int().positive(),
	user_name: z.string().nullish(),
	signed_by: z
		.object({
			user_id: z.coerce.number().int().positive(),
			username: z.string().min(1),
			full_name: z.string().nullish(),
			role: z.enum(['student', 'parent', 'teacher', 'dev', 'other']).catch('other'),
			is_verified: z.boolean().catch(false)
		})
		.nullish(),
	aspect: z.enum(['quran', 'it', 'bahasa', 'karakter']),
	title: z.string(),
	description: z.string().nullish(),
	media_url: z.string().nullish(),
	year: z.coerce.number().int().nullish(),
	created_at: z.string()
});
export const portfoliosResponseSchema = z.object({ portfolios: z.array(portfolioSchema) });
export const createdPortfolioResponseSchema = z.object({
	message: z.string(),
	portfolio: portfolioSchema.passthrough()
});
