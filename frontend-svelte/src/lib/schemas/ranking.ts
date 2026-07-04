import { z } from 'zod';

export const rankingStudentSchema = z.object({
	studentId: z.coerce.string().min(1),
	name: z.string().min(1),
	photo: z.string().catch(''),
	averageScore: z.coerce.number().finite()
});
export const rankingStudentsSchema = z.array(rankingStudentSchema);
export const rankingBffResponseSchema = z.object({
	students: rankingStudentsSchema,
	stale: z.boolean(),
	fetchedAt: z.string()
});
