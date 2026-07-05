<script lang="ts">
	import { ArrowUpRight, Megaphone, Pin } from '@lucide/svelte';
	import { fly } from 'svelte/transition';
	import type { AnnouncementPreview } from '$lib/types/domain';

	let { announcements }: { announcements: AnnouncementPreview[] } = $props();
	let active = $state(0);

	// Auto-geser ke pengumuman berikutnya setiap 5 detik bila lebih dari satu.
	$effect(() => {
		if (announcements.length <= 1) return;
		const timer = setInterval(() => {
			active = (active + 1) % announcements.length;
		}, 5000);
		return () => clearInterval(timer);
	});
	// Jaga index tetap valid bila jumlah pengumuman berubah.
	$effect(() => {
		if (active >= announcements.length) active = 0;
	});
</script>

{#if announcements.length}
	<div class="announcement-carousel">
		{#key active}
			<article class="announcement" in:fly={{ x: 48, duration: 420 }}>
				<div class="icon"><Megaphone size={21} /></div>
				<div class="copy">
					<div class="meta">
						{#if announcements[active].pinned}<Pin size={13} /> Disematkan ·
						{/if}{announcements[active].createdLabel}
					</div>
					<h2>{announcements[active].title}</h2>
					<p>{announcements[active].content}</p>
				</div>
				<a href="/announcements" aria-label="Lihat semua pengumuman"><ArrowUpRight size={20} /></a>
			</article>
		{/key}
		{#if announcements.length > 1}
			<div class="dots" aria-label="Navigasi pengumuman">
				{#each announcements as _, index (index)}
					<button
						type="button"
						class:active={index === active}
						onclick={() => (active = index)}
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
		overflow: hidden;
	}
	.announcement {
		min-width: 0;
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
