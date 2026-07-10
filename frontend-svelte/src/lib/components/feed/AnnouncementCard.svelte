<script lang="ts">
	import { ArrowUpRight, Megaphone, Pin } from '@lucide/svelte';
	import type { AnnouncementPreview } from '$lib/types/domain';

	let { announcements }: { announcements: AnnouncementPreview[] } = $props();
	let active = $state(0);
	let holding = $state(false);
	let trackEl = $state<HTMLDivElement>();

	function scrollToIndex(index: number, behavior: ScrollBehavior = 'smooth') {
		if (!trackEl) return;
		const clamped = ((index % announcements.length) + announcements.length) % announcements.length;
		trackEl.scrollTo({ left: clamped * trackEl.clientWidth, behavior });
	}

	function onScroll() {
		if (!trackEl) return;
		active = Math.round(trackEl.scrollLeft / (trackEl.clientWidth || 1));
	}

	// Auto-geser tiap 5 detik — dijeda selama user menahan/menggeser agar tidak membingungkan.
	$effect(() => {
		if (announcements.length <= 1) return;
		const timer = setInterval(() => {
			if (holding) return;
			scrollToIndex(active + 1);
		}, 5000);
		return () => clearInterval(timer);
	});

	$effect(() => {
		if (active >= announcements.length) active = 0;
	});
</script>

{#if announcements.length}
	<div class="announcement-carousel">
		<div
			class="track"
			role="region"
			aria-label="Slider pengumuman"
			bind:this={trackEl}
			onscroll={onScroll}
			onpointerdown={() => (holding = true)}
			onpointerup={() => (holding = false)}
			onpointercancel={() => (holding = false)}
			onpointerleave={() => (holding = false)}
		>
			{#each announcements as item (item.id)}
				<article class="announcement">
					<div class="icon"><Megaphone size={21} /></div>
					<div class="copy">
						<div class="meta">
							{#if item.pinned}<Pin size={13} /> Disematkan · {/if}{item.createdLabel}
						</div>
						<h2>{item.title}</h2>
						<p>{item.content}</p>
					</div>
					<a href="/announcements" aria-label="Lihat semua pengumuman"><ArrowUpRight size={20} /></a>
				</article>
			{/each}
		</div>
		{#if announcements.length > 1}
			<div class="dots" aria-label="Navigasi pengumuman">
				{#each announcements as _, index (index)}
					<button
						type="button"
						class:active={index === active}
						onclick={() => scrollToIndex(index)}
						aria-label={`Pengumuman ${index + 1} dari ${announcements.length}`}
					></button>
				{/each}
			</div>
		{/if}
	</div>
{/if}

<style>
	.announcement-carousel {
		position: relative;
		min-width: 0;
	}
	.track {
		display: flex;
		overflow-x: auto;
		scroll-snap-type: x mandatory;
		scrollbar-width: none;
		border-radius: var(--radius-lg);
		-webkit-overflow-scrolling: touch;
		overscroll-behavior-x: contain;
		touch-action: pan-x;
	}
	.track::-webkit-scrollbar {
		display: none;
	}
	.announcement {
		flex: 0 0 100%;
		min-width: 0;
		scroll-snap-align: center;
		scroll-snap-stop: always;
		display: grid;
		grid-template-columns: auto 1fr auto;
		align-items: start;
		gap: 13px;
		padding: 15px;
		background: linear-gradient(125deg, #fff8e8, #fffdf8 70%);
		border: 1px solid #efdcb8;
		border-radius: var(--radius-lg);
	}

	.icon {
		display: grid;
		width: 40px;
		height: 40px;
		place-items: center;
		background: #ffe8b9;
		border-radius: 12px;
		color: #9a4c00;
	}

	.copy {
		min-width: 0;
	}

	.meta {
		display: flex;
		align-items: center;
		margin-bottom: 3px;
		color: #8b5d26;
		font-size: 0.72rem;
		font-weight: 680;
	}

	h2 {
		margin: 0 0 3px;
		font-size: 0.98rem;
	}

	p {
		display: -webkit-box;
		margin: 0;
		overflow: hidden;
		-webkit-box-orient: vertical;
		-webkit-line-clamp: 2;
		line-clamp: 2;
		color: var(--color-muted);
		font-size: 0.86rem;
		line-height: 1.45;
	}

	article > a {
		display: grid;
		width: 38px;
		height: 38px;
		place-items: center;
		border-radius: 50%;
		color: #8b5d26;
	}

	article > a:hover {
		background: #ffe8b9;
	}

	.dots {
		position: absolute;
		right: 14px;
		bottom: 10px;
		display: flex;
		gap: 5px;
	}
	.dots button {
		width: 7px;
		height: 7px;
		padding: 0;
		background: #e2c793;
		border: 0;
		border-radius: 50%;
		cursor: pointer;
		transition: all 200ms ease;
	}
	.dots button.active {
		width: 18px;
		background: #9a4c00;
		border-radius: 99px;
	}
</style>
