<script lang="ts">
	import { goto, invalidateAll } from '$app/navigation';
	import { AtSign, Bell, CheckCheck, Heart, MessageCircle, UserPlus } from '@lucide/svelte';
	import { onMount } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import { subscribePrivate } from '$lib/realtime/client';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	let items = $derived([...data.items]);
	let busy = $state(false);
	let statusMessage = $state('');
	const unreadCount = $derived(items.filter((item) => !item.read).length);
	const icons = {
		like: Heart,
		comment: MessageCircle,
		reply: MessageCircle,
		follow: UserPlus,
		mention: AtSign,
		story_mention: AtSign
	};

	onMount(() => {
		if (!data.user) return;
		return subscribePrivate(
			`user.${data.user.id}`,
			'notification.created',
			() => void invalidateAll()
		);
	});

	function destination(item: (typeof items)[number]) {
		if (item.postId) return `/posts/${item.postId}`;
		if (item.user) return `/u/${item.user.username}`;
		return '/notifications';
	}

	async function openNotification(event: MouseEvent, item: (typeof items)[number]) {
		event.preventDefault();
		if (!item.read) {
			item.read = true;
			try {
				await clientRequest(`notifications/${item.id}/read`, { method: 'PATCH' });
				window.dispatchEvent(
					new CustomEvent('portal:notifications-read', { detail: { count: unreadCount } })
				);
			} catch {
				item.read = false;
			}
		}
		await goto(destination(item));
	}

	async function markAllRead() {
		if (busy || unreadCount === 0) return;
		busy = true;
		statusMessage = '';
		try {
			await clientRequest('notifications/read/all', { method: 'PATCH' });
			for (const item of items) item.read = true;
			window.dispatchEvent(new CustomEvent('portal:notifications-read', { detail: { count: 0 } }));
			statusMessage = 'Semua notifikasi ditandai dibaca.';
		} catch {
			statusMessage = 'Notifikasi belum dapat diperbarui.';
		} finally {
			busy = false;
		}
	}
</script>

<svelte:head
	><title>Notifikasi — Portal SI</title><meta name="robots" content="noindex" /></svelte:head
>

<SectionPage
	eyebrow="Aktivitas terbaru"
	title="Notifikasi"
	description="Kabar tentang interaksi, teman, dan komunitas Anda."
>
	{#snippet actions()}<button
			class="read-all"
			onclick={markAllRead}
			disabled={busy || unreadCount === 0}><CheckCheck size={17} /> Tandai semua dibaca</button
		>{/snippet}
	<div class="notifications-layout">
		<section class="notification-list surface" aria-labelledby="notification-heading">
			<div class="list-head">
				<h2 id="notification-heading">Terbaru</h2>
				<span>{unreadCount} baru</span>
			</div>
			{#each items as item (item.id)}
				{@const Icon = icons[item.type as keyof typeof icons] || Bell}
				<article class:unread={!item.read}>
					<div class="avatar-wrap">
						{#if item.user}<StoryAvatarLink
								userId={item.user.id}
								username={item.user.username}
								name={item.user.fullName}
								avatarUrl={item.user.avatarUrl ?? undefined}
								size="md"
								hasStory={item.user.hasStory}
								seen={item.user.storyViewed}
							/>{:else}<Avatar name="Portal SI" size="md" />{/if}<i
							><Icon size={12} fill={item.type === 'like' ? 'currentColor' : 'none'} /></i
						>
					</div>
					<a href={destination(item)} onclick={(event) => openNotification(event, item)}
						><p>{item.message}<small>{item.time}</small></p></a
					>
					{#if !item.read}<span class="dot" aria-label="Belum dibaca"></span>{/if}
				</article>
			{/each}
			{#if items.length === 0}<p class="empty">Belum ada notifikasi.</p>{/if}
			<nav class="pagination" aria-label="Halaman notifikasi">
				{#if data.page > 1}<a href={`/notifications?page=${data.page - 1}`}>Sebelumnya</a>{/if}<span
					>Halaman {data.page}</span
				>{#if data.hasNext}<a href={`/notifications?page=${data.page + 1}`}>Berikutnya</a>{/if}
			</nav>
			{#if statusMessage}<p class="status" aria-live="polite">{statusMessage}</p>{/if}
		</section>
		<aside class="notification-aside surface">
			<span><Bell size={22} /></span>
			<h2>Tetap terhubung</h2>
			<p>Notifikasi membantu Anda mengikuti percakapan tanpa perlu memeriksa setiap halaman.</p>
			<a href="/settings">Atur preferensi</a>
		</aside>
	</div>
</SectionPage>

<style>
	.read-all {
		display: flex;
		min-height: 42px;
		align-items: center;
		gap: 7px;
		padding: 0 13px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 11px;
		font-size: 0.78rem;
		font-weight: 680;
	}
	.read-all:disabled {
		opacity: 0.55;
	}
	.notifications-layout {
		display: grid;
		grid-template-columns: minmax(0, 1fr) 280px;
		gap: 18px;
		align-items: start;
	}
	.notification-list {
		overflow: hidden;
	}
	.list-head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 16px;
		border-bottom: 1px solid var(--color-border);
	}
	.list-head h2 {
		margin: 0;
		font-size: 0.92rem;
	}
	.list-head span {
		padding: 4px 8px;
		background: var(--color-primary-soft);
		border-radius: 99px;
		color: var(--color-primary-strong);
		font-size: 0.68rem;
		font-weight: 700;
	}
	.notification-list > article {
		display: grid;
		grid-template-columns: auto 1fr auto;
		align-items: center;
		gap: 12px;
		min-height: 80px;
		padding: 13px 16px;
		border-bottom: 1px solid var(--color-border);
	}
	.notification-list > article:hover {
		background: var(--color-surface-soft);
	}
	.notification-list > article.unread {
		background: #fffaf1;
	}
	.avatar-wrap {
		position: relative;
	}
	.avatar-wrap i {
		position: absolute;
		right: -3px;
		bottom: -2px;
		display: grid;
		width: 21px;
		height: 21px;
		place-items: center;
		background: var(--color-primary);
		border: 2px solid white;
		border-radius: 50%;
		color: white;
	}
	.notification-list p {
		margin: 0;
		font-size: 0.83rem;
	}
	.notification-list article > a {
		display: block;
		min-width: 0;
	}
	.notification-list p small {
		display: block;
		margin-top: 3px;
		color: var(--color-muted);
		font-size: 0.7rem;
	}
	.dot {
		width: 8px;
		height: 8px;
		background: var(--color-primary);
		border-radius: 50%;
	}
	.notification-aside {
		display: grid;
		justify-items: start;
		padding: 20px;
	}
	.notification-aside > span {
		display: grid;
		width: 45px;
		height: 45px;
		place-items: center;
		background: var(--color-secondary-soft);
		border-radius: 14px;
		color: var(--color-secondary);
	}
	.notification-aside h2 {
		margin: 14px 0 5px;
		font-size: 0.98rem;
	}
	.notification-aside p {
		margin: 0;
		color: var(--color-muted);
		font-size: 0.78rem;
	}
	.notification-aside a {
		margin-top: 13px;
		color: var(--color-secondary);
		font-size: 0.76rem;
		font-weight: 720;
	}
	.pagination {
		display: flex;
		justify-content: center;
		gap: 14px;
		padding: 14px;
		color: var(--color-muted);
		font-size: 0.72rem;
	}
	.pagination a {
		color: var(--color-primary-strong);
		font-weight: 700;
	}
	.status,
	.empty {
		margin: 0;
		padding: 14px;
		color: var(--color-muted);
		font-size: 0.75rem;
		text-align: center;
	}
	@media (max-width: 800px) {
		.notifications-layout {
			grid-template-columns: 1fr;
		}
		.notification-aside {
			display: none;
		}
	}
	@media (max-width: 767px) {
		.read-all {
			width: 42px;
			padding: 0;
			justify-content: center;
			font-size: 0;
		}
		.notification-list {
			border-inline: 0;
			border-radius: 0;
		}
	}
</style>
