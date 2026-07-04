<script lang="ts">
	import type { Snippet } from 'svelte';
	let {
		eyebrow,
		title,
		description,
		action
	}: { eyebrow?: string; title: string; description?: string; action?: Snippet } = $props();
</script>

<header class="page-header">
	<div>
		{#if eyebrow}<p class="eyebrow">{eyebrow}</p>{/if}
		<h1 class="page-title">{title}</h1>
		{#if description}<p>{description}</p>{/if}
	</div>
	{#if action}<div class="action">{@render action()}</div>{/if}
</header>

<style>
	.page-header {
		display: flex;
		align-items: end;
		justify-content: space-between;
		gap: 24px;
		padding: 28px 0 20px;
	}

	.page-header p:last-child {
		max-width: 46rem;
		margin: 8px 0 0;
		color: var(--color-muted);
	}
</style>
