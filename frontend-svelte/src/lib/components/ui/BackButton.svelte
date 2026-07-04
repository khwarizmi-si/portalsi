<script lang="ts">
	import { goto } from '$app/navigation';
	import { ArrowLeft } from '@lucide/svelte';
	let { fallback = '/home', label = 'Kembali' }: { fallback?: string; label?: string } = $props();
	function back() {
		if (history.length > 1) history.back();
		else void goto(fallback);
	}
</script>

<button type="button" onclick={back} aria-label={label}
	><ArrowLeft size={18} /><span>{label}</span></button
>

<style>
	button {
		display: inline-flex;
		min-height: 40px;
		align-items: center;
		gap: 7px;
		padding: 0 12px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 11px;
		color: var(--color-muted);
		font-size: 0.75rem;
		font-weight: 700;
		box-shadow: var(--shadow-xs);
	}
	@media (max-width: 520px) {
		button span {
			display: none;
		}
		button {
			width: 40px;
			padding: 0;
			justify-content: center;
			border-radius: 50%;
		}
	}
</style>
