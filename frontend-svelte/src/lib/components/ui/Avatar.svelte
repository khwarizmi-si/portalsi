<script lang="ts">
	let {
		name,
		src,
		size = 'md',
		story = false,
		seen = false
	}: {
		name: string;
		src?: string;
		size?: 'sm' | 'md' | 'lg' | 'xl';
		story?: boolean;
		seen?: boolean;
	} = $props();

	const initials = $derived(
		name
			.split(' ')
			.map((word) => word[0])
			.join('')
			.slice(0, 2)
			.toUpperCase()
	);
</script>

<span class:story class:seen class="avatar-wrap {size}" aria-hidden="true">
	<span class="avatar">
		{#if src}
			<img {src} alt="" />
		{:else}
			<span>{initials}</span>
		{/if}
	</span>
</span>

<style>
	.avatar-wrap {
		display: inline-grid;
		flex: none;
		place-items: center;
		border-radius: 50%;
	}

	.avatar-wrap.sm {
		width: 34px;
		height: 34px;
	}

	.avatar-wrap.md {
		width: 44px;
		height: 44px;
	}

	.avatar-wrap.lg {
		width: 58px;
		height: 58px;
	}

	.avatar-wrap.xl {
		width: 78px;
		height: 78px;
	}

	.avatar-wrap.story {
		padding: 3px;
		background: conic-gradient(
			from 210deg,
			var(--color-secondary),
			#33b8a4,
			#f5ae2d,
			var(--color-primary),
			var(--color-secondary)
		);
	}

	.avatar-wrap.story.seen {
		background: var(--color-border-strong);
	}

	.avatar {
		display: grid;
		width: 100%;
		height: 100%;
		place-items: center;
		overflow: hidden;
		background: var(--color-secondary-soft);
		border: 2px solid var(--color-surface);
		border-radius: 50%;
		color: var(--color-secondary);
		font-size: 0.78rem;
		font-weight: 780;
	}

	.avatar img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
</style>
