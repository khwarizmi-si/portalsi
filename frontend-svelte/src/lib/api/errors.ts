import { z } from 'zod';

const backendErrorSchema = z
	.object({
		message: z.string().optional(),
		error: z.string().optional(),
		code: z.union([z.string(), z.number()]).optional(),
		errors: z.record(z.string(), z.union([z.array(z.string()), z.string()])).optional(),
		verification_email_status: z.string().optional(),
		resend_cooldown_seconds: z.coerce.number().optional()
	})
	.passthrough();

export type FieldErrors = Record<string, string[]>;

export class ApiError extends Error {
	readonly status: number;
	readonly code?: string | number;
	readonly fieldErrors: FieldErrors;
	readonly requestId?: string;
	readonly verificationStatus?: string;
	readonly retryAfterSeconds?: number;

	constructor(options: {
		status: number;
		message: string;
		code?: string | number;
		fieldErrors?: FieldErrors;
		requestId?: string;
		verificationStatus?: string;
		retryAfterSeconds?: number;
	}) {
		super(options.message);
		this.name = 'ApiError';
		this.status = options.status;
		this.code = options.code;
		this.fieldErrors = options.fieldErrors ?? {};
		this.requestId = options.requestId;
		this.verificationStatus = options.verificationStatus;
		this.retryAfterSeconds = options.retryAfterSeconds;
	}
}

export class ApiContractError extends ApiError {
	constructor(message: string, requestId?: string) {
		super({ status: 502, message, requestId });
		this.name = 'ApiContractError';
	}
}

export function parseBackendError(
	status: number,
	body: unknown,
	requestId?: string,
	retryAfterHeader?: string | null
): ApiError {
	const parsed = backendErrorSchema.safeParse(body);
	const data = parsed.success ? parsed.data : {};
	const fieldErrors: FieldErrors = {};

	for (const [field, messages] of Object.entries(data.errors ?? {})) {
		fieldErrors[field] = Array.isArray(messages) ? messages : [messages];
	}

	const headerSeconds = retryAfterHeader ? Number.parseInt(retryAfterHeader, 10) : undefined;
	return new ApiError({
		status,
		message: data.message ?? data.error ?? defaultMessage(status),
		code: data.code,
		fieldErrors,
		requestId,
		verificationStatus: data.verification_email_status,
		retryAfterSeconds:
			data.resend_cooldown_seconds ?? (Number.isFinite(headerSeconds) ? headerSeconds : undefined)
	});
}

function defaultMessage(status: number): string {
	if (status === 401) return 'Sesi tidak valid. Silakan masuk kembali.';
	if (status === 403) return 'Anda tidak memiliki izin untuk melakukan tindakan ini.';
	if (status === 404) return 'Data yang diminta tidak ditemukan.';
	if (status === 422) return 'Periksa kembali data yang Anda masukkan.';
	if (status === 429) return 'Terlalu banyak permintaan. Coba lagi sebentar.';
	return status >= 500
		? 'Layanan Portal SI sedang bermasalah.'
		: 'Permintaan tidak dapat diproses.';
}
