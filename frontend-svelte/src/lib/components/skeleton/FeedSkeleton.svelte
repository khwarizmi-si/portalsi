<script lang="ts">
	import Skeleton from '$lib/components/ui/Skeleton.svelte';
</script>

<div class="feed-skeleton" aria-hidden="true">
	<div class="stories">
		{#each Array(7) as _, i (i)}
			<div class="story">
				<Skeleton w="58px" h="58px" circle />
				<Skeleton w="42px" h="8px" />
			</div>
		{/each}
	</div>

	{#each Array(3) as _, i (i)}
		<article class="card">
			<header>
				<Skeleton w="42px" h="42px" circle />
				<div class="lines">
					<Skeleton w="45%" h="11px" mb="7px" />
					<Skeleton w="28%" h="9px" />
				</div>
			</header>
			<Skeleton w="90%" h="10px" mb="7px" />
			<Skeleton w="70%" h="10px" mb="12px" />
			<Skeleton h="320px" radius="16px" />
			<div class="actions">
				<Skeleton w="64px" h="14px" />
				<Skeleton w="64px" h="14px" />
				<Skeleton w="64px" h="14px" />
			</div>
		</article>
	{/each}
</div>

<style>
	.feed-skeleton {
		display: grid;
		gap: 16px;
		padding-top: 8px;
	}
	.stories {
		display: flex;
		gap: 14px;
		padding: 4px 2px;
		overflow: hidden;
	}
	.story {
		display: grid;
		justify-items: center;
		gap: 8px;
	}
	.card {
		display: block;
		padding: 16px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-lg, 18px);
	}
	.card header {
		display: flex;
		align-items: center;
		gap: 11px;
		margin-bottom: 13px;
	}
	.lines {
		flex: 1;
	}
	.actions {
		display: flex;
		gap: 18px;
		margin-top: 14px;
	}
</style>
