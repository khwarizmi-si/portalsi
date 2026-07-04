<script lang="ts">
	import { goto, preloadData } from '$app/navigation';
	import { LoaderCircle } from '@lucide/svelte';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import { markStoryUserRead, readStoryUsers } from '$lib/story/read-state';

	let {
		userId,
		username,
		name,
		avatarUrl,
		hasStory = false,
		seen = false,
		size = 'md',
		storyOrder = [],
		profileHref = `/u/${username}`
	}: {
		userId: number;
		username: string;
		name: string;
		avatarUrl?: string;
		hasStory?: boolean;
		seen?: boolean;
		size?: 'sm' | 'md' | 'lg' | 'xl';
		storyOrder?: number[];
		profileHref?: string;
	} = $props();

	let loading = $state(false);
	let locallySeen = $state(false);
	const href = $derived(
		hasStory
			? `/stories/${userId}${storyOrder.length > 0 ? `?order=${storyOrder.join(',')}` : ''}`
			: profileHref
	);
	$effect(() => {
		if (seen) locallySeen = true;
	});

	async function open(event: MouseEvent) {
		if (!hasStory || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
		event.preventDefault();
		if (loading) return;
		loading = true;
		try {
			await preloadData(href);
			locallySeen = true;
			markStoryUserRead(userId);
			await goto(href);
		} finally {
			loading = false;
		}
	}
</script>

<a
	{href}
	onclick={open}
	class:loading
	aria-label={hasStory ? `Lihat cerita ${name}` : `Buka profil ${name}`}
>
	<Avatar
		{name}
		src={avatarUrl}
		{size}
		story={hasStory}
		seen={locallySeen || $readStoryUsers.has(userId)}
	/>
	{#if loading}<span class="spinner"><LoaderCircle size={size === 'sm' ? 14 : 18} /></span>{/if}
</a>

<style>
	a {
		position: relative;
		display: inline-grid;
		flex: none;
		place-items: center;
		border-radius: 50%;
	}
	a.loading {
		cursor: wait;
	}
	.spinner {
		position: absolute;
		inset: 3px;
		display: grid;
		place-items: center;
		background: rgb(25 20 15 / 58%);
		border-radius: 50%;
		color: white;
		backdrop-filter: blur(2px);
	}
	.spinner :global(svg) {
		animation: spin 0.75s linear infinite;
	}
	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}
</style>
