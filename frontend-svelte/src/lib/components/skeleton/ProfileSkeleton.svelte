<script lang="ts">
	import Skeleton from '$lib/components/ui/Skeleton.svelte';
</script>

<div class="profile-skeleton" aria-hidden="true">
	<section class="hero surface">
		<Skeleton h="132px" radius="0" class="banner" />
		<div class="main">
			<div class="avatar"><Skeleton w="96px" h="96px" circle /></div>
			<Skeleton w="150px" h="18px" mb="9px" />
			<Skeleton w="110px" h="11px" mb="14px" />
			<Skeleton w="80%" h="10px" mb="6px" />
			<Skeleton w="55%" h="10px" mb="16px" />
			<div class="stats">
				{#each Array(3) as _, i (i)}
					<div class="stat">
						<Skeleton w="38px" h="15px" mb="6px" />
						<Skeleton w="52px" h="9px" />
					</div>
				{/each}
			</div>
		</div>
	</section>

	<div class="tabs">
		{#each Array(3) as _, i (i)}
			<Skeleton w="88px" h="14px" />
		{/each}
	</div>

	<div class="grid">
		{#each Array(9) as _, i (i)}
			<Skeleton h="auto" radius="4px" class="tile" />
		{/each}
	</div>
</div>

<style>
	.profile-skeleton {
		display: grid;
		gap: 16px;
		padding-top: 8px;
	}
	.hero {
		overflow: hidden;
		border-radius: var(--radius-lg, 18px);
	}
	.main {
		padding: 0 20px 20px;
	}
	.avatar {
		margin-top: -46px;
		margin-bottom: 12px;
	}
	.avatar :global(.sk) {
		border: 4px solid var(--color-surface);
	}
	.stats {
		display: flex;
		gap: 26px;
	}
	.stat {
		display: grid;
	}
	.tabs {
		display: flex;
		justify-content: center;
		gap: 26px;
		padding: 4px 0;
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 4px;
		overflow: hidden;
		border-radius: var(--radius-lg, 18px);
	}
	.grid :global(.tile) {
		width: 100%;
		aspect-ratio: 1 / 1;
	}
</style>
