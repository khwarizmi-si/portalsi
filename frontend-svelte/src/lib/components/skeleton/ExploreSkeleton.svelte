<script lang="ts">
	import Skeleton from '$lib/components/ui/Skeleton.svelte';
</script>

<div class="explore-skeleton" aria-hidden="true">
	<Skeleton h="46px" radius="13px" mb="14px" />
	<div class="grid">
		{#each Array(12) as _, i (i)}
			<Skeleton h="auto" radius="4px" class="tile" />
		{/each}
	</div>
</div>

<style>
	.explore-skeleton {
		padding-top: 8px;
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(3, minmax(0, 1fr));
		gap: 4px;
		overflow: hidden;
		border-radius: var(--radius-lg, 18px);
	}
	.grid :global(.tile) {
		width: 100%;
		aspect-ratio: 1 / 1;
	}
	@media (min-width: 900px) {
		.grid {
			grid-template-columns: repeat(4, minmax(0, 1fr));
		}
	}
</style>
