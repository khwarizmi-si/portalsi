<script lang="ts">
	import { env } from '$env/dynamic/public';
	import { LoaderCircle, Search, SlidersHorizontal } from '@lucide/svelte';
	import { clientRequest } from '$lib/api/client';
	import { mapCompactUser, mapPost } from '$lib/api/mappers';
	import AnnouncementCard from '$lib/components/feed/AnnouncementCard.svelte';
	import PostCard from '$lib/components/feed/PostCard.svelte';
	import StoryRail from '$lib/components/feed/StoryRail.svelte';
	import RightRail from '$lib/components/layout/RightRail.svelte';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import { feedResponseSchema, userSearchResponseSchema } from '$lib/schemas/post';
	import { untrack } from 'svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const firstName = $derived(data.user.fullName.split(' ')[0]);
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	let posts = $state(untrack(() => [...data.posts]));
	let nextPage = $state(2);
	let hasMore = $state(untrack(() => data.hasMore));
	let loadingMore = $state(false);
	let loadMoreError = $state('');
	let homeQuery = $state('');
	let searchResults = $state<typeof data.suggestions>([]);
	let searching = $state(false);

	$effect(() => {
		const query = homeQuery.trim();
		if (query.length < 2) {
			searchResults = [];
			searching = false;
			return;
		}
		searching = true;
		const controller = new AbortController();
		const timer = window.setTimeout(async () => {
			try {
				const encoded = encodeURIComponent(query);
				const response = await clientRequest(
					`users/search?username=${encoded}&full_name=${encoded}&per_page=6`,
					{ schema: userSearchResponseSchema, signal: controller.signal }
				);
				const storyStatus = new Map(data.stories.map((item) => [item.user.id, item.user]));
				searchResults = response.data.map((user) => ({
					...mapCompactUser(user, mediaBaseUrl),
					...(storyStatus.get(user.user_id)
						? { hasStory: true, storyViewed: storyStatus.get(user.user_id)?.storyViewed }
						: {})
				}));
			} catch (error) {
				if (!(error instanceof DOMException && error.name === 'AbortError')) searchResults = [];
			} finally {
				if (!controller.signal.aborted) searching = false;
			}
		}, 280);
		return () => {
			window.clearTimeout(timer);
			controller.abort();
		};
	});

	async function loadMore() {
		if (loadingMore || !hasMore) return;
		loadingMore = true;
		loadMoreError = '';
		try {
			const response = await clientRequest(`posts?page=${nextPage}`, {
				schema: feedResponseSchema
			});
			const incoming = response.feed
				.filter((item) => item.type === 'post')
				.map((post) => mapPost(post, mediaBaseUrl));
			const existingIds = new Set(posts.map((post) => post.id));
			posts.push(...incoming.filter((post) => !existingIds.has(post.id)));
			hasMore = response.current_page * response.per_page < response.total;
			nextPage = response.current_page + 1;
		} catch {
			loadMoreError = 'Postingan berikutnya belum dapat dimuat.';
		} finally {
			loadingMore = false;
		}
	}
</script>

<svelte:head>
	<title>Beranda — Portal SI</title>
	<meta name="robots" content="noindex" />
</svelte:head>

<div class="home-layout">
	<section class="feed-column" aria-label="Beranda">
		<header class="desktop-feed-header">
			<div>
				<p class="eyebrow">{data.dateLabel}</p>
				<h1>Assalamu’alaikum, {firstName}</h1>
			</div>
			<div class="search-wrap">
				<div class="search-box">
					<Search size={18} />
					<label class="sr-only" for="home-search">Cari di Portal SI</label>
					<input
						id="home-search"
						bind:value={homeQuery}
						placeholder="Cari teman atau topik"
						onkeydown={(event) => {
							if (event.key === 'Enter') event.preventDefault();
						}}
					/>
					{#if searching}<LoaderCircle class="search-spin" size={16} />{/if}
					<a href="/explore" aria-label="Buka filter jelajah"><SlidersHorizontal size={17} /></a>
				</div>
				{#if homeQuery.trim().length >= 2}<div class="home-results surface">
						{#each searchResults as user (user.id)}<div>
								<StoryAvatarLink
									userId={user.id}
									username={user.username}
									name={user.fullName}
									avatarUrl={user.avatarUrl}
									size="sm"
									hasStory={user.hasStory}
									seen={user.storyViewed}
								/><a href={`/u/${user.username}`}
									><strong>{user.fullName}</strong><small>@{user.username}</small></a
								>
							</div>{/each}{#if !searching && searchResults.length === 0}<p>
								Tidak ada pengguna yang cocok.
							</p>{/if}
					</div>{/if}
			</div>
		</header>

		{#if data.unavailable.length > 0}
			<div class="partial-error" role="status">
				<span>Sebagian konten belum dapat dimuat: {data.unavailable.join(', ')}.</span>
				<a href="/home">Coba lagi</a>
			</div>
		{/if}

		<StoryRail stories={data.stories} />
		{#if data.announcement}<AnnouncementCard announcement={data.announcement} />{/if}

		<div class="feed-label">
			<div>
				<span></span>
				<h2>Untuk Anda</h2>
			</div>
			<a href="/explore">Jelajahi lainnya</a>
		</div>

		<div class="feed-list">
			{#each posts as post (post.id)}<PostCard {post} />{/each}
		</div>
		{#if hasMore}
			<div class="load-more">
				<button onclick={loadMore} disabled={loadingMore}>
					{loadingMore ? 'Memuat…' : 'Muat postingan lainnya'}
				</button>
				{#if loadMoreError}<span aria-live="polite">{loadMoreError}</span>{/if}
			</div>
		{/if}

		<div class="feed-end" class:empty={posts.length === 0}>
			<img src="/assets/logo-mark.png" alt="" />
			{#if posts.length === 0}
				<strong>Belum ada postingan untuk ditampilkan</strong>
				<span>Ikuti teman atau kembali beberapa saat lagi.</span>
			{:else}
				<strong>Anda sudah sampai di sini</strong>
				<span>Temukan lebih banyak cerita dari komunitas Portal SI.</span>
			{/if}
			<a href="/explore">Buka Jelajah</a>
		</div>
	</section>

	<RightRail
		suggestions={data.suggestions}
		onlineUsers={data.onlineUsers}
		onlineCount={data.onlineCount}
	/>
</div>

<style>
	.home-layout {
		display: grid;
		max-width: calc(var(--content-width) + var(--right-rail-width) + 72px);
		grid-template-columns: minmax(0, 1fr);
		gap: 32px;
		margin: 0 auto;
		padding: 0;
	}

	.feed-column {
		display: grid;
		min-width: 0;
		align-content: start;
		gap: 14px;
	}

	.desktop-feed-header {
		display: none;
		align-items: end;
		justify-content: space-between;
		gap: 24px;
		padding: 30px 2px 8px;
	}

	.desktop-feed-header h1 {
		margin: 0;
		font-size: 1.65rem;
		letter-spacing: -0.035em;
	}

	.search-box {
		display: flex;
		width: 280px;
		height: 44px;
		align-items: center;
		gap: 8px;
		padding: 0 8px 0 13px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 13px;
		color: var(--color-muted);
	}
	.search-wrap {
		position: relative;
	}
	:global(.search-spin) {
		color: var(--color-primary);
		animation: home-spin 0.8s linear infinite;
	}
	@keyframes home-spin {
		to {
			transform: rotate(360deg);
		}
	}
	.home-results {
		position: absolute;
		z-index: 30;
		top: 50px;
		right: 0;
		left: 0;
		display: grid;
		min-width: 280px;
		padding: 7px;
		box-shadow: var(--shadow-md);
	}
	.home-results > div {
		display: grid;
		grid-template-columns: auto 1fr;
		align-items: center;
		gap: 8px;
		padding: 7px;
	}
	.home-results > div > a:last-child {
		display: grid;
	}
	.home-results strong {
		font-size: 0.72rem;
	}
	.home-results small,
	.home-results p {
		color: var(--color-muted);
		font-size: 0.64rem;
	}
	.home-results p {
		margin: 0;
		padding: 12px;
		text-align: center;
	}

	.search-box:focus-within {
		border-color: var(--color-primary);
		box-shadow: var(--focus-ring);
	}

	.search-box input {
		min-width: 0;
		flex: 1;
		background: transparent;
		border: 0;
		outline: 0;
		font-size: 0.83rem;
	}

	.search-box a {
		display: grid;
		width: 32px;
		height: 32px;
		place-items: center;
		border-radius: 9px;
	}

	.search-box a:hover {
		background: var(--color-primary-soft);
		color: var(--color-primary-strong);
	}

	.feed-label,
	.feed-label > div {
		display: flex;
		align-items: center;
	}

	.feed-label {
		justify-content: space-between;
		padding: 5px 4px 0;
	}

	.feed-label > div {
		gap: 8px;
	}

	.feed-label span {
		width: 7px;
		height: 7px;
		background: var(--color-primary);
		border-radius: 50%;
	}

	.feed-label h2 {
		margin: 0;
		font-size: 0.91rem;
	}

	.feed-label a {
		color: var(--color-muted);
		font-size: 0.75rem;
		font-weight: 650;
	}

	.feed-list {
		display: grid;
		gap: 16px;
	}

	.load-more {
		display: grid;
		justify-items: center;
		gap: 7px;
		padding: 4px 16px;
	}

	.load-more button {
		min-height: 42px;
		padding: 0 18px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 999px;
		color: var(--color-primary-strong);
		font-weight: 740;
		cursor: pointer;
	}

	.load-more button:disabled {
		cursor: wait;
		opacity: 0.65;
	}

	.load-more span {
		color: var(--color-danger);
		font-size: 0.75rem;
	}

	.partial-error {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
		padding: 11px 14px;
		background: #fff8e8;
		border: 1px solid #efdcb8;
		border-radius: 12px;
		color: #784718;
		font-size: 0.78rem;
	}

	.partial-error a {
		flex: none;
		font-weight: 750;
	}

	.feed-end {
		display: grid;
		place-items: center;
		padding: 34px 16px 44px;
		text-align: center;
	}

	.feed-end img {
		width: 42px;
		height: 42px;
		margin-bottom: 9px;
		border-radius: 12px;
		opacity: 0.75;
	}

	.feed-end strong {
		font-size: 0.94rem;
	}

	.feed-end span {
		max-width: 24rem;
		margin-top: 3px;
		color: var(--color-muted);
		font-size: 0.8rem;
	}

	.feed-end a {
		margin-top: 12px;
		color: var(--color-primary-strong);
		font-size: 0.8rem;
		font-weight: 750;
	}

	:global(.right-rail) {
		display: none;
	}

	@media (min-width: 768px) {
		.home-layout {
			padding: 0 28px;
		}

		.desktop-feed-header {
			display: flex;
		}
	}

	@media (min-width: 1200px) {
		.home-layout {
			grid-template-columns: minmax(0, var(--content-width)) var(--right-rail-width);
			padding: 0 32px;
		}

		:global(.right-rail) {
			display: grid;
			position: sticky;
			top: 28px;
			max-height: calc(100vh - 56px);
			margin-top: 92px;
		}
	}
</style>
