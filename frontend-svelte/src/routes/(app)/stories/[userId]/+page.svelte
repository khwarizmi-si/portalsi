<script lang="ts">
	import { goto } from '$app/navigation';
	import {
		ChevronLeft,
		ChevronRight,
		Eye,
		LoaderCircle,
		MessageCircle,
		Music2,
		Pause,
		Play,
		Trash2,
		Volume2,
		VolumeX,
		X
	} from '@lucide/svelte';
	import { untrack } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import { storyViewersResponseSchema } from '$lib/schemas/story';
	import type { PageProps } from './$types';
	import { confirmAction } from '$lib/ui/confirm';

	let { data }: PageProps = $props();
	let stories = $state(untrack(() => structuredClone(data.stories)));
	let index = $state(0);
	let paused = $state(false);
	let holding = $state(false);
	let muted = $state(true);
	let mediaElement = $state<HTMLMediaElement>();
	let viewers = $state<Array<{ id: number; username: string; avatarUrl: string | null }>>([]);
	let viewersOpen = $state(false);
	let viewerStatus = $state('');
	let mediaLoading = $state(true);
	let mediaError = $state(false);
	const effectivePaused = $derived(paused || holding || viewersOpen);
	const story = $derived(stories[index]);

	function next() {
		viewersOpen = false;
		if (index < stories.length - 1) index += 1;
		else if (data.nextUserId) void goto(`/stories/${data.nextUserId}`);
		else void goto('/home');
	}

	function previous() {
		viewersOpen = false;
		if (index > 0) index -= 1;
		else if (data.previousUserId) void goto(`/stories/${data.previousUserId}`);
	}

	$effect(() => {
		const storyId = story.id;
		mediaLoading = story.type === 'music' ? Boolean(story.musicPreviewUrl) : true;
		mediaError = false;
		void clientRequest(`stories/${storyId}/view`, { method: 'POST' }).catch(() => undefined);
		if (effectivePaused || story.type === 'video') return;
		const timer = window.setTimeout(next, 7_000);
		return () => window.clearTimeout(timer);
	});

	$effect(() => {
		const element = mediaElement;
		if (!element) return;
		if (effectivePaused) element.pause();
		else void element.play().catch(() => undefined);
	});

	async function openViewers() {
		viewersOpen = true;
		viewerStatus = '';
		try {
			const response = await clientRequest(`stories/${story.id}/viewers`, {
				schema: storyViewersResponseSchema
			});
			viewers = response.viewers.map((viewer) => ({
				id: viewer.user_id,
				username: viewer.username,
				avatarUrl: viewer.profile_picture_url ?? null
			}));
		} catch {
			viewerStatus = 'Daftar penonton belum dapat dimuat.';
		}
	}

	async function deleteStory() {
		if (
			!(await confirmAction({
				title: 'Hapus cerita ini?',
				description: 'Cerita akan langsung dihapus dan tidak dapat dipulihkan dari arsip.',
				confirmLabel: 'Hapus cerita',
				tone: 'danger'
			}))
		)
			return;
		try {
			await clientRequest(`stories/${story.id}`, { method: 'DELETE' });
			stories.splice(index, 1);
			if (stories.length === 0) await goto('/home');
			else if (index >= stories.length) index = stories.length - 1;
		} catch {
			viewerStatus = 'Cerita belum dapat dihapus.';
		}
	}

	function keyboard(event: KeyboardEvent) {
		if (event.key === 'ArrowRight') next();
		else if (event.key === 'ArrowLeft') previous();
		else if (event.key === ' ') {
			event.preventDefault();
			paused = !paused;
		} else if (event.key === 'Escape') void goto('/home');
	}
</script>

<svelte:window onkeydown={keyboard} />

<svelte:head
	><title>Cerita @{data.user.username} — Portal SI</title><meta
		name="robots"
		content="noindex"
	/></svelte:head
>

<div class="story-viewer">
	<a class="close" href="/home" aria-label="Tutup cerita"><X size={22} /></a>
	<button
		class="previous"
		onclick={previous}
		disabled={index === 0 && !data.previousUserId}
		aria-label="Cerita sebelumnya"><ChevronLeft size={26} /></button
	>
	<article
		onpointerdown={() => (holding = true)}
		onpointerup={() => (holding = false)}
		onpointercancel={() => (holding = false)}
	>
		<div class="progress">
			{#each stories as item, itemIndex (item.id)}<span
					class:complete={itemIndex < index}
					class:current={itemIndex === index}
				></span>{/each}
		</div>
		<header>
			<Avatar name={data.user.username} src={data.user.avatarUrl ?? undefined} size="sm" />
			<span><strong>@{data.user.username}</strong><small>{story.createdLabel}</small></span>
			<button onclick={() => (paused = !paused)} aria-label={paused ? 'Lanjutkan' : 'Jeda'}
				>{#if paused}<Play size={18} />{:else}<Pause size={18} />{/if}</button
			>
			<button onclick={() => (muted = !muted)} aria-label={muted ? 'Aktifkan suara' : 'Bisukan'}
				>{#if muted}<VolumeX size={17} />{:else}<Volume2 size={17} />{/if}</button
			>
		</header>
		{#if story.type === 'video' && story.mediaUrl}
			<video
				bind:this={mediaElement}
				src={story.mediaUrl}
				autoplay
				{muted}
				playsinline
				onended={next}
				onwaiting={() => (mediaLoading = true)}
				oncanplay={() => (mediaLoading = false)}
				onerror={() => {
					mediaLoading = false;
					mediaError = true;
				}}
			></video>
		{:else if story.mediaUrl}
			<img
				src={story.mediaUrl}
				alt={story.caption || `Cerita @${data.user.username}`}
				onload={() => (mediaLoading = false)}
				onerror={() => {
					mediaLoading = false;
					mediaError = true;
				}}
			/>
		{:else}
			<div
				class="music-story"
				style:background-image={story.albumArtUrl
					? `linear-gradient(rgb(0 0 0 / 48%), rgb(0 0 0 / 70%)), url('${story.albumArtUrl}')`
					: undefined}
			>
				<Music2 size={44} /><strong>{story.musicTitle || 'Cerita musik'}</strong><span
					>{story.musicArtist || 'Portal SI'}</span
				>
				{#if story.musicPreviewUrl}<audio
						bind:this={mediaElement}
						src={story.musicPreviewUrl}
						autoplay
						onended={next}
						oncanplay={() => (mediaLoading = false)}
						onerror={() => {
							mediaLoading = false;
							mediaError = true;
						}}
					></audio>{/if}
			</div>
		{/if}
		{#if mediaLoading}<div class="media-loading">
				<LoaderCircle size={28} /><span>Menyiapkan cerita…</span>
			</div>{:else if mediaError}<div class="media-loading error">
				<span>Media cerita belum dapat dimuat.</span>
			</div>{/if}
		{#if story.caption}<div class="story-caption"><p>{story.caption}</p></div>{/if}
		<footer>
			{#if data.isOwn}<button
					onclick={(event) => {
						event.stopPropagation();
						void openViewers();
					}}><Eye size={18} /> Penonton</button
				><button
					class="delete-story"
					onclick={(event) => {
						event.stopPropagation();
						void deleteStory();
					}}><Trash2 size={18} /> Hapus</button
				>{:else}<a href={`/messages/direct/${data.user.id}`}
					><MessageCircle size={19} /> Kirim pesan</a
				>{/if}
		</footer>
		{#if viewersOpen}<aside class="viewer-panel" onpointerdown={(event) => event.stopPropagation()}>
				<header>
					<strong>Penonton ({viewers.length})</strong><button
						onclick={() => (viewersOpen = false)}
						aria-label="Tutup daftar penonton"><X size={16} /></button
					>
				</header>
				{#if viewerStatus}<p>{viewerStatus}</p>{/if}
				<div>
					{#each viewers as viewer (viewer.id)}<a href={`/u/${viewer.username}`}
							><Avatar name={viewer.username} src={viewer.avatarUrl ?? undefined} size="sm" /> @{viewer.username}</a
						>{/each}{#if !viewerStatus && viewers.length === 0}<p>Belum ada penonton.</p>{/if}
				</div>
			</aside>{/if}
	</article>
	<button class="next" onclick={next} aria-label="Cerita berikutnya"
		><ChevronRight size={26} /></button
	>
</div>

<style>
	.story-viewer {
		position: relative;
		display: grid;
		min-height: 100vh;
		grid-template-columns: auto minmax(300px, 430px) auto;
		place-content: center;
		gap: 20px;
		padding: 20px;
		background: #17130f;
	}
	.story-viewer > article {
		position: relative;
		aspect-ratio: 9/16;
		max-height: calc(100vh - 40px);
		overflow: hidden;
		background: #33271e;
		border-radius: 18px;
		box-shadow: 0 30px 80px rgb(0 0 0 / 45%);
		color: white;
	}
	.story-viewer article > img,
	.story-viewer article > video {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.progress {
		position: absolute;
		z-index: 3;
		top: 10px;
		right: 10px;
		left: 10px;
		display: flex;
		gap: 4px;
	}
	.progress span {
		height: 3px;
		flex: 1;
		background: rgb(255 255 255 / 35%);
		border-radius: 99px;
	}
	.progress .complete {
		background: white;
	}
	.progress .current {
		background: linear-gradient(90deg, white 58%, rgb(255 255 255 / 35%) 58%);
	}
	article > header {
		position: absolute;
		z-index: 2;
		top: 22px;
		right: 10px;
		left: 10px;
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 8px;
		background: linear-gradient(rgb(0 0 0 / 45%), transparent);
		border-radius: 12px;
	}
	article > header > span {
		display: grid;
		margin-right: auto;
	}
	article > header strong {
		font-size: 0.78rem;
	}
	article > header small {
		color: rgb(255 255 255 / 70%);
		font-size: 0.65rem;
	}
	article button {
		display: grid;
		width: 36px;
		height: 36px;
		place-items: center;
		padding: 0;
		background: rgb(0 0 0 / 25%);
		border: 0;
		border-radius: 50%;
		color: white;
	}
	.music-story {
		display: grid;
		width: 100%;
		height: 100%;
		place-content: center;
		justify-items: center;
		gap: 8px;
		padding: 30px;
		background: linear-gradient(145deg, #76532f, #1d544d);
		background-position: center;
		background-size: cover;
		text-align: center;
	}
	.media-loading {
		position: absolute;
		z-index: 1;
		inset: 0;
		display: grid;
		place-content: center;
		justify-items: center;
		gap: 9px;
		background: rgb(28 20 14 / 46%);
		color: white;
		font-size: 0.74rem;
		pointer-events: none;
	}
	.media-loading :global(svg) {
		animation: media-spin 0.8s linear infinite;
	}
	.media-loading.error {
		padding: 28px;
		text-align: center;
	}
	@keyframes media-spin {
		to {
			transform: rotate(360deg);
		}
	}
	.music-story strong {
		font-size: 1.25rem;
	}
	.music-story span {
		color: rgb(255 255 255 / 75%);
	}
	.story-caption {
		position: absolute;
		right: 20px;
		bottom: 74px;
		left: 20px;
		text-shadow: 0 2px 8px #000;
	}
	.story-caption p {
		margin: 0;
		font-size: 0.92rem;
	}
	article > footer {
		position: absolute;
		right: 12px;
		bottom: 12px;
		left: 12px;
		display: flex;
		justify-content: center;
	}
	article > footer a,
	article > footer button {
		display: flex;
		min-height: 42px;
		align-items: center;
		gap: 7px;
		padding: 0 16px;
		background: rgb(0 0 0 / 35%);
		border: 1px solid rgb(255 255 255 / 45%);
		border-radius: 99px;
		color: white;
		font-size: 0.78rem;
		font-weight: 700;
	}
	article > footer button {
		padding: 0 13px;
	}
	article > footer .delete-story {
		border-color: rgb(255 150 145 / 65%);
		color: #ffd2ce;
	}
	.viewer-panel {
		position: absolute;
		z-index: 5;
		right: 12px;
		bottom: 66px;
		left: 12px;
		max-height: 45%;
		overflow: hidden;
		background: rgb(24 20 16 / 95%);
		border: 1px solid rgb(255 255 255 / 18%);
		border-radius: 14px;
	}
	.viewer-panel > header {
		position: static;
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 11px 12px;
		background: transparent;
		border-bottom: 1px solid rgb(255 255 255 / 12%);
	}
	.viewer-panel > div {
		display: grid;
		max-height: 230px;
		overflow-y: auto;
		padding: 6px 12px;
	}
	.viewer-panel a {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 8px 0;
		color: white;
		font-size: 0.72rem;
	}
	.viewer-panel p {
		margin: 0;
		padding: 12px;
		color: rgb(255 255 255 / 68%);
		font-size: 0.72rem;
		text-align: center;
	}
	.close {
		position: absolute;
		z-index: 4;
		top: 24px;
		right: 24px;
		display: grid;
		width: 44px;
		height: 44px;
		place-items: center;
		background: rgb(255 255 255 / 10%);
		border-radius: 50%;
		color: white;
	}
	.previous,
	.next {
		display: grid;
		width: 48px;
		height: 48px;
		align-self: center;
		place-items: center;
		background: rgb(255 255 255 / 10%);
		border: 0;
		border-radius: 50%;
		color: white;
	}
	.previous:disabled {
		opacity: 0.25;
	}
	@media (max-width: 767px) {
		.story-viewer {
			display: block;
			padding: 0;
		}
		.story-viewer > article {
			width: 100%;
			max-height: none;
			min-height: calc(100vh - 64px);
			border-radius: 0;
		}
		.previous,
		.next {
			display: none;
		}
		.close {
			top: 14px;
			right: 12px;
			background: rgb(0 0 0 / 25%);
		}
		.story-viewer article > img,
		.story-viewer article > video {
			position: absolute;
			inset: 0;
		}
	}
</style>
