import { writable } from 'svelte/store';

type ProgressState = {
	active: boolean;
	value: number;
	status: 'loading' | 'success' | 'error';
};

export const progressState = writable<ProgressState>({
	active: false,
	value: 0,
	status: 'loading'
});

let activeRequests = 0;
let timer: ReturnType<typeof setInterval> | null = null;
let hideTimer: ReturnType<typeof setTimeout> | null = null;

export function startProgress() {
	activeRequests += 1;
	if (hideTimer) clearTimeout(hideTimer);
	progressState.set({ active: true, value: 8, status: 'loading' });
	if (!timer) {
		timer = setInterval(() => {
			progressState.update((state) => ({
				...state,
				value: Math.min(88, state.value + Math.max(1, (90 - state.value) * 0.08))
			}));
		}, 180);
	}
}

export function finishProgress(success = true) {
	if (activeRequests === 0) return;
	activeRequests = Math.max(0, activeRequests - 1);
	if (activeRequests > 0) return;
	if (timer) clearInterval(timer);
	timer = null;
	progressState.set({ active: true, value: 100, status: success ? 'success' : 'error' });
	hideTimer = setTimeout(
		() => {
			progressState.set({ active: false, value: 0, status: 'loading' });
		},
		success ? 420 : 900
	);
}
