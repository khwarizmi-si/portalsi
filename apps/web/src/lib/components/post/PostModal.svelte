<script lang="ts">
	import { X } from '@lucide/svelte';
	import { fade, fly } from 'svelte/transition';
	import { cubicOut } from 'svelte/easing';
	import PostDetailView from '$lib/components/post/PostDetailView.svelte';
	import type { PageData } from '../../../routes/(app)/posts/[postId]/$types';

	type PrivatePostData = Extract<PageData, { isPublic: false }>;
	let { data, onClose }: { data: PrivatePostData; onClose: () => void } = $props();

	let scrollEl = $state<HTMLDivElement>();
	let dragging = $state(false);
	let dragY = $state(0);
	let startY = 0;

	// Cegah scroll latar & kembalikan saat modal ditutup.
	$effect(() => {
		const previous = document.body.style.overflow;
		document.body.style.overflow = 'hidden';
		return () => {
			document.body.style.overflow = previous;
		};
	});

	// Swipe-down untuk menutup (mobile) — hanya saat konten sudah di paling atas.
	function onPointerDown(event: PointerEvent) {
		if (event.pointerType === 'mouse') return;
		if (!scrollEl || scrollEl.scrollTop > 0) return;
		startY = event.clientY;
		dragging = true;
	}
	function onPointerMove(event: PointerEvent) {
		if (!dragging) return;
		dragY = Math.max(0, event.clientY - startY);
	}
	function onPointerUp() {
		if (!dragging) return;
		dragging = false;
		if (dragY > 120) onClose();
		dragY = 0;
	}
</script>

<svelte:window
	onkeydown={(event) => {
		if (event.key === 'Escape') onClose();
	}}
/>

<div class="pm-overlay" transition:fade={{ duration: 180 }} onclick={onClose} role="presentation"></div>

<div class="pm-viewport">
	<div
		class="pm-panel"
		in:fly={{ y: 30, duration: 240, easing: cubicOut }}
		out:fly={{ y: 20, duration: 160, easing: cubicOut }}
		style:transform={dragY ? `translateY(${dragY}px)` : undefined}
		style:transition={dragging ? 'none' : 'transform 220ms cubic-bezier(0.2,0.9,0.3,1)'}
		role="dialog"
		aria-modal="true"
		aria-label="Detail postingan"
	>
		<div class="pm-grabber" aria-hidden="true"><span></span></div>
		<div
			class="pm-scroll"
			bind:this={scrollEl}
			onpointerdown={onPointerDown}
			onpointermove={onPointerMove}
			onpointerup={onPointerUp}
			onpointercancel={onPointerUp}
		>
			<PostDetailView {data} />
		</div>
	</div>
</div>

<!-- Tombol tutup di luar panel (panel ber-transform), agar 'fixed' relatif ke layar, tidak terpotong. -->
<button class="pm-close" onclick={onClose} aria-label="Tutup"><X size={20} /></button>

<style>
	.pm-overlay {
		position: fixed;
		inset: 0;
		z-index: 1400;
		background: rgb(18 13 8 / 55%);
		backdrop-filter: blur(3px);
	}
	.pm-viewport {
		position: fixed;
		inset: 0;
		z-index: 1401;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 20px;
		pointer-events: none;
	}
	.pm-panel {
		position: relative;
		display: flex;
		width: min(1120px, calc(100% - 40px));
		max-height: 92vh;
		flex-direction: column;
		overflow: hidden;
		background: var(--color-canvas, #fbf7ef);
		border: 1px solid var(--color-border);
		border-radius: 20px;
		box-shadow: 0 30px 80px rgb(0 0 0 / 34%);
		pointer-events: auto;
		will-change: transform;
	}
	.pm-grabber {
		display: none;
	}
	.pm-close {
		position: fixed;
		z-index: 1402;
		top: calc(12px + env(safe-area-inset-top, 0px));
		right: 14px;
		display: grid;
		width: 40px;
		height: 40px;
		place-items: center;
		background: rgb(0 0 0 / 55%);
		border: 0;
		border-radius: 50%;
		color: white;
		backdrop-filter: blur(6px);
	}
	.pm-scroll {
		flex: 1;
		overflow-y: auto;
		padding: 22px 24px 12px;
		-webkit-overflow-scrolling: touch;
	}
	.pm-scroll :global(.post-detail-layout) {
		margin: 0;
	}
	/* Tampilan bersih ala Instagram di dalam modal: kartu tanpa bingkai, media di latar gelap. */
	.pm-scroll :global(.post-card) {
		border: 0;
		box-shadow: none;
		background: transparent;
	}
	.pm-scroll :global(.post-card .media) {
		background: #0b0c0d;
		border-radius: 14px;
	}
	/* Beri ruang lebih lega untuk dua kolom (post + komentar) di dalam modal lebar. */
	@media (min-width: 951px) {
		.pm-scroll :global(.post-detail-layout) {
			grid-template-columns: minmax(0, 1.15fr) minmax(0, 0.85fr);
			gap: 24px;
		}
	}
	@media (max-width: 720px) {
		.pm-scroll {
			padding: 8px 14px 8px;
		}
	}

	@media (max-width: 720px) {
		.pm-viewport {
			align-items: flex-end;
			padding: 0;
		}
		.pm-panel {
			width: 100%;
			max-height: 94vh;
			border-radius: 20px 20px 0 0;
			touch-action: pan-y;
		}
		.pm-grabber {
			display: grid;
			place-items: center;
			padding: 8px 0 4px;
		}
		.pm-grabber span {
			width: 40px;
			height: 4px;
			border-radius: 999px;
			background: var(--color-border);
		}
	}
</style>
