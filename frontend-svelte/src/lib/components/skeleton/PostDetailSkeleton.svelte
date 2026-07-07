<script lang="ts">
	import Skeleton from '$lib/components/ui/Skeleton.svelte';
</script>

<div class="post-skeleton surface" aria-hidden="true">
	<header>
		<Skeleton w="44px" h="44px" circle />
		<div class="lines">
			<Skeleton w="140px" h="12px" mb="7px" />
			<Skeleton w="90px" h="9px" />
		</div>
	</header>
	<Skeleton h="420px" radius="14px" mb="16px" />
	<div class="actions">
		<Skeleton w="70px" h="16px" />
		<Skeleton w="70px" h="16px" />
		<Skeleton w="70px" h="16px" />
	</div>
	<Skeleton w="95%" h="11px" mb="7px" />
	<Skeleton w="80%" h="11px" mb="20px" />

	{#each Array(4) as _, i (i)}
		<div class="comment">
			<Skeleton w="34px" h="34px" circle />
			<div class="lines">
				<Skeleton w="40%" h="10px" mb="6px" />
				<Skeleton w="72%" h="10px" />
			</div>
		</div>
	{/each}
</div>

<style>
	.post-skeleton {
		max-width: 640px;
		margin: 8px auto 0;
		padding: 18px;
		border: 1px solid var(--color-border);
		border-radius: var(--radius-lg, 18px);
	}
	header {
		display: flex;
		align-items: center;
		gap: 11px;
		margin-bottom: 14px;
	}
	.lines {
		flex: 1;
	}
	.actions {
		display: flex;
		gap: 20px;
		margin-bottom: 16px;
	}
	.comment {
		display: flex;
		align-items: center;
		gap: 10px;
		margin-bottom: 14px;
	}
</style>
