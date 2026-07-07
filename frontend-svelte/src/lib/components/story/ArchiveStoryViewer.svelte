<script lang="ts">
	import { ChevronLeft, ChevronRight, LoaderCircle, Music2, Trash2, X } from '@lucide/svelte';
	import { untrack } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import MentionText from '$lib/components/ui/MentionText.svelte';
	import { confirmAction } from '$lib/ui/confirm';

	type ArchiveStory = {
		id: number;
		type: 'image' | 'video' | 'music';
		mediaUrl: string | null;
		caption: string;
		createdLabel: string;
		musicTitle: string | null;
		musicArtist: string | null;
		musicPreviewUrl: string | null;
		albumArtUrl: string | null;
		musicStartSeconds: number;
		musicDurationSeconds: number;
	};

	let {
		stories: incoming,
		startIndex = 0,
		username,
		avatarUrl = null,
		onClose,
		onDeleted
	}: {
		stories: ArchiveStory[];
		startIndex?: number;
		username: string;
		avatarUrl?: string | null;
		onClose: () => void;
		onDeleted?: (id: number) => void;
	} = $props();

	let stories = $state(untrack(() => structuredClone(incoming)));
	let index = $state(untrack(() => Math.min(Math.max(0, startIndex), incoming.length - 1)));
	let paused = $state(false);
	let holding = $state(false);
	let muted = $state(true);
	let mediaElement = $state<HTMLMediaElement>();
	let musicElement = $state<HTMLAudioElement>();
	let mediaLoading = $state(true);
	let mediaError = $state(false);
	let status = $state('');
	const effectivePaused = $derived(paused || holding);
	const story = $derived(stories[index]);

	let vw = $state(430);
	let vh = $state(900);
	let frameAspect = $state(9 / 16);
	let segmentDuration = $state(7_000);
	const frame = $derived.by(() => {
		const mobile = vw > 0 && vw < 768;
		const maxW = mobile ? vw : Math.min(500, vw - 40);
		const maxH = mobile ? vh : vh - 40;
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

	function next() {
		if (index < stories.length - 1) index += 1;
		else onClose();
	}
	function previous() {
		if (index > 0) index -= 1;
	}

	$effect(() => {
		const current = story;
		if (!current) return;
		mediaLoading = current.type === 'music' ? Boolean(current.musicPreviewUrl) : true;
		mediaError = false;
		frameAspect = 9 / 16;
		segmentDuration = 7_000;
	});

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

	function captureAspect(width: number, height: number) {
		if (width > 0 && height > 0) frameAspect = width / height;
	}

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

	async function deleteStory() {
		const wasPaused = paused;
		paused = true;
		const confirmed = await confirmAction({
			title: 'Hapus cerita ini?',
			description: 'Cerita akan dihapus permanen dari arsip dan tidak dapat dipulihkan.',
			confirmLabel: 'Hapus cerita',
			tone: 'danger'
		});
		if (!confirmed) {
			paused = wasPaused;
			return;
		}
		const removedId = story.id;
		try {
			await clientRequest(`stories/${removedId}`, { method: 'DELETE' });
			stories.splice(index, 1);
			onDeleted?.(removedId);
			if (stories.length === 0) onClose();
			else if (index >= stories.length) index = stories.length - 1;
		} catch {
			status = 'Cerita belum dapat dihapus.';
			paused = wasPaused;
		}
	}

	function keyboard(event: KeyboardEvent) {
		if (event.key === 'ArrowRight') next();
		else if (event.key === 'ArrowLeft') previous();
		else if (event.key === ' ') {
			event.preventDefault();
			paused = !paused;
		} else if (event.key === 'Escape') onClose();
	}
</script>

<svelte:window onkeydown={keyboard} />

<div class="story-viewer" role="dialog" aria-modal="true" aria-label="Arsip cerita">
	<article
		style:width={`${frame.width}px`}
		style:height={`${frame.height}px`}
		onpointerdown={() => (holding = true)}
		onpointerup={() => (holding = false)}
		onpointercancel={() => (holding = false)}
	>
		<button class="story-zone story-zone-left" onclick={previous} aria-label="Cerita sebelumnya"
			><ChevronLeft size={28} /></button
		>
		<button class="story-zone story-zone-right" onclick={next} aria-label="Cerita berikutnya"
			><ChevronRight size={28} /></button
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
			<div class="story-user">
				<Avatar name={username} src={avatarUrl ?? undefined} size="sm" />
				<span><small>@{username} · {story?.createdLabel ?? ''}</small></span>
			</div>
			<button class="close" onclick={onClose} aria-label="Tutup cerita"><X size={19} /></button>
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
				alt={story.caption || `Cerita @${username}`}
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
			<button
				class="delete-story"
				onclick={(event) => {
					event.stopPropagation();
					void deleteStory();
				}}><Trash2 size={18} /> Hapus</button
			>
		</footer>
		{#if status}<p class="status">{status}</p>{/if}
	</article>
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
	.story-viewer article > button.story-zone {
		position: absolute;
		z-index: 2;
		top: 80px;
		bottom: 68px;
		width: 34%;
		height: auto;
		border-radius: 0;
		background: transparent;
		opacity: 0;
		transition:
			opacity 160ms ease,
			background 160ms ease;
	}
	.story-viewer article > button.story-zone:hover,
	.story-viewer article > button.story-zone:focus-visible {
		background: linear-gradient(90deg, rgb(0 0 0 / 24%), transparent);
		opacity: 1;
	}
	.story-viewer article > button.story-zone-left {
		left: 0;
		justify-items: start;
		padding-left: 12px;
	}
	.story-viewer article > button.story-zone-right {
		right: 0;
		justify-items: end;
		padding-right: 12px;
	}
	.story-viewer article > button.story-zone-right:hover,
	.story-viewer article > button.story-zone-right:focus-visible {
		background: linear-gradient(-90deg, rgb(0 0 0 / 24%), transparent);
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
	article > button.story-zone {
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
	article > footer button {
		display: flex;
		min-width: 122px;
		height: 44px;
		align-items: center;
		justify-content: center;
		gap: 7px;
		padding: 0 17px;
		background: rgb(87 27 25 / 48%);
		border: 1px solid rgb(255 150 145 / 65%);
		border-radius: 99px;
		color: #ffd2ce;
		font-size: 0.78rem;
		font-weight: 700;
		white-space: nowrap;
		backdrop-filter: blur(12px);
		transition:
			transform 160ms ease,
			background 160ms ease;
	}
	article > footer button:hover {
		transform: translateY(-2px);
	}
	.status {
		position: absolute;
		right: 12px;
		bottom: 64px;
		left: 12px;
		margin: 0;
		text-align: center;
		color: #ffd2ce;
		font-size: 0.72rem;
	}
	@media (max-width: 767px) {
		.story-viewer {
			padding: 0;
		}
		.story-viewer > article {
			border-radius: 0;
		}
		.story-viewer article > .story-media {
			position: absolute;
			inset: 0;
		}
		.story-viewer article > button.story-zone {
			display: flex;
		}
		article > footer button {
			min-width: 0;
			flex: 1;
		}
	}
</style>
