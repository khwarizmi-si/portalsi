<script lang="ts">
	import { Music2, Play } from '@lucide/svelte';
	import { untrack } from 'svelte';
	import { page } from '$app/state';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import ArchiveStoryViewer from '$lib/components/story/ArchiveStoryViewer.svelte';
	import type { PageProps } from './$types';
	let { data }: PageProps = $props();

	let stories = $state(untrack(() => [...data.stories]));
	let openIndex = $state<number | null>(null);

	// Resync bila pindah halaman arsip.
	$effect(() => {
		const next = data.stories;
		untrack(() => {
			stories = [...next];
			openIndex = null;
		});
	});

	const sessionUser = $derived(page.data.user);

	function removeStory(id: number) {
		stories = stories.filter((story) => story.id !== id);
	}
</script>

<svelte:head><title>Arsip cerita — Portal SI</title></svelte:head><SectionPage
	eyebrow="Kenangan Anda"
	title="Arsip cerita"
	description="Cerita yang telah melewati masa tayang 24 jam. Ketuk untuk memutarnya kembali."
	><section class="archive">
		{#each stories as story, i (story.id)}<button
				type="button"
				class="thumb"
				onclick={() => (openIndex = i)}
				aria-label={`Putar cerita: ${story.caption || 'tanpa caption'}`}
			>
				{#if story.thumbUrl}<img
						src={story.thumbUrl}
						alt={story.caption || 'Cerita tersimpan'}
					/>{:else}<div><Music2 size={28} /></div>{/if}{#if story.type === 'video'}<Play
						class="type"
						size={18}
						fill="currentColor"
					/>{:else if story.type === 'music'}<Music2 class="type" size={16} />{/if}
				<p>{story.caption || 'Tanpa caption'}</p>
			</button>{/each}
	</section>
	{#if stories.length === 0}<p class="empty surface">Belum ada cerita di arsip.</p>{/if}
	<nav>
		{#if data.page > 1}<a href={`/settings/story-archive?page=${data.page - 1}`}>Sebelumnya</a
			>{/if}<span>Halaman {data.page}</span>{#if data.hasNext}<a
				href={`/settings/story-archive?page=${data.page + 1}`}>Berikutnya</a
			>{/if}
	</nav></SectionPage
>

{#if openIndex !== null && sessionUser}
	<ArchiveStoryViewer
		{stories}
		startIndex={openIndex}
		username={sessionUser.username}
		avatarUrl={sessionUser.avatarUrl ?? null}
		onClose={() => (openIndex = null)}
		onDeleted={removeStory}
	/>
{/if}

<style>
	.archive {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		gap: 8px;
	}
	.archive .thumb {
		position: relative;
		aspect-ratio: 9/16;
		overflow: hidden;
		padding: 0;
		background: var(--color-canvas-deep);
		border: 0;
		border-radius: 13px;
		cursor: pointer;
	}
	.archive .thumb:hover img {
		transform: scale(1.04);
	}
	.archive img,
	.archive .thumb > div {
		width: 100%;
		height: 100%;
		object-fit: cover;
		transition: transform 200ms ease;
	}
	.archive .thumb > div {
		display: grid;
		place-items: center;
		color: var(--color-secondary);
	}
	.archive p {
		position: absolute;
		right: 0;
		bottom: 0;
		left: 0;
		margin: 0;
		padding: 25px 9px 8px;
		background: linear-gradient(transparent, rgb(0 0 0/0.7));
		color: white;
		font-size: 0.7rem;
		text-align: left;
	}
	.archive :global(.type) {
		position: absolute;
		top: 8px;
		right: 8px;
		color: white;
		filter: drop-shadow(0 1px 3px rgb(0 0 0 / 0.6));
	}
	.empty {
		padding: 40px;
		color: var(--color-muted);
		text-align: center;
	}
	nav {
		display: flex;
		justify-content: center;
		gap: 14px;
		padding: 18px;
		color: var(--color-muted);
		font-size: 0.75rem;
	}
	nav a {
		color: var(--color-primary-strong);
		font-weight: 700;
	}
	@media (max-width: 767px) {
		.archive {
			grid-template-columns: repeat(3, 1fr);
			padding: 0 8px;
		}
		.archive .thumb {
			border-radius: 8px;
		}
	}
</style>
