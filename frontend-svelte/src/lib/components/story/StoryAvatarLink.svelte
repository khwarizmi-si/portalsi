<script lang="ts">
	import { goto, preloadData } from '$app/navigation';
	import { Expand, LoaderCircle, X } from '@lucide/svelte';
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
		profileHref = `/u/${username}`,
		previewable = false
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
		previewable?: boolean;
	} = $props();

	let loading = $state(false);
	let photoOpen = $state(false);
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
		if (
			previewable &&
			!hasStory &&
			avatarUrl &&
			!event.metaKey &&
			!event.ctrlKey &&
			!event.shiftKey &&
			!event.altKey
		) {
			event.preventDefault();
			photoOpen = true;
			return;
		}
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
	function closePhoto() {
		photoOpen = false;
	}
</script>

<svelte:window onkeydown={(event) => photoOpen && event.key === 'Escape' && closePhoto()} />

<span class="avatar-action">
	<a
		{href}
		onclick={open}
		class:loading
		aria-label={hasStory
			? `Lihat cerita ${name}`
			: previewable && avatarUrl
				? `Perbesar foto profil ${name}`
				: `Buka profil ${name}`}
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
	{#if previewable && hasStory && avatarUrl}<button
			type="button"
			class="expand-photo"
			onclick={() => (photoOpen = true)}
			aria-label={`Perbesar foto profil ${name}`}><Expand size={13} /></button
		>{/if}
</span>

{#if photoOpen && avatarUrl}<div
		class="photo-backdrop"
		role="button"
		tabindex="0"
		aria-label="Tutup foto profil"
		onclick={closePhoto}
		onkeydown={(event) => (event.key === 'Enter' || event.key === ' ') && closePhoto()}
	>
		<div
			class="photo-dialog"
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			aria-label={`Foto profil ${name}`}
			onclick={(event) => event.stopPropagation()}
			onkeydown={(event) => event.stopPropagation()}
		>
			<button type="button" class="photo-close" onclick={closePhoto} aria-label="Tutup foto profil"
				><X size={20} /></button
			>
			<img src={avatarUrl} alt={`Foto profil ${name}`} />
			<strong>{name}</strong><span>@{username}</span>
		</div>
	</div>{/if}

<style>
	.avatar-action,
	a {
		position: relative;
		display: inline-grid;
		flex: none;
		place-items: center;
		border-radius: 50%;
	}
	.expand-photo {
		position: absolute;
		right: -3px;
		bottom: -3px;
		display: grid;
		width: 25px;
		height: 25px;
		place-items: center;
		background: var(--color-primary);
		border: 2px solid var(--color-surface);
		border-radius: 50%;
		color: white;
		box-shadow: 0 4px 12px rgb(0 0 0 / 18%);
		cursor: zoom-in;
	}
	.photo-backdrop {
		position: fixed;
		z-index: 1000;
		inset: 0;
		display: grid;
		place-items: center;
		padding: 24px;
		background: rgb(17 14 12 / 78%);
		backdrop-filter: blur(12px);
	}
	.photo-dialog {
		position: relative;
		display: grid;
		justify-items: center;
		gap: 5px;
		width: min(92vw, 520px);
		color: white;
	}
	.photo-dialog img {
		width: min(78vw, 440px);
		aspect-ratio: 1;
		object-fit: cover;
		border: 4px solid rgb(255 255 255 / 88%);
		border-radius: 50%;
		box-shadow: 0 24px 80px rgb(0 0 0 / 45%);
	}
	.photo-dialog strong {
		margin-top: 12px;
		font-size: 1.05rem;
	}
	.photo-dialog span {
		color: rgb(255 255 255 / 70%);
		font-size: 0.82rem;
	}
	.photo-close {
		position: absolute;
		top: -12px;
		right: 0;
		display: grid;
		width: 40px;
		height: 40px;
		place-items: center;
		background: rgb(255 255 255 / 14%);
		border: 1px solid rgb(255 255 255 / 24%);
		border-radius: 50%;
		color: white;
		cursor: pointer;
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
