<script lang="ts">
	import { Move, ZoomIn } from '@lucide/svelte';
	import { SvelteMap } from 'svelte/reactivity';
	import type { CropRegion } from '$lib/utils/image-crop';

	let {
		src,
		aspect,
		label,
		round = false,
		filterCss = 'none',
		onready,
		onregion
	}: {
		src: string;
		aspect: number;
		label: string;
		round?: boolean;
		filterCss?: string;
		onready?: (aspect: number) => void;
		onregion?: (region: CropRegion) => void;
	} = $props();

	let containerWidth = $state(0);
	let naturalWidth = $state(0);
	let naturalHeight = $state(0);
	let zoom = $state(1);
	let offsetX = $state(0);
	let offsetY = $state(0);
	let dragging = $state(false);
	const pointers = new SvelteMap<number, { x: number; y: number }>();
	let lastPinchDistance = 0;

	const containerHeight = $derived(containerWidth / aspect);
	const ready = $derived(naturalWidth > 0 && naturalHeight > 0 && containerWidth > 0);
	const coverScale = $derived(
		ready ? Math.max(containerWidth / naturalWidth, containerHeight / naturalHeight) : 1
	);
	const displayScale = $derived(coverScale * zoom);
	const displayWidth = $derived(naturalWidth * displayScale);
	const displayHeight = $derived(naturalHeight * displayScale);
	const maxOffsetX = $derived(Math.max(0, (displayWidth - containerWidth) / 2));
	const maxOffsetY = $derived(Math.max(0, (displayHeight - containerHeight) / 2));

	function clamp(value: number, limit: number) {
		return Math.min(limit, Math.max(-limit, value));
	}

	function clampZoom(value: number) {
		return Math.min(4, Math.max(1, value));
	}

	// Jaga agar pan tetap di dalam batas ketika zoom berubah.
	$effect(() => {
		offsetX = clamp(offsetX, maxOffsetX);
		offsetY = clamp(offsetY, maxOffsetY);
	});

	// Hitung region sumber (piksel asli) sehingga hasil crop persis seperti pratinjau.
	$effect(() => {
		if (!ready) return;
		const sw = containerWidth / displayScale;
		const sh = containerHeight / displayScale;
		const sx = (naturalWidth - sw) / 2 - offsetX / displayScale;
		const sy = (naturalHeight - sh) / 2 - offsetY / displayScale;
		onregion?.({ sx, sy, sw, sh });
	});

	function onImageLoad(event: Event) {
		const image = event.currentTarget as HTMLImageElement;
		naturalWidth = image.naturalWidth;
		naturalHeight = image.naturalHeight;
		onready?.(image.naturalWidth / image.naturalHeight);
		zoom = 1;
		offsetX = 0;
		offsetY = 0;
	}

	let startX = 0;
	let startY = 0;
	let startOffsetX = 0;
	let startOffsetY = 0;

	function onPointerDown(event: PointerEvent) {
		dragging = true;
		pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
		startX = event.clientX;
		startY = event.clientY;
		startOffsetX = offsetX;
		startOffsetY = offsetY;
		(event.currentTarget as HTMLElement).setPointerCapture(event.pointerId);
		if (pointers.size === 2) {
			const [first, second] = [...pointers.values()];
			lastPinchDistance = Math.hypot(second.x - first.x, second.y - first.y);
		}
	}

	function onPointerMove(event: PointerEvent) {
		if (!pointers.has(event.pointerId)) return;
		pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
		if (pointers.size >= 2) {
			const [first, second] = [...pointers.values()];
			const distance = Math.hypot(second.x - first.x, second.y - first.y);
			if (lastPinchDistance > 0) zoom = clampZoom(zoom * (distance / lastPinchDistance));
			lastPinchDistance = distance;
			return;
		}
		if (!dragging) return;
		offsetX = clamp(startOffsetX + (event.clientX - startX), maxOffsetX);
		offsetY = clamp(startOffsetY + (event.clientY - startY), maxOffsetY);
	}

	function onPointerUp(event: PointerEvent) {
		pointers.delete(event.pointerId);
		dragging = pointers.size > 0;
		lastPinchDistance = 0;
		const remaining = [...pointers.values()][0];
		if (remaining) {
			startX = remaining.x;
			startY = remaining.y;
			startOffsetX = offsetX;
			startOffsetY = offsetY;
		}
		(event.currentTarget as HTMLElement).releasePointerCapture?.(event.pointerId);
	}

	function onWheel(event: WheelEvent) {
		event.preventDefault();
		zoom = clampZoom(zoom + (event.deltaY < 0 ? 0.12 : -0.12));
	}

	function onKeyDown(event: KeyboardEvent) {
		const step = 12;
		if (event.key === 'ArrowLeft') offsetX = clamp(offsetX + step, maxOffsetX);
		else if (event.key === 'ArrowRight') offsetX = clamp(offsetX - step, maxOffsetX);
		else if (event.key === 'ArrowUp') offsetY = clamp(offsetY + step, maxOffsetY);
		else if (event.key === 'ArrowDown') offsetY = clamp(offsetY - step, maxOffsetY);
		else return;
		event.preventDefault();
	}
</script>

<section class="cropper" class:round>
	<div
		class="crop-window"
		class:dragging
		style:aspect-ratio={aspect}
		style:width={`min(100%, ${Math.round(620 * aspect)}px, ${62 * aspect}dvh)`}
		bind:clientWidth={containerWidth}
		onpointerdown={onPointerDown}
		onpointermove={onPointerMove}
		onpointerup={onPointerUp}
		onpointercancel={onPointerUp}
		onwheel={onWheel}
		onkeydown={onKeyDown}
		role="slider"
		tabindex="0"
		aria-valuemin="0"
		aria-valuemax="100"
		aria-valuenow="50"
		aria-label={`${label}. Seret atau gunakan tombol panah untuk menggeser, penggeser zoom untuk memperbesar.`}
	>
		<img
			{src}
			alt={label}
			draggable="false"
			onload={onImageLoad}
			style:width={`${displayWidth}px`}
			style:height={`${displayHeight}px`}
			style:transform={`translate(-50%, -50%) translate(${offsetX}px, ${offsetY}px)`}
			style:filter={filterCss}
		/>
		<div class="crop-guide"></div>
	</div>
	<label class="zoom">
		<ZoomIn size={14} /><span>Zoom</span><input
			type="range"
			min="1"
			max="4"
			step="0.02"
			bind:value={zoom}
			aria-label="Perbesar gambar"
		/>
	</label>
	<p class="hint"><Move size={12} /> Seret untuk menggeser · cubit atau scroll untuk zoom.</p>
</section>

<style>
	.cropper {
		display: grid;
		gap: 9px;
		padding: 10px;
		background: var(--color-canvas);
		border: 1px solid var(--color-border);
		border-radius: 14px;
	}
	.crop-window {
		position: relative;
		width: 100%;
		overflow: hidden;
		background: #171512;
		border-radius: 10px;
		cursor: grab;
		touch-action: none;
		user-select: none;
		margin-inline: auto;
	}
	.crop-window.dragging {
		cursor: grabbing;
	}
	.crop-window img {
		position: absolute;
		top: 50%;
		left: 50%;
		max-width: none;
		pointer-events: none;
		will-change: transform;
	}
	.crop-guide {
		position: absolute;
		inset: 0;
		border: 1px solid rgb(255 255 255 / 70%);
		box-shadow: inset 0 0 0 1px rgb(0 0 0 / 18%);
		pointer-events: none;
	}
	.round .crop-window {
		width: min(100%, 260px);
		margin: auto;
		border-radius: 50%;
	}
	.round .crop-guide {
		border: 2px solid white;
		border-radius: 50%;
		box-shadow: 0 0 0 999px rgb(0 0 0 / 28%);
	}
	.zoom {
		display: grid;
		grid-template-columns: 16px 46px 1fr;
		align-items: center;
		gap: 6px;
	}
	.zoom span {
		color: var(--color-muted);
		font-size: 0.66rem;
	}
	.zoom input {
		width: 100%;
		height: 24px;
		padding: 0;
		accent-color: var(--color-primary);
	}
	.hint {
		display: flex;
		align-items: center;
		gap: 5px;
		margin: 0;
		color: var(--color-muted);
		font-size: 0.66rem;
	}
</style>
