<script lang="ts">
	import { RotateCcw, X, ZoomIn, ZoomOut } from '@lucide/svelte';

	let {
		open,
		src,
		alt,
		isVideo = false,
		poster = null,
		onClose
	}: {
		open: boolean;
		src: string;
		alt: string;
		isVideo?: boolean;
		poster?: string | null;
		onClose: () => void;
	} = $props();
	let zoom = $state(1);

	$effect(() => {
		if (!open) return;
		zoom = 1;
		const previousOverflow = document.body.style.overflow;
		document.body.style.overflow = 'hidden';
		return () => {
			document.body.style.overflow = previousOverflow;
		};
	});

	function changeZoom(next: number) {
		zoom = Math.max(1, Math.min(4, Math.round(next * 10) / 10));
	}

	function keyboard(event: KeyboardEvent) {
		if (!open) return;
		if (event.key === 'Escape') onClose();
		else if (event.key === '+' || event.key === '=') changeZoom(zoom + 0.25);
		else if (event.key === '-') changeZoom(zoom - 0.25);
	}

	function wheel(event: WheelEvent) {
		event.preventDefault();
		changeZoom(zoom + (event.deltaY < 0 ? 0.2 : -0.2));
	}
</script>

<svelte:window onkeydown={keyboard} />

{#if open}
	<div
		class="backdrop"
		role="presentation"
		onclick={(event) => event.currentTarget === event.target && onClose()}
	>
		<div class="toolbar" aria-label="Kontrol pratinjau media">
			<button onclick={() => changeZoom(zoom - 0.25)} disabled={zoom <= 1} aria-label="Perkecil"
				><ZoomOut size={19} /></button
			>
			<span>{Math.round(zoom * 100)}%</span>
			<button onclick={() => changeZoom(zoom + 0.25)} disabled={zoom >= 4} aria-label="Perbesar"
				><ZoomIn size={19} /></button
			>
			<button onclick={() => (zoom = 1)} disabled={zoom === 1} aria-label="Atur ulang zoom"
				><RotateCcw size={18} /></button
			>
			<button class="close" onclick={onClose} aria-label="Tutup pratinjau"><X size={22} /></button>
		</div>
		<div class="stage" onwheel={wheel}>
			{#if isVideo}
				<!-- svelte-ignore a11y_media_has_caption -->
				<video
					{src}
					{poster}
					controls
					autoplay
					playsinline
					style:transform={`scale(${zoom})`}
					aria-label={alt}
				></video>
			{:else}
				<img {src} {alt} style:transform={`scale(${zoom})`} />
			{/if}
		</div>
		<p class="hint">Scroll atau gunakan tombol untuk memperbesar · Esc untuk menutup</p>
	</div>
{/if}

<style>
	.backdrop {
		position: fixed;
		z-index: 1600;
		inset: 0;
		display: grid;
		place-items: center;
		padding: 74px 24px 46px;
		background: rgb(10 9 8 / 94%);
		backdrop-filter: blur(16px);
		animation: lightbox-in 180ms ease-out;
	}
	.toolbar {
		position: absolute;
		top: max(18px, env(safe-area-inset-top));
		right: 20px;
		display: flex;
		align-items: center;
		gap: 5px;
		padding: 5px;
		background: rgb(255 255 255 / 11%);
		border: 1px solid rgb(255 255 255 / 13%);
		border-radius: 999px;
		color: white;
	}
	.toolbar button {
		display: grid;
		width: 38px;
		height: 38px;
		place-items: center;
		padding: 0;
		background: transparent;
		border: 0;
		border-radius: 50%;
		color: inherit;
	}
	.toolbar button:hover:not(:disabled) {
		background: rgb(255 255 255 / 14%);
	}
	.toolbar button:disabled {
		opacity: 0.35;
	}
	.toolbar span {
		min-width: 44px;
		font-size: 0.7rem;
		font-weight: 720;
		text-align: center;
	}
	.toolbar .close {
		margin-left: 3px;
		background: rgb(255 255 255 / 12%);
	}
	.stage {
		display: grid;
		width: min(1120px, 100%);
		height: min(78dvh, 850px);
		place-items: center;
		overflow: hidden;
		border-radius: 18px;
		cursor: zoom-in;
	}
	.stage img,
	.stage video {
		display: block;
		max-width: 100%;
		max-height: 100%;
		object-fit: contain;
		border-radius: 8px;
		box-shadow: 0 28px 80px rgb(0 0 0 / 45%);
		transition: transform 150ms ease;
		transform-origin: center;
	}
	.stage video {
		width: min(100%, 920px);
	}
	.hint {
		position: absolute;
		bottom: max(15px, env(safe-area-inset-bottom));
		margin: 0;
		color: rgb(255 255 255 / 58%);
		font-size: 0.68rem;
	}
	@keyframes lightbox-in {
		from {
			opacity: 0;
		}
		to {
			opacity: 1;
		}
	}
	@media (max-width: 767px) {
		.backdrop {
			padding: 68px 0 34px;
		}
		.toolbar {
			right: 10px;
		}
		.toolbar span,
		.hint {
			display: none;
		}
		.stage {
			height: calc(100dvh - 108px);
			border-radius: 0;
		}
	}
	@media (prefers-reduced-motion: reduce) {
		.backdrop {
			animation: none;
		}
		.stage img,
		.stage video {
			transition: none;
		}
	}
</style>
