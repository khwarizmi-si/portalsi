import { writable } from 'svelte/store';

export type ConfirmOptions = {
	title: string;
	description: string;
	confirmLabel?: string;
	cancelLabel?: string;
	tone?: 'default' | 'danger';
};

type ConfirmState = ConfirmOptions & { open: true; resolve: (answer: boolean) => void };

export const confirmState = writable<ConfirmState | null>(null);

export function confirmAction(options: ConfirmOptions): Promise<boolean> {
	return new Promise((resolve) => {
		confirmState.set({ ...options, open: true, resolve });
	});
}

export function resolveConfirmation(answer: boolean) {
	confirmState.update((state) => {
		state?.resolve(answer);
		return null;
	});
}

export async function confirmButtonAction(event: MouseEvent, options: ConfirmOptions) {
	event.preventDefault();
	const button = event.currentTarget as HTMLButtonElement;
	if (!(await confirmAction(options)) || !button.form) return;
	if (button.formAction) button.form.action = button.formAction;
	button.form.submit();
}

export async function confirmFormSubmit(event: SubmitEvent, options: ConfirmOptions) {
	event.preventDefault();
	const form = event.currentTarget as HTMLFormElement;
	if (await confirmAction(options)) form.submit();
}
