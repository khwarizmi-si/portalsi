<script lang="ts">
	import { Move, Search } from '@lucide/svelte';
	let {
		src,
		aspect,
		label,
		round = false,
		zoom = $bindable(1),
		x = $bindable(0),
		y = $bindable(0)
	}: {
		src: string;
		aspect: number;
		label: string;
		round?: boolean;
		zoom?: number;
		x?: number;
		y?: number;
	} = $props();
</script>

<section class="cropper" class:round>
	<div class="crop-window" style:aspect-ratio={aspect}>
		<img
			{src}
			alt={label}
			style:object-position={`${50 + x}% ${50 + y}%`}
			style:transform={`scale(${zoom})`}
		/>
		<div class="crop-guide"></div>
	</div>
	<div class="crop-sliders">
		<label
			><Search size={13} /><span>Zoom</span><input
				type="range"
				min="1"
				max="3"
				step="0.05"
				bind:value={zoom}
			/></label
		>
		<label
			><Move size={13} /><span>Kiri/kanan</span><input
				type="range"
				min="-50"
				max="50"
				step="1"
				bind:value={x}
			/></label
		>
		<label
			><Move size={13} /><span>Atas/bawah</span><input
				type="range"
				min="-50"
				max="50"
				step="1"
				bind:value={y}
			/></label
		>
	</div>
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
	}
	.crop-window img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		transition:
			transform 120ms ease,
			object-position 120ms ease;
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
	.crop-sliders {
		display: grid;
		gap: 5px;
	}
	.crop-sliders label {
		display: grid;
		grid-template-columns: 16px 74px 1fr;
		align-items: center;
		gap: 5px;
	}
	.crop-sliders span {
		color: var(--color-muted);
		font-size: 0.62rem;
	}
	.crop-sliders input {
		width: 100%;
		height: 24px;
		padding: 0;
		accent-color: var(--color-primary);
	}
</style>
