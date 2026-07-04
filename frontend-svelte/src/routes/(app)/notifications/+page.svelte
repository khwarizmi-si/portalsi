<script lang="ts">
	import { env } from '$env/dynamic/public';
	import { goto, invalidateAll } from '$app/navigation';
	import {
		AtSign,
		Bell,
		Check,
		CheckCheck,
		Heart,
		MessageCircle,
		UserPlus,
		X
	} from '@lucide/svelte';
	import { onMount, untrack } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import { subscribePrivate } from '$lib/realtime/client';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import UserBadges from '$lib/components/ui/UserBadges.svelte';
	import InfiniteScrollTrigger from '$lib/components/ui/InfiniteScrollTrigger.svelte';
	import { notificationsResponseSchema } from '$lib/schemas/notification';
	import { normalizeMediaUrl } from '$lib/utils/media';
	import { relativeTimeId } from '$lib/utils/time';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	let items = $state(untrack(() => [...data.items]));
	let busy = $state(false);
	let statusMessage = $state('');
	let requests = $state(untrack(() => [...data.requests]));
	let nextPage = $state(untrack(() => data.page + 1));
	let hasMore = $state(untrack(() => data.hasNext));
	let loadingMore = $state(false);
	const unreadCount = $derived(items.filter((item) => !item.read).length);
	const icons = {
		like: Heart,
		comment: MessageCircle,
		reply: MessageCircle,
		follow: UserPlus,
		follow_accepted: UserPlus,
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
	async function decideRequest(id: number, accept: boolean) {
		try {
			await clientRequest(`followers/${id}/${accept ? 'accept' : 'reject'}`, { method: 'POST' });
			requests = requests.filter((item) => item.id !== id);
			statusMessage = accept ? 'Permintaan pengikut diterima.' : 'Permintaan pengikut ditolak.';
		} catch {
			statusMessage = 'Permintaan pengikut belum dapat diproses.';
		}
	}
	async function loadMore() {
		if (!hasMore || loadingMore) return;
		loadingMore = true;
		try {
			const response = await clientRequest(`notifications?page=${nextPage}&per_page=15`, {
				schema: notificationsResponseSchema
			});
			const known = new Set(items.map((item) => item.id));
			items.push(
				...response.notifications
					.filter((item) => !known.has(item.notification_id))
					.map((item) => ({
						id: item.notification_id,
						type: item.type,
						message: item.message,
						read: item.is_read,
						time: relativeTimeId(item.created_at),
						postId: item.related_post_id,
						user: item.sender
							? {
									id: item.sender.user_id,
									username: item.sender.username,
									fullName: item.sender.full_name?.trim() || item.sender.username,
									avatarUrl: normalizeMediaUrl(item.sender.profile_picture_url, mediaBaseUrl),
									role: item.sender.role,
									badgeVerified: item.sender.is_verified,
									hasStory: false,
									storyViewed: false
								}
							: null
					}))
			);
			nextPage = response.pagination.current_page + 1;
			hasMore = response.pagination.current_page < response.pagination.last_page;
		} catch {
			statusMessage = 'Notifikasi berikutnya belum dapat dimuat.';
		} finally {
			loadingMore = false;
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
			{#if requests.length}<div class="follow-requests">
					<h2><UserPlus size={17} /> Permintaan pengikut <span>{requests.length}</span></h2>
					{#each requests as user (user.id)}<article>
							<Avatar name={user.fullName} src={user.avatarUrl ?? undefined} size="md" /><a
								href={`/u/${user.username}`}
								><strong
									>{user.fullName}<UserBadges
										verified={user.badgeVerified}
										role={user.role}
									/></strong
								><small>@{user.username}</small></a
							><button
								onclick={() => decideRequest(user.id, true)}
								aria-label={`Terima ${user.fullName}`}><Check size={16} /></button
							><button
								class="reject"
								onclick={() => decideRequest(user.id, false)}
								aria-label={`Tolak ${user.fullName}`}><X size={16} /></button
							>
						</article>{/each}
				</div>{/if}
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
						><p>
							{item.message}{#if item.user}<UserBadges
									verified={item.user.badgeVerified}
									role={item.user.role}
								/>{/if}<small>{item.time}</small>
						</p></a
					>
					{#if !item.read}<span class="dot" aria-label="Belum dibaca"></span>{/if}
				</article>
			{/each}
			{#if items.length === 0}<p class="empty">Belum ada notifikasi.</p>{/if}
			<InfiniteScrollTrigger
				{hasMore}
				loading={loadingMore}
				onLoad={loadMore}
				label="Memuat notifikasi berikutnya…"
			/>
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
	.follow-requests {
		background: linear-gradient(135deg, #f5fbff, #fffaf2);
		border-bottom: 1px solid var(--color-border);
	}
	.follow-requests > h2 {
		display: flex;
		align-items: center;
		gap: 7px;
		margin: 0;
		padding: 13px 16px 7px;
		font-size: 0.78rem;
	}
	.follow-requests > h2 span {
		display: grid;
		min-width: 20px;
		height: 20px;
		margin-left: auto;
		place-items: center;
		background: #1687e8;
		border-radius: 99px;
		color: white;
		font-size: 0.62rem;
	}
	.follow-requests article {
		display: grid;
		grid-template-columns: auto 1fr auto auto;
		align-items: center;
		gap: 9px;
		padding: 9px 16px 13px;
	}
	.follow-requests article > a {
		display: grid;
	}
	.follow-requests article strong {
		font-size: 0.78rem;
	}
	.follow-requests article small {
		color: var(--color-muted);
		font-size: 0.68rem;
	}
	.follow-requests article button {
		display: grid;
		width: 36px;
		height: 36px;
		padding: 0;
		place-items: center;
		background: #1687e8;
		border: 0;
		border-radius: 10px;
		color: white;
	}
	.follow-requests article button.reject {
		background: var(--color-danger-soft);
		color: var(--color-danger);
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
	.notification-list article > a p :global(.user-badges) {
		margin-left: 5px;
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
