<script lang="ts">
	import { clientRequest } from '$lib/api/client';
	import { userSearchResponseSchema } from '$lib/schemas/post';

	let {
		value = $bindable(''),
		name,
		placeholder = '',
		maxlength = 2000,
		rows = 4,
		onEnter
	}: {
		value?: string;
		name: string;
		placeholder?: string;
		maxlength?: number;
		rows?: number;
		onEnter?: () => void;
	} = $props();
	let textarea: HTMLTextAreaElement;
	let results = $state<Array<{ user_id: number; username: string; full_name?: string | null }>>([]);
	let loading = $state(false);
	let request = 0;

	async function updateSuggestions() {
		const cursor = textarea.selectionStart;
		const match = value.slice(0, cursor).match(/(?:^|\s)@([A-Za-z0-9._]{1,40})$/);
		if (!match) {
			results = [];
			return;
		}
		const current = ++request;
		loading = true;
		try {
			const query = encodeURIComponent(match[1]);
			const response = await clientRequest(
				`users/search?username=${query}&full_name=${query}&per_page=6`,
				{ schema: userSearchResponseSchema }
			);
			if (current === request) results = response.data;
		} catch {
			if (current === request) results = [];
		} finally {
			if (current === request) loading = false;
		}
	}

	function handleKeydown(event: KeyboardEvent) {
		// Desktop: Enter mengirim, Shift+Enter membuat baris baru. Di layar sentuh Enter tetap baris baru.
		// Jika menu mention terbuka, Enter dibiarkan untuk mengetik (bukan mengirim).
		if (event.key !== 'Enter' || event.shiftKey || !onEnter) return;
		if (results.length > 0) return;
		if (typeof window !== 'undefined' && window.matchMedia('(pointer: coarse)').matches) return;
		event.preventDefault();
		onEnter();
	}

	function select(username: string) {
		const cursor = textarea.selectionStart;
		const before = value.slice(0, cursor).replace(/@([A-Za-z0-9._]{1,40})$/, `@${username} `);
		value = before + value.slice(cursor);
		results = [];
		requestAnimationFrame(() => {
			textarea.focus();
			textarea.setSelectionRange(before.length, before.length);
		});
	}
</script>

<div class="mention-field">
	<textarea
		bind:this={textarea}
		bind:value
		{name}
		{placeholder}
		{maxlength}
		{rows}
		oninput={updateSuggestions}
		onkeydown={handleKeydown}></textarea>
	{#if results.length || loading}<div class="mention-menu" role="listbox">
			{#if loading && !results.length}<span>Mencari pengguna…</span>{/if}
			{#each results as user (user.user_id)}<button
					type="button"
					onclick={() => select(user.username)}
					><strong>{user.full_name || user.username}</strong><small>@{user.username}</small></button
				>{/each}
		</div>{/if}
</div>

<style>
	.mention-field {
		position: relative;
	}
	textarea {
		width: 100%;
	}
	.mention-menu {
		position: absolute;
		z-index: 40;
		right: 0;
		left: 0;
		display: grid;
		max-height: 220px;
		overflow: auto;
		margin-top: 4px;
		padding: 5px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 12px;
		box-shadow: var(--shadow-md);
	}
	.mention-menu button {
		display: grid;
		padding: 8px 10px;
		background: transparent;
		border: 0;
		border-radius: 8px;
		text-align: left;
	}
	.mention-menu button:hover {
		background: var(--color-primary-soft);
	}
	.mention-menu strong {
		font-size: 0.75rem;
	}
	.mention-menu small,
	.mention-menu > span {
		color: var(--color-muted);
		font-size: 0.66rem;
	}
	.mention-menu > span {
		padding: 10px;
	}
</style>
