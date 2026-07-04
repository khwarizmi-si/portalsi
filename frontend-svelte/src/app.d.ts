import type { SessionUser } from '$lib/schemas/user';

declare global {
	namespace App {
		interface Error {
			message: string;
			requestId?: string;
		}
		interface Locals {
			token: string | null;
			user: SessionUser | null;
			sessionUnavailable: boolean;
			requestId: string;
		}
		interface PageData {
			user?: SessionUser | null;
		}
		// interface PageState {}
		// interface Platform {}
	}
}

export {};
