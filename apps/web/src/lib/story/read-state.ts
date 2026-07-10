import { writable } from 'svelte/store';

export const readStoryUsers = writable<Set<number>>(new Set());

export function markStoryUserRead(userId: number) {
	readStoryUsers.update((current) => {
		const next = new Set(current);
		next.add(userId);
		return next;
	});
}
