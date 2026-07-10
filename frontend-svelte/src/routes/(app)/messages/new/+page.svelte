<script lang="ts">
	import { env } from '$env/dynamic/public';
	import { ArrowLeft, LoaderCircle, Search } from '@lucide/svelte';
	import { untrack } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import { mapCompactUser } from '$lib/api/mappers';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import UserBadges from '$lib/components/ui/UserBadges.svelte';
	import { userSearchResponseSchema } from '$lib/schemas/post';
	import type { PageProps } from './$types';
	import type { PortalUser } from '$lib/types/domain';

	let { data }: PageProps = $props();
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	let users = $state<PortalUser[]>(untrack(() => [...data.users]));
	let query = $state('');
	let searching = $state(false);
	let message = $state('');

	$effect(() => {
		const value = query.trim();
		if (value.length < 2) {
			users = [...data.users];
			searching = false;
			message = '';
			return;
		}
		searching = true;
		message = '';
		const controller = new AbortController();
		const timer = window.setTimeout(async () => {
			try {
				const encoded = encodeURIComponent(value);
				const response = await clientRequest(
					`users/search?username=${encoded}&full_name=${encoded}&per_page=30`,
					{ schema: userSearchResponseSchema, signal: controller.signal }
				);
				users = response.data.map((user) => mapCompactUser(user, mediaBaseUrl));
				if (!users.length) message = 'Tidak ada pengguna yang cocok.';
			} catch (error) {
				if (!(error instanceof DOMException && error.name === 'AbortError')) {
					users = [];
					message = 'Pencarian pengguna belum dapat dimuat.';
				}
			} finally {
				if (!controller.signal.aborted) searching = false;
			}
		}, 280);
		return () => {
			window.clearTimeout(timer);
			controller.abort();
		};
	});
</script>

<svelte:head
	><title>Pesan baru — Portal SI</title><meta name="robots" content="noindex" /></svelte:head
>

<main class="new-message surface">
	<header>
		<a href="/messages" aria-label="Kembali"><ArrowLeft size={20} /></a>
		<h1>Pesan baru</h1>
	</header>
	<form class="search" onsubmit={(event) => event.preventDefault()}>
		<label
			><Search size={18} /><span class="sr-only">Cari pengguna</span><input
				bind:value={query}
				maxlength="80"
				placeholder="Cari nama atau username"
			/>{#if searching}<LoaderCircle class="spin" size={17} />{/if}</label
		>
	</form>
	<section>
		<h2>{query ? 'Hasil pencarian' : 'Teman bersama'}</h2>
		{#each users as user (user.id)}<div class="user-row">
				<StoryAvatarLink
					userId={user.id}
					username={user.username}
					name={user.fullName}
					avatarUrl={user.avatarUrl}
					size="md"
					hasStory={user.hasStory}
					seen={user.storyViewed}
				/>
				<a
					href={`/messages/direct/${user.id}?name=${encodeURIComponent(user.fullName)}&username=${encodeURIComponent(user.username)}${user.avatarUrl ? `&avatar=${encodeURIComponent(user.avatarUrl)}` : ''}`}
				>
					<strong
						>{user.fullName}<UserBadges verified={user.badgeVerified} role={user.role} /></strong
					><small>@{user.username}</small>
				</a>
			</div>{/each}
		{#if message}<p aria-live="polite">{message}</p>{:else if users.length === 0}<p>
				{query.trim()
					? 'Tidak ada pengguna yang cocok.'
					: 'Cari nama atau username untuk memulai percakapan pertama.'}
			</p>{/if}
	</section>
</main>

<style>
	.new-message {
		width: min(100% - 32px, 560px);
		min-height: 600px;
		margin: 28px auto;
		overflow: hidden;
	}
	.new-message header {
		display: flex;
		min-height: 64px;
		align-items: center;
		gap: 12px;
		padding: 0 15px;
		border-bottom: 1px solid var(--color-border);
	}
	header a {
		display: grid;
		width: 40px;
		height: 40px;
		place-items: center;
		border-radius: 50%;
	}
	h1 {
		margin: 0;
		font-size: 1rem;
	}
	.search {
		display: flex;
		gap: 8px;
		margin: 15px;
	}
	.search label {
		display: flex;
		min-width: 0;
		height: 45px;
		flex: 1;
		align-items: center;
		gap: 8px;
		padding: 0 12px;
		background: var(--color-canvas);
		border: 1px solid var(--color-border);
		border-radius: 12px;
		color: var(--color-muted);
	}
	.search input {
		min-width: 0;
		flex: 1;
		background: transparent;
		border: 0;
		outline: 0;
	}
	:global(.spin) {
		color: var(--color-primary);
		animation: spin 0.8s linear infinite;
	}
	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}
	section h2 {
		margin: 20px 15px 8px;
		font-size: 0.8rem;
	}
	.user-row {
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 11px 15px;
		border-top: 1px solid var(--color-border);
	}
	.user-row:hover {
		background: var(--color-surface-soft);
	}
	.user-row > a {
		display: grid;
		min-width: 0;
		flex: 1;
	}
	section strong {
		font-size: 0.83rem;
	}
	section small,
	section > p {
		color: var(--color-muted);
		font-size: 0.7rem;
	}
	section > p {
		padding: 20px 15px;
		text-align: center;
	}
	@media (max-width: 767px) {
		.new-message {
			width: 100%;
			min-height: calc(100vh - 132px);
			margin: 0;
			border: 0;
			border-radius: 0;
		}
	}
</style>
