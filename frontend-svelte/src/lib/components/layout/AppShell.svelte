<script lang="ts">
	import type { Snippet } from 'svelte';
	import { page } from '$app/state';
	import { onMount } from 'svelte';
	import {
		Bell,
		Bookmark,
		Compass,
		Home,
		MessageCircle,
		Plus,
		Search,
		Settings,
		ShoppingBag,
		UserRound
	} from '@lucide/svelte';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import BackButton from '$lib/components/ui/BackButton.svelte';
	import { clientRequest } from '$lib/api/client';
	import { notificationsResponseSchema } from '$lib/schemas/notification';
	import type { SessionUser } from '$lib/schemas/user';

	let { children, user }: { children: Snippet; user: SessionUser } = $props();
	let unreadCount = $state(0);
	const topLevel = new Set([
		'/home',
		'/explore',
		'/messages',
		'/notifications',
		'/store',
		'/profile',
		'/settings'
	]);
	const hasOwnBack = $derived(
		/^\/(create\/|messages\/(direct|groups|new)|stories\/|groups\/)/.test(page.url.pathname)
	);
	const showBack = $derived(!topLevel.has(page.url.pathname) && !hasOwnBack);

	onMount(() => {
		const updateUnread = (event: Event) => {
			const detail = (event as CustomEvent<{ count: number }>).detail;
			unreadCount = Math.max(0, detail.count);
		};
		window.addEventListener('portal:notifications-read', updateUnread);
		void clientRequest('notifications?page=1&per_page=50', {
			schema: notificationsResponseSchema
		})
			.then((response) => {
				unreadCount = response.notifications.filter((item) => !item.is_read).length;
			})
			.catch(() => undefined);
		return () => window.removeEventListener('portal:notifications-read', updateUnread);
	});

	const primary = [
		{ href: '/home', label: 'Beranda', icon: Home },
		{ href: '/explore', label: 'Jelajah', icon: Compass },
		{ href: '/messages', label: 'Pesan', icon: MessageCircle },
		{ href: '/notifications', label: 'Notifikasi', icon: Bell },
		{ href: '/store', label: 'Store', icon: ShoppingBag },
		{ href: '/profile', label: 'Profil', icon: UserRound }
	];

	const mobile = [
		{ href: '/home', label: 'Beranda', icon: Home },
		{ href: '/explore', label: 'Jelajah', icon: Compass },
		{ href: '/create/post', label: 'Buat', icon: Plus, create: true },
		{ href: '/store', label: 'Store', icon: ShoppingBag },
		{ href: '/profile', label: 'Profil', icon: UserRound }
	];

	function active(href: string) {
		return page.url.pathname === href || page.url.pathname.startsWith(`${href}/`);
	}
</script>

<div class="app-shell">
	<aside class="sidebar" aria-label="Navigasi utama">
		<a class="brand" href="/home" aria-label="Portal SI — Beranda">
			<img src="/assets/logo-mark.png" alt="" />
			<span>Portal <b>SI</b></span>
		</a>

		<nav class="side-nav">
			{#each primary as item (item.href)}
				<a
					href={item.href}
					class:active={active(item.href)}
					aria-current={active(item.href) ? 'page' : undefined}
				>
					<item.icon size={21} strokeWidth={active(item.href) ? 2.5 : 2} />
					<span>{item.label}</span>
					{#if item.label === 'Notifikasi' && unreadCount > 0}<i
							aria-label={`${unreadCount} notifikasi belum dibaca`}
							>{unreadCount > 99 ? '99+' : unreadCount}</i
						>{/if}
				</a>
			{/each}
		</nav>

		<a class="create-button" href="/create/post">
			<Plus size={20} strokeWidth={2.5} />
			<span>Buat konten</span>
		</a>

		<div class="side-spacer"></div>
		<a class="saved-link" href="/settings/saved"><Bookmark size={19} /> Tersimpan</a>
		<a class="profile-switch" href="/settings">
			<Avatar name={user.fullName} src={user.avatarUrl ?? undefined} size="sm" />
			<span><strong>{user.fullName}</strong><small>@{user.username}</small></span>
			<Settings size={17} class="settings-icon" />
		</a>
	</aside>

	<header class="mobile-header">
		<a class="mobile-brand" href="/home"
			><img src="/assets/logo-mark.png" alt="" /><b>Portal SI</b></a
		>
		<div>
			<a href="/explore" aria-label="Cari"><Search size={21} /></a>
			<a href="/notifications" aria-label="Notifikasi" class:has-dot={unreadCount > 0}
				><Bell size={21} /></a
			>
			<a href="/messages" aria-label="Pesan"><MessageCircle size={21} /></a>
		</div>
	</header>

	<main class="app-main" id="main-content">
		{#if showBack}<div class="page-back"><BackButton /></div>{/if}
		{@render children()}
	</main>

	<nav class="bottom-nav" aria-label="Navigasi utama seluler">
		{#each mobile as item (item.href)}
			<a
				href={item.href}
				class:active={active(item.href)}
				class:create={item.create}
				aria-current={active(item.href) ? 'page' : undefined}
			>
				<span><item.icon size={item.create ? 24 : 21} strokeWidth={item.create ? 2.8 : 2.2} /></span
				>
				<small>{item.label}</small>
			</a>
		{/each}
	</nav>
</div>

<style>
	.app-shell {
		min-height: 100vh;
	}

	.sidebar {
		position: fixed;
		z-index: var(--z-nav);
		top: 0;
		bottom: 0;
		left: 0;
		display: none;
		width: var(--sidebar-width);
		padding: 24px 18px 18px;
		background: rgb(255 253 248 / 90%);
		border-right: 1px solid var(--color-border);
		backdrop-filter: blur(18px);
	}

	.brand,
	.mobile-brand {
		display: flex;
		align-items: center;
		gap: 10px;
		font-size: 1.25rem;
		font-weight: 720;
		letter-spacing: -0.03em;
	}

	.brand img,
	.mobile-brand img {
		width: 34px;
		height: 34px;
		border-radius: 10px;
	}

	.brand b {
		color: var(--color-primary);
	}

	.side-nav {
		display: grid;
		gap: 5px;
		margin-top: 34px;
	}

	.side-nav a,
	.saved-link {
		display: flex;
		min-height: 46px;
		align-items: center;
		gap: 13px;
		padding: 0 13px;
		border-radius: 12px;
		color: var(--color-muted);
		font-weight: 600;
	}

	.side-nav a:hover,
	.saved-link:hover {
		background: var(--color-surface);
		color: var(--color-text);
	}

	.side-nav a.active {
		background: var(--color-primary-soft);
		color: var(--color-primary-strong);
	}

	.side-nav i {
		display: grid;
		min-width: 20px;
		height: 20px;
		margin-left: auto;
		place-items: center;
		background: var(--color-primary);
		border-radius: 50%;
		color: white;
		font-size: 0.68rem;
		font-style: normal;
		font-weight: 800;
	}

	.create-button {
		display: flex;
		min-height: 48px;
		align-items: center;
		justify-content: center;
		gap: 9px;
		margin-top: 20px;
		background: var(--color-primary);
		border-radius: 13px;
		box-shadow: 0 8px 20px rgb(232 117 11 / 20%);
		color: white;
		font-weight: 730;
	}

	.create-button:hover {
		background: var(--color-primary-strong);
		transform: translateY(-1px);
	}

	.side-spacer {
		min-height: 30px;
		flex: 1;
	}

	.sidebar {
		flex-direction: column;
	}

	.profile-switch {
		display: flex;
		align-items: center;
		gap: 9px;
		margin-top: 12px;
		padding: 10px;
		border: 1px solid var(--color-border);
		border-radius: var(--radius-md);
		background: var(--color-surface);
	}

	.profile-switch > span:nth-child(2) {
		display: grid;
		min-width: 0;
		margin-right: auto;
	}

	.profile-switch strong,
	.profile-switch small {
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.profile-switch strong {
		font-size: 0.82rem;
	}

	.profile-switch small {
		color: var(--color-muted);
		font-size: 0.72rem;
	}

	.mobile-header {
		position: sticky;
		z-index: var(--z-nav);
		top: 0;
		display: flex;
		height: var(--topbar-height);
		align-items: center;
		justify-content: space-between;
		padding: 0 16px;
		background: rgb(255 253 248 / 92%);
		border-bottom: 1px solid rgb(235 229 218 / 80%);
		backdrop-filter: blur(18px);
	}

	.mobile-brand {
		font-size: 1.02rem;
	}

	.mobile-brand img {
		width: 31px;
		height: 31px;
	}

	.mobile-header > div {
		display: flex;
		gap: 4px;
	}

	.mobile-header > div a {
		position: relative;
		display: grid;
		width: 42px;
		height: 42px;
		place-items: center;
		border-radius: 50%;
	}

	.mobile-header > div a:hover {
		background: var(--color-primary-soft);
	}

	.has-dot::after {
		position: absolute;
		top: 9px;
		right: 9px;
		width: 7px;
		height: 7px;
		background: var(--color-danger);
		border: 2px solid var(--color-surface);
		border-radius: 50%;
		content: '';
	}

	.app-main {
		min-width: 0;
		padding-bottom: calc(var(--bottom-nav-height) + var(--safe-bottom) + 16px);
	}
	.page-back {
		position: relative;
		z-index: 20;
		width: min(100% - 32px, 1080px);
		height: 0;
		margin: 0 auto;
		transform: translateY(14px);
	}
	.page-back :global(button) {
		position: absolute;
		left: 0;
	}
	.page-back + :global(.section-page) {
		padding-top: 72px;
	}

	.bottom-nav {
		position: fixed;
		z-index: var(--z-nav);
		bottom: 0;
		left: 0;
		display: grid;
		width: 100%;
		height: calc(var(--bottom-nav-height) + var(--safe-bottom));
		grid-template-columns: repeat(5, 1fr);
		padding: 7px 8px var(--safe-bottom);
		background: rgb(255 255 255 / 95%);
		border-top: 1px solid var(--color-border);
		box-shadow: 0 -8px 28px rgb(59 42 22 / 7%);
		backdrop-filter: blur(18px);
	}

	.bottom-nav a {
		display: grid;
		place-items: center;
		color: var(--color-muted);
	}

	.bottom-nav a > span {
		display: grid;
		width: 38px;
		height: 32px;
		place-items: center;
		border-radius: 12px;
	}

	.bottom-nav a small {
		font-size: 0.64rem;
		font-weight: 650;
	}

	.bottom-nav a.active {
		color: var(--color-primary-strong);
	}

	.bottom-nav a.active > span {
		background: var(--color-primary-soft);
	}

	.bottom-nav a.create > span {
		width: 45px;
		height: 38px;
		margin-top: -14px;
		background: var(--color-primary);
		box-shadow: 0 8px 18px rgb(232 117 11 / 28%);
		color: white;
	}

	@media (min-width: 768px) {
		.sidebar {
			display: flex;
			width: 88px;
			padding-inline: 12px;
		}

		.brand {
			justify-content: center;
		}

		.brand span,
		.side-nav span,
		.create-button span,
		.saved-link:not(svg),
		.profile-switch > span:nth-child(2),
		:global(.settings-icon) {
			display: none;
		}

		.side-nav a,
		.saved-link {
			justify-content: center;
			padding: 0;
		}

		.side-nav i {
			position: absolute;
			margin: -24px -24px 0 0;
		}

		.create-button {
			width: 48px;
			height: 48px;
			margin-inline: auto;
		}

		.profile-switch {
			justify-content: center;
			padding: 8px;
		}

		.mobile-header,
		.bottom-nav {
			display: none;
		}

		.app-main {
			margin-left: 88px;
			padding-bottom: 40px;
		}
	}

	@media (min-width: 1200px) {
		.sidebar {
			width: var(--sidebar-width);
			padding-inline: 18px;
		}

		.brand {
			justify-content: flex-start;
		}

		.brand span,
		.side-nav span,
		.create-button span,
		.profile-switch > span:nth-child(2),
		:global(.settings-icon) {
			display: initial;
		}

		.side-nav a,
		.saved-link {
			justify-content: flex-start;
			padding-inline: 13px;
		}

		.side-nav i {
			position: static;
			margin: 0 0 0 auto;
		}

		.create-button {
			width: auto;
			margin-inline: 0;
		}

		.profile-switch {
			justify-content: flex-start;
		}

		.app-main {
			margin-left: var(--sidebar-width);
		}
	}
</style>
