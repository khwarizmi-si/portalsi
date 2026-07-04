<script lang="ts">
	import { ArrowUpRight, Megaphone, Pin } from '@lucide/svelte';
	import type { AnnouncementPreview } from '$lib/types/domain';
	let { announcement }: { announcement: AnnouncementPreview } = $props();
</script>

<article class="announcement">
	<div class="icon"><Megaphone size={21} /></div>
	<div class="copy">
		<div class="meta">
			{#if announcement.pinned}<Pin size={13} /> Disematkan ·
			{/if}{announcement.createdLabel}
		</div>
		<h2>{announcement.title}</h2>
		<p>{announcement.content}</p>
	</div>
	<a href="/announcements" aria-label="Lihat semua pengumuman"><ArrowUpRight size={20} /></a>
</article>

<style>
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
</style>
