<script lang="ts">
	import { goto } from '$app/navigation';
	import {
		ChevronLeft,
		ChevronRight,
		Eye,
		LoaderCircle,
		MessageCircle,
		Music2,
		Trash2,
		X
	} from '@lucide/svelte';
	import { untrack } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import { storyViewersResponseSchema } from '$lib/schemas/story';
	import type { PageProps } from './$types';
	import { confirmAction } from '$lib/ui/confirm';
	import MentionText from '$lib/components/ui/MentionText.svelte';

	let { data }: PageProps = $props();
	let stories = $state(untrack(() => structuredClone(data.stories)));
	let index = $state(0);
	let paused = $state(false);
	let holding = $state(false);
	let muted = $state(true);
	let mediaElement = $state<HTMLMediaElement>();
	let musicElement = $state<HTMLAudioElement>();
	let viewers = $state<Array<{ id: number; username: string; avatarUrl: string | null }>>([]);
	let viewersOpen = $state(false);
	let viewerStatus = $state('');
	let mediaLoading = $state(true);
	let mediaError = $state(false);
	const effectivePaused = $derived(paused || holding || viewersOpen);
	const story = $derived(stories[index]);
	const storyOrderSuffix = $derived(data.storyOrder ? `?order=${data.storyOrder}` : '');
	const storyHref = (userId: number) => `/stories/${userId}${storyOrderSuffix}`;

	// Ukuran viewport untuk membingkai cerita mengikuti rasio media (mirip Instagram).
	let vw = $state(430);
	let vh = $state(900);
	let frameAspect = $state(9 / 16);
	let segmentDuration = $state(7_000);
	const frame = $derived.by(() => {
		const mobile = vw > 0 && vw < 768;
		const maxW = mobile ? Math.max(180, vw - 106) : Math.min(500, vw - 140);
		const maxH = mobile ? vh - 18 : vh - 40;
		const aspect = Math.min(1.91, Math.max(0.42, frameAspect));
		let width = maxW;
		let height = width / aspect;
		if (height > maxH) {
			height = maxH;
			width = height * aspect;
		}
		return { width: Math.round(width), height: Math.round(height) };
	});

	$effect(() => {
		const sync = () => {
			vw = window.innerWidth;
			vh = window.innerHeight;
		};
		sync();
		window.addEventListener('resize', sync);
		return () => window.removeEventListener('resize', sync);
	});

	// Resync ketika berpindah ke cerita user lain (goto tetap memakai komponen yang sama).
	$effect(() => {
		const nextStories = data.stories;
		void data.user.id;
		untrack(() => {
			stories = structuredClone(nextStories);
			index = 0;
			viewersOpen = false;
			paused = false;
		});
	});

	function captureAspect(width: number, height: number) {
		if (width > 0 && height > 0) frameAspect = width / height;
	}

	function next() {
		viewersOpen = false;
		if (index < stories.length - 1) index += 1;
		else if (data.nextUserId) void goto(storyHref(data.nextUserId));
		else closeStory();
	}

	function previous() {
		viewersOpen = false;
		if (index > 0) index -= 1;
		else if (data.previousUserId) void goto(storyHref(data.previousUserId));
	}

	function closeStory() {
		viewersOpen = false;
		if (history.length > 1) history.back();
		else void goto('/home', { replaceState: true });
	}

	// Reset media state hanya saat cerita berganti (bukan saat pause).
	$effect(() => {
		const current = story;
		if (!current) return;
		mediaLoading = current.type === 'music' ? Boolean(current.musicPreviewUrl) : true;
		mediaError = false;
		frameAspect = 9 / 16;
		segmentDuration = 7_000;
		void clientRequest(`stories/${current.id}/view`, { method: 'POST' }).catch(() => undefined);
	});

	// Timer maju otomatis; gambar/musik memakai durasi tetap, video memakai event onended.
	$effect(() => {
		if (!story || effectivePaused || story.type === 'video') return;
		const timer = window.setTimeout(next, segmentDuration);
		return () => window.clearTimeout(timer);
	});

	$effect(() => {
		const element = mediaElement;
		const music = musicElement;
		if (effectivePaused) {
			element?.pause();
			music?.pause();
		} else {
			if (element) void element.play().catch(() => undefined);
			if (music) void music.play().catch(() => undefined);
		}
	});

	function loopStoryMusic(event: Event) {
		const audio = event.currentTarget as HTMLAudioElement;
		const start =
			Number.isFinite(audio.duration) && story.musicStartSeconds < audio.duration
				? story.musicStartSeconds
				: 0;
		const end = Math.min(
			start + story.musicDurationSeconds,
			audio.duration || start + story.musicDurationSeconds
		);
		if (audio.currentTime < start || audio.currentTime >= end) {
			audio.currentTime = start;
			if (!effectivePaused) void audio.play().catch(() => undefined);
		}
	}

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
		const wasPaused = paused;
		paused = true;
		const confirmed = await confirmAction({
			title: 'Hapus cerita ini?',
			description: 'Cerita akan langsung dihapus dan tidak dapat dipulihkan dari arsip.',
			confirmLabel: 'Hapus cerita',
			tone: 'danger'
		});
		if (!confirmed) {
			paused = wasPaused;
			return;
		}
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
		} else if (event.key === 'Escape') closeStory();
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
	<button
		class="story-nav outside-prev"
		disabled={index === 0 && !data.previousUserId}
		onclick={previous}
		aria-label="Cerita sebelumnya"><ChevronLeft size={28} /></button
	>
	<article
		style:width={`${frame.width}px`}
		style:height={`${frame.height}px`}
		onpointerdown={() => (holding = true)}
		onpointerup={() => (holding = false)}
		onpointercancel={() => (holding = false)}
	>
		<div class="progress">
			{#each stories as item, itemIndex (item.id)}<span class:complete={itemIndex < index}
					>{#if itemIndex === index}<i
							style:animation-duration={`${segmentDuration}ms`}
							class:paused={effectivePaused}
						></i>{/if}</span
				>{/each}
		</div>
		<header>
			<a
				class="story-user"
				href={data.isOwn ? '/profile' : `/u/${data.user.username}`}
				aria-label={`Buka profil @${data.user.username}`}
			>
				<Avatar name={data.user.username} src={data.user.avatarUrl ?? undefined} size="sm" />
				<span><small>@{data.user.username} · {story?.createdLabel ?? ''}</small></span>
			</a>
			<button class="close" type="button" onclick={closeStory} aria-label="Tutup cerita"><X size={19} /></button>
		</header>
		{#if story && story.type === 'video' && story.mediaUrl}
			<video
				class="story-media"
				bind:this={mediaElement}
				src={story.mediaUrl}
				autoplay
				{muted}
				playsinline
				onended={next}
				onwaiting={() => (mediaLoading = true)}
				onloadedmetadata={(event) => {
					const video = event.currentTarget;
					captureAspect(video.videoWidth, video.videoHeight);
					if (Number.isFinite(video.duration) && video.duration > 0)
						segmentDuration = Math.round(video.duration * 1000);
				}}
				oncanplay={() => (mediaLoading = false)}
				onerror={() => {
					mediaLoading = false;
					mediaError = true;
				}}
			></video>
		{:else if story && story.mediaUrl}
			<div class="story-backdrop" style:background-image={`url('${story.mediaUrl}')`}></div>
			<img
				class="story-media"
				src={story.mediaUrl}
				alt={story.caption || `Cerita @${data.user.username}`}
				onload={(event) => {
					const image = event.currentTarget as HTMLImageElement;
					captureAspect(image.naturalWidth, image.naturalHeight);
					mediaLoading = false;
				}}
				onerror={() => {
					mediaLoading = false;
					mediaError = true;
				}}
			/>
		{:else if story}
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
						bind:this={musicElement}
						src={story.musicPreviewUrl}
						autoplay
						onplay={loopStoryMusic}
						ontimeupdate={loopStoryMusic}
						oncanplay={() => (mediaLoading = false)}
						onerror={() => {
							mediaLoading = false;
							mediaError = true;
						}}
					></audio>{/if}
			</div>
		{/if}
		{#if story?.musicPreviewUrl && story.type !== 'music'}<audio
				class="story-audio"
				bind:this={musicElement}
				src={story.musicPreviewUrl}
				autoplay
				onplay={loopStoryMusic}
				ontimeupdate={loopStoryMusic}
			></audio>{/if}
		{#if mediaLoading}<div class="media-loading">
				<LoaderCircle size={28} /><span>Menyiapkan cerita…</span>
			</div>{:else if mediaError}<div class="media-loading error">
				<span>Media cerita belum dapat dimuat.</span>
			</div>{/if}
		{#if story?.caption}<div class="story-caption">
				<p><MentionText text={story.caption} /></p>
			</div>{/if}
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
	<button
		class="story-nav outside-next"
		disabled={index === stories.length - 1 && !data.nextUserId}
		onclick={next}
		aria-label="Cerita berikutnya"><ChevronRight size={28} /></button
	>
</div>

<style>
	.story-viewer {
		position: fixed;
		z-index: 1000;
		inset: 0;
		display: flex;
		min-height: 100dvh;
		align-items: center;
		justify-content: center;
		padding: 20px;
		background:
			radial-gradient(circle at 50% 44%, rgb(115 81 47 / 22%), transparent 34rem), #100e0c;
	}
	.story-nav {
		display: grid;
		width: 46px;
		height: 72px;
		flex: none;
		place-items: center;
		background: rgb(255 255 255 / 11%);
		border: 1px solid rgb(255 255 255 / 16%);
		border-radius: 999px;
		color: white;
		cursor: pointer;
		backdrop-filter: blur(12px);
		transition:
			opacity 160ms ease,
			transform 160ms ease,
			background 160ms ease;
	}
	.story-nav:hover {
		background: rgb(255 255 255 / 18%);
		transform: translateY(-1px);
	}
	.story-nav:disabled {
		opacity: 0.25;
		cursor: default;
		transform: none;
	}
	.story-viewer > article {
		position: relative;
		overflow: hidden;
		isolation: isolate;
		background: #090807;
		border: 1px solid rgb(255 255 255 / 10%);
		border-radius: 22px;
		box-shadow: 0 30px 80px rgb(0 0 0 / 45%);
		color: white;
	}
	.story-viewer article > .story-media {
		position: relative;
		z-index: 0;
		width: 100%;
		height: 100%;
		object-fit: contain;
	}
	.story-backdrop {
		position: absolute;
		z-index: -1;
		inset: -34px;
		background-position: center;
		background-size: cover;
		filter: blur(28px) saturate(0.82);
		opacity: 0.42;
		transform: scale(1.08);
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
		position: relative;
		height: 3px;
		flex: 1;
		overflow: hidden;
		background: rgb(255 255 255 / 35%);
		border-radius: 99px;
	}
	.progress .complete {
		background: white;
	}
	.progress span i {
		display: block;
		width: 0;
		height: 100%;
		background: white;
		border-radius: 99px;
		animation-name: story-progress;
		animation-timing-function: linear;
		animation-fill-mode: forwards;
	}
	.progress span i.paused {
		animation-play-state: paused;
	}
	@keyframes story-progress {
		from {
			width: 0;
		}
		to {
			width: 100%;
		}
	}
	article > header {
		position: absolute;
		z-index: 2;
		top: 20px;
		right: 10px;
		left: 10px;
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 8px 9px;
		background: rgb(12 10 8 / 48%);
		border: 1px solid rgb(255 255 255 / 10%);
		border-radius: 14px;
		backdrop-filter: blur(12px);
	}
	.story-user {
		display: flex;
		align-items: center;
		gap: 8px;
		margin-right: auto;
		color: inherit;
	}
	.story-user span {
		display: grid;
	}
	article > header small {
		color: rgb(255 255 255 / 70%);
		font-size: 0.65rem;
	}
	article > header button,
	.viewer-panel > header button {
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
	article > header .close {
		display: grid;
		width: 36px;
		height: 36px;
		flex: none;
		place-items: center;
		background: rgb(0 0 0 / 25%);
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
		display: flex;
		justify-content: center;
		text-shadow: 0 2px 8px #000;
	}
	.story-caption p {
		max-width: 100%;
		margin: 0;
		padding: 8px 12px;
		background: rgb(0 0 0 / 38%);
		border-radius: 12px;
		font-size: 0.92rem;
		backdrop-filter: blur(8px);
	}
	article > footer {
		position: absolute;
		right: 12px;
		bottom: 12px;
		left: 12px;
		display: flex;
		gap: 10px;
		justify-content: center;
		padding-inline: 8px;
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
		width: auto;
		height: 44px;
		min-width: 122px;
		justify-content: center;
		padding: 0 17px;
		white-space: nowrap;
		backdrop-filter: blur(12px);
		transition:
			transform 160ms ease,
			background 160ms ease;
	}
	article > footer button:hover {
		background: rgb(0 0 0 / 52%);
		transform: translateY(-2px);
	}
	article > footer .delete-story {
		background: rgb(87 27 25 / 48%);
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
	@media (max-width: 767px) {
		.story-viewer {
			gap: 6px;
			padding: 8px;
		}
		.story-viewer > article {
			border-radius: 18px;
		}
		.story-viewer article > .story-media {
			position: absolute;
			inset: 0;
		}
		.story-nav {
			width: 38px;
			height: 58px;
		}
		article > footer button {
			min-width: 0;
			flex: 1;
		}
	}
</style>
