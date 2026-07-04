import { z } from 'zod';

export const userRoleSchema = z.enum(['student', 'parent', 'teacher', 'dev', 'other']);

const booleanishSchema = z.union([z.boolean(), z.literal(0), z.literal(1)]).transform(Boolean);

export const backendUserSchema = z
	.object({
		user_id: z.coerce.number().int().positive(),
		username: z.string().min(1),
		full_name: z.string().nullish(),
		email: z.string().email().nullish(),
		bio: z.string().nullish(),
		profile_picture_url: z.string().nullish(),
		banner_url: z.string().nullish(),
		role: userRoleSchema.catch('other'),
		is_verified: booleanishSchema.catch(false),
		is_private: booleanishSchema.catch(false),
		email_verified: z.boolean().optional(),
		email_verified_at: z.string().nullish()
	})
	.passthrough();

export type BackendUser = z.infer<typeof backendUserSchema>;

export interface SessionUser {
	id: number;
	username: string;
	fullName: string;
	email: string | null;
	bio: string | null;
	avatarUrl: string | null;
	bannerUrl: string | null;
	role: z.infer<typeof userRoleSchema>;
	badgeVerified: boolean;
	emailVerified: boolean;
	isPrivate: boolean;
}

export function toSessionUser(user: BackendUser): SessionUser {
	return {
		id: user.user_id,
		username: user.username,
		fullName: user.full_name?.trim() || user.username,
		email: user.email ?? null,
		bio: user.bio ?? null,
		avatarUrl: user.profile_picture_url ?? null,
		bannerUrl: user.banner_url ?? null,
		role: user.role,
		badgeVerified: user.is_verified,
		emailVerified: user.email_verified ?? Boolean(user.email_verified_at),
		isPrivate: user.is_private
	};
}
