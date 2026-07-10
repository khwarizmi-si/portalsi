<script lang="ts">
	import { Expand, LoaderCircle, Pause, Play, Volume2, VolumeX } from '@lucide/svelte';
	let {
		src,
		poster,
		label = 'Video postingan',
		fill = false,
		autoplay = false,
		forceMuted = false,
		preferSound = false
	}: {
		src: string;
		poster?: string;
		label?: string;
		fill?: boolean;
		autoplay?: boolean;
		forceMuted?: boolean;
		preferSound?: boolean;
	} = $props();
	let video: HTMLVideoElement;
	let root: HTMLDivElement;
	let loading = $state(true);
	let hasFrame = $state(false);
	let failed = $state(false);
	let playing = $state(false);
	// forceMuted mengunci mute. preferSound (mis. di detail/modal) mulai dengan suara aktif;
	// bila browser memblokir autoplay bersuara, otomatis fallback ke mute agar tetap main.
	let muted = $state(forceMuted ? true : preferSound ? false : autoplay);
	let current = $state(0);
	let duration = $state(0);
	let mediaAspect = $state('16 / 9');

	function playWithFallback() {
		if (!video) return;
		void video.play().catch(() => {
			if (!forceMuted && !video.muted) {
				video.muted = true;
				muted = true;
				void video.play().catch(() => undefined);
			}
		});
	}

	function togglePlayback() {
		if (!video || failed) return;
		if (video.paused) void video.play();
		else video.pause();
	}
	function seek(event: Event) {
		const value = Number((event.currentTarget as HTMLInputElement).value);
		if (Number.isFinite(value)) video.currentTime = value;
	}
	function format(value: number) {
		if (!Number.isFinite(value)) return '0:00';
		const minutes = Math.floor(value / 60);
		return `${minutes}:${Math.floor(value % 60)
			.toString()
			.padStart(2, '0')}`;
	}
	function fullscreen(event: MouseEvent) {
		event.stopPropagation();
		void root.requestFullscreen?.();
	}

	// Autoplay ala Instagram: putar saat video masuk viewport, jeda saat digulir menjauh.
	$effect(() => {
		if (!autoplay) return;
		const el = video;
		const container = root;
		if (!el || !container) return;
		const observer = new IntersectionObserver(
			(entries) => {
				const entry = entries[0];
				if (!entry) return;
				if (entry.isIntersecting && entry.intersectionRatio >= 0.55) {
					playWithFallback();
				} else if (!el.paused) {
					el.pause();
				}
			},
			{ threshold: [0, 0.55, 1] }
		);
		observer.observe(container);
		return () => observer.disconnect();
	});
</script>

<div
	class="smart-video"
	bind:this={root}
	class:playing
	class:failed
	class:fill
	style:aspect-ratio={fill ? undefined : mediaAspect}
>
	<video
		bind:this={video}
		{src}
		{poster}
		bind:muted
		preload={autoplay ? 'auto' : 'metadata'}
		playsinline
		aria-label={label}
		onclick={togglePlayback}
		onloadstart={() => (loading = true)}
		onwaiting={() => {
			if (!hasFrame) loading = true;
		}}
		oncanplay={() => {
			hasFrame = true;
			loading = false;
		}}
		onloadeddata={() => {
			hasFrame = true;
			loading = false;
		}}
		onloadedmetadata={() => {
			duration = video.duration;
			if (video.videoWidth && video.videoHeight)
				mediaAspect = `${video.videoWidth} / ${video.videoHeight}`;
			loading = false;
		}}
		onplay={() => (playing = true)}
		onpause={() => (playing = false)}
		onended={() => (playing = false)}
		ontimeupdate={() => {
			current = video.currentTime;
			duration = video.duration || duration;
		}}
		onerror={() => {
			failed = true;
			loading = false;
		}}><track kind="captions" label="Takarir tidak tersedia" /></video
	>
	{#if loading && !failed}<div class="video-state">
			<LoaderCircle class="spin" size={28} /><span>Menyiapkan video…</span>
		</div>{/if}
	{#if failed}<div class="video-state error">
			<span>Video belum dapat diputar.</span><button
				onclick={(event) => {
					event.stopPropagation();
					hasFrame = false;
					loading = true;
					video.load();
					failed = false;
				}}>Coba lagi</button
			>
		</div>{/if}
	{#if !playing && !loading && !failed}<button
			class="center-play"
			aria-label="Putar video"
			onclick={(event) => {
				event.stopPropagation();
				togglePlayback();
			}}><Play size={28} fill="currentColor" /></button
		>{/if}
	<div class="video-controls">
		<button onclick={togglePlayback} aria-label={playing ? 'Jeda video' : 'Putar video'}
			>{#if playing}<Pause size={18} fill="currentColor" />{:else}<Play
					size={18}
					fill="currentColor"
				/>{/if}</button
		>
		<span>{format(current)}</span>
		<input
			aria-label="Posisi video"
			type="range"
			min="0"
			max={duration || 0}
			step="0.1"
			value={current}
			oninput={seek}
		/>
		<span>{format(duration)}</span>
		{#if !forceMuted}<button
				onclick={() => {
					video.muted = !video.muted;
					muted = video.muted;
				}}
				aria-label={muted ? 'Nyalakan suara' : 'Bisukan'}
				>{#if muted}<VolumeX size={18} />{:else}<Volume2 size={18} />{/if}</button
			>{/if}
		<button onclick={fullscreen} aria-label="Layar penuh"><Expand size={17} /></button>
	</div>
</div>

<style>
	.smart-video {
		position: relative;
		width: 100%;
		max-height: 82vh;
		overflow: hidden;
		background: #0b0c0d;
		cursor: pointer;
	}
	.smart-video.fill {
		height: 100%;
		max-height: none;
		aspect-ratio: auto;
	}
	video {
		width: 100%;
		height: 100%;
		object-fit: contain;
	}
	.video-state {
		position: absolute;
		inset: 0;
		display: grid;
		place-content: center;
		justify-items: center;
		gap: 8px;
		background: rgb(8 10 12 / 66%);
		color: white;
		font-size: 0.75rem;
		backdrop-filter: blur(4px);
	}
	.video-state.error button {
		padding: 7px 11px;
		background: white;
		border: 0;
		border-radius: 9px;
		font-weight: 720;
	}
	:global(.spin) {
		animation: spin 0.8s linear infinite;
	}
	.center-play {
		position: absolute;
		top: 50%;
		left: 50%;
		display: grid;
		width: 58px;
		height: 58px;
		padding: 0;
		place-items: center;
		background: rgb(10 12 14 / 70%);
		border: 1px solid rgb(255 255 255 / 25%);
		border-radius: 50%;
		color: white;
		transform: translate(-50%, -50%);
		backdrop-filter: blur(8px);
	}
	.video-controls {
		position: absolute;
		right: 10px;
		bottom: 10px;
		left: 10px;
		display: flex;
		min-height: 44px;
		align-items: center;
		gap: 8px;
		padding: 7px 9px;
		background: linear-gradient(135deg, rgb(12 15 18 / 82%), rgb(36 42 49 / 72%));
		border: 1px solid rgb(255 255 255 / 14%);
		border-radius: 13px;
		color: white;
		opacity: 0;
		transform: translateY(8px);
		transition: 180ms ease;
		backdrop-filter: blur(12px);
	}
	.smart-video:hover .video-controls,
	.smart-video:focus-within .video-controls,
	.smart-video:not(.playing) .video-controls {
		opacity: 1;
		transform: none;
	}
	.video-controls button {
		display: grid;
		width: 30px;
		height: 30px;
		flex: none;
		padding: 0;
		place-items: center;
		background: transparent;
		border: 0;
		border-radius: 8px;
		color: inherit;
	}
	.video-controls button:hover {
		background: rgb(255 255 255 / 14%);
	}
	.video-controls span {
		flex: none;
		font-size: 0.6rem;
		font-variant-numeric: tabular-nums;
	}
	.video-controls input {
		min-width: 40px;
		flex: 1;
		accent-color: #f28a22;
	}
	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}
	@media (hover: none) {
		.video-controls {
			opacity: 1;
			transform: none;
		}
	}
</style>
