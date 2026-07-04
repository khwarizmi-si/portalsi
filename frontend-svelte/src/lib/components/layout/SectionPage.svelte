<script lang="ts">
	import type { Snippet } from 'svelte';
	let {
		eyebrow,
		title,
		description,
		children,
		actions
	}: {
		eyebrow?: string;
		title: string;
		description?: string;
		children: Snippet;
		actions?: Snippet;
	} = $props();
</script>

<div class="section-page">
	<header>
		<div>
			{#if eyebrow}<p class="eyebrow">{eyebrow}</p>{/if}
			<h1 class="page-title">{title}</h1>
			{#if description}<p class="description">{description}</p>{/if}
		</div>
		{#if actions}<div class="actions">{@render actions()}</div>{/if}
	</header>
	{@render children()}
</div>

<style>
	.section-page {
		width: min(100% - 32px, 1080px);
		margin: 0 auto;
		padding: 18px 0 40px;
	}

	header {
		display: flex;
		align-items: end;
		justify-content: space-between;
		gap: 24px;
		padding: 12px 0 22px;
	}

	.description {
		max-width: 42rem;
		margin: 8px 0 0;
		color: var(--color-muted);
		font-size: 0.92rem;
	}

	.actions {
		flex: none;
	}

	@media (max-width: 767px) {
		.section-page {
			width: 100%;
			padding-top: 0;
		}

		header {
			align-items: start;
			padding: 22px 16px 18px;
		}
	}
</style>
