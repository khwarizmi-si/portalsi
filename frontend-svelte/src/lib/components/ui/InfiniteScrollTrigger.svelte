<script lang="ts">
	import { onMount } from 'svelte';
	let {
		hasMore,
		loading,
		onLoad,
		label = 'Memuat konten berikutnya…'
	}: {
		hasMore: boolean;
		loading: boolean;
		onLoad: () => void | Promise<void>;
		label?: string;
	} = $props();
	let trigger: HTMLDivElement;

	onMount(() => {
		const observer = new IntersectionObserver(
			(entries) => {
				if (entries[0]?.isIntersecting && hasMore && !loading) void onLoad();
			},
			{ rootMargin: '500px 0px' }
		);
		observer.observe(trigger);
		return () => observer.disconnect();
	});
</script>

<div class="infinite-trigger" bind:this={trigger} aria-live="polite">
	{#if loading}<span></span>{label}{:else if hasMore}<i>Scroll untuk memuat lebih banyak</i>{/if}
</div>

<style>
	.infinite-trigger {
		display: flex;
		min-height: 38px;
		align-items: center;
		justify-content: center;
		gap: 8px;
		color: var(--color-muted);
		font-size: 0.72rem;
	}
	.infinite-trigger span {
		width: 16px;
		height: 16px;
		border: 2px solid var(--color-border);
		border-top-color: var(--color-primary);
		border-radius: 50%;
		animation: spin 0.7s linear infinite;
	}
	.infinite-trigger i {
		font-style: normal;
		opacity: 0;
	}
	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}
</style>
