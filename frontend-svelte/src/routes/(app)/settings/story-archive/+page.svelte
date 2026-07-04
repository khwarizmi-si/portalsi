<script lang="ts">
	import { Music2, Play } from '@lucide/svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import type { PageProps } from './$types';
	let { data }: PageProps = $props();
</script>

<svelte:head><title>Arsip cerita — Portal SI</title></svelte:head><SectionPage
	eyebrow="Kenangan Anda"
	title="Arsip cerita"
	description="Cerita yang telah melewati masa tayang 24 jam."
	><section class="archive">
		{#each data.stories as story (story.id)}<article>
				{#if story.mediaUrl}<img
						src={story.mediaUrl}
						alt={story.caption || 'Cerita tersimpan'}
					/>{:else}<div><Music2 size={28} /></div>{/if}{#if story.type === 'video'}<Play
						class="type"
						size={18}
						fill="currentColor"
					/>{/if}
				<p>{story.caption || 'Tanpa caption'}</p>
			</article>{/each}
	</section>
	{#if data.stories.length === 0}<p class="empty surface">Belum ada cerita di arsip.</p>{/if}
	<nav>
		{#if data.page > 1}<a href={`/settings/story-archive?page=${data.page - 1}`}>Sebelumnya</a
			>{/if}<span>Halaman {data.page}</span>{#if data.hasNext}<a
				href={`/settings/story-archive?page=${data.page + 1}`}>Berikutnya</a
			>{/if}
	</nav></SectionPage
>

<style>
	.archive {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		gap: 8px;
	}
	.archive article {
		position: relative;
		aspect-ratio: 9/16;
		overflow: hidden;
		background: var(--color-canvas-deep);
		border-radius: 13px;
	}
	.archive img,
	.archive article > div {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.archive article > div {
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
	}
	.archive :global(.type) {
		position: absolute;
		top: 8px;
		right: 8px;
		color: white;
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
		.archive article {
			border-radius: 8px;
		}
	}
</style>
