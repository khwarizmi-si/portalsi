import { z } from 'zod';
import { backendUserSchema } from './user';

export const loginInputSchema = z.object({
	login: z.string().trim().min(1, 'Username atau email wajib diisi.'),
	password: z.string().min(1, 'Kata sandi wajib diisi.'),
	remember: z.boolean().default(false)
});

export const loginResponseSchema = z
	.object({
		code: z.number().optional(),
		message: z.string(),
		token: z.string().min(1),
		user: backendUserSchema
	})
	.passthrough();

export const registerInputSchema = z.object({
	full_name: z.string().trim().min(1, 'Nama lengkap wajib diisi.'),
	username: z
		.string()
		.trim()
		.min(1, 'Username wajib diisi.')
		.regex(/^[a-zA-Z0-9._]+$/, 'Username hanya boleh memakai huruf, angka, titik, dan underscore.'),
	email: z.string().trim().email('Format email tidak valid.'),
	role: z.enum(['student', 'parent', 'teacher', 'other']),
	password: z.string().min(6, 'Kata sandi minimal 6 karakter.'),
	terms: z.literal(true, { error: 'Anda perlu menyetujui aturan komunitas.' })
});

export const registerResponseSchema = z
	.object({
		message: z.string(),
		verification_email_status: z.string().optional(),
		token: z.string().min(1),
		user: backendUserSchema
	})
	.passthrough();

export const forgotPasswordInputSchema = z.object({
	email: z.string().trim().email('Format email tidak valid.')
});

export const forgotPasswordResponseSchema = z
	.object({
		message: z.string(),
		status: z.string()
	})
	.passthrough();
