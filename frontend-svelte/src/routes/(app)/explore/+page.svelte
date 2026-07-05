<script lang="ts">
	import { env } from '$env/dynamic/public';
	import { untrack } from 'svelte';
	import { Image, LoaderCircle, Play, Search, SlidersHorizontal, Users, X } from '@lucide/svelte';
	import { clientRequest } from '$lib/api/client';
	import { mapCompactUser, mapPost } from '$lib/api/mappers';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import UserBadges from '$lib/components/ui/UserBadges.svelte';
	import InfiniteScrollTrigger from '$lib/components/ui/InfiniteScrollTrigger.svelte';
	import { exploreResponseSchema, userSearchResponseSchema } from '$lib/schemas/post';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	let searchQuery = $state(untrack(() => data.query));
	let livePeople = $state(untrack(() => [...data.people]));
	let searching = $state(false);
	let searchMessage = $state('');
	let showFilters = $state(false);
	let showPeople = $state(false);
	let posts = $state(untrack(() => [...data.posts]));
	let nextPage = $state(untrack(() => data.page + 1));
	let hasMore = $state(untrack(() => data.hasNext));
	let loadingMore = $state(false);
	let loadError = $state('');
	const visiblePeople = $derived(searchQuery.trim().length >= 2 ? livePeople : data.people);

	// Sinkronkan grid saat filter/sort berganti (navigasi client-side) — tanpa perlu refresh manual.
	$effect(() => {
		const incomingPosts = data.posts;
		void data.sort;
		untrack(() => {
			posts = [...incomingPosts];
			nextPage = data.page + 1;
			hasMore = data.hasNext;
			loadError = '';
		});
	});

	$effect(() => {
		const query = searchQuery.trim();
		if (query.length < 2) {
			searching = false;
			searchMessage = '';
			return;
		}
		searching = true;
		searchMessage = '';
		const controller = new AbortController();
		const timer = window.setTimeout(async () => {
			try {
				const encoded = encodeURIComponent(query);
				const response = await clientRequest(
					`users/search?username=${encoded}&full_name=${encoded}&per_page=12`,
					{ schema: userSearchResponseSchema, signal: controller.signal }
				);
				livePeople = response.data.map((user) => mapCompactUser(user, mediaBaseUrl));
				if (!livePeople.length) searchMessage = 'Tidak ada pengguna yang cocok.';
			} catch (error) {
				if (!(error instanceof DOMException && error.name === 'AbortError')) {
					livePeople = [];
					searchMessage = 'Tidak ada pengguna yang cocok.';
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
	function filterHref(sort: string, page = 1) {
		const params = [`sort=${encodeURIComponent(sort)}`, `page=${page}`];
		if (data.query) params.push(`q=${encodeURIComponent(data.query)}`);
		return `/explore?${params.join('&')}`;
	}
	async function loadMore() {
		if (!hasMore || loadingMore) return;
		loadingMore = true;
		loadError = '';
		try {
			const response = await clientRequest(
				`explore?sort=${encodeURIComponent(data.sort)}&page=${nextPage}&per_page=15`,
				{ schema: exploreResponseSchema }
			);
			const known = new Set(posts.map((post) => post.id));
			posts.push(
				...response.data
					.map((post) => mapPost(post, mediaBaseUrl))
					.filter((post) => !known.has(post.id))
			);
			nextPage = response.current_page + 1;
			hasMore = response.current_page < response.last_page;
		} catch {
			loadError = 'Konten berikutnya belum dapat dimuat.';
		} finally {
			loadingMore = false;
		}
	}
</script>

<svelte:head><title>Jelajah — Portal SI</title><meta name="robots" content="noindex" /></svelte:head
>

<SectionPage
	eyebrow="Temukan hal baru"
	title="Jelajah"
	description="Karya, cerita, dan orang-orang dari seluruh komunitas Portal SI."
>
	<form class="search-row" onsubmit={(event) => event.preventDefault()}>
		<label
			><Search size={19} /><span class="sr-only">Cari pengguna atau topik</span><input
				bind:value={searchQuery}
				placeholder="Cari pengguna atau topik"
			/>{#if searching}<LoaderCircle class="spin" size={17} />{:else if searchQuery}<button
					type="button"
					class="clear"
					onclick={() => (searchQuery = '')}
					aria-label="Hapus pencarian"><X size={16} /></button
				>{/if}</label
		>
		<button
			class="filter-action"
			type="button"
			class:active={showFilters}
			aria-pressed={showFilters}
			onclick={() => (showFilters = !showFilters)}><SlidersHorizontal size={18} /> Filter</button
		>
	</form>
	{#if searchQuery.trim().length >= 2}<section class="live-results surface" aria-live="polite">
			<h2>Hasil cepat</h2>
			{#each visiblePeople as user (user.id)}<div>
					<StoryAvatarLink
						userId={user.id}
						username={user.username}
						name={user.fullName}
						avatarUrl={user.avatarUrl}
						size="sm"
						hasStory={user.hasStory}
						seen={user.storyViewed}
					/><a href={`/u/${user.username}`}
						><strong
							>{user.fullName}<UserBadges verified={user.badgeVerified} role={user.role} /></strong
						><small>@{user.username}</small></a
					>
				</div>{/each}{#if searchMessage}<p>{searchMessage}</p>{/if}
		</section>{/if}
	{#if showFilters}<nav class="filters surface" id="filters" aria-label="Filter jelajah">
			<span class="filters-label"><SlidersHorizontal size={14} /> Urutkan</span>
			<a class:active={data.sort === 'random'} href={filterHref('random')}>Untuk Anda</a>
			<a class:active={data.sort === 'newest'} href={filterHref('newest')}>Terbaru</a>
			<a class:active={data.sort === 'popular'} href={filterHref('popular')}>Populer</a>
			<button
				type="button"
				class="people-toggle"
				class:active={showPeople}
				aria-pressed={showPeople}
				onclick={() => (showPeople = !showPeople)}><Users size={14} /> Orang</button
			>
		</nav>{/if}
	{#if showPeople || data.query}<section class="people surface" id="people">
		<h2><Users size={16} /> {data.query ? `Hasil pengguna untuk “${data.query}”` : 'Orang yang mungkin Anda kenal'}</h2>
		{#if data.peopleUnavailable}<p class="people-error">
				Sebagian hasil pengguna belum dapat dimuat.
			</p>{/if}
		<div>
			{#each data.people as user (user.id)}<article>
					<StoryAvatarLink
						userId={user.id}
						username={user.username}
						name={user.fullName}
						avatarUrl={user.avatarUrl}
						size="md"
						hasStory={user.hasStory}
						seen={user.storyViewed}
					/><a href={`/u/${user.username}`}
						><strong
							>{user.fullName}<UserBadges verified={user.badgeVerified} role={user.role} /></strong
						><small>@{user.username}</small></a
					>
				</article>{/each}
		</div>
		{#if data.people.length === 0}<p class="empty">Tidak ada pengguna yang cocok.</p>{/if}
	</section>{/if}
	<section class="explore-grid" aria-label="Konten jelajah">
		{#each posts as post, index (post.id)}
			<a href={`/posts/${post.id}`} class:wide={index % 7 === 0}>
				{#if post.isVideo && !post.thumbnailUrl}<video
						src={post.mediaUrl}
						muted
						playsinline
						preload="metadata"
					></video>{:else}<img src={post.thumbnailUrl ?? post.mediaUrl} alt={post.mediaAlt} />{/if}
				<span
					>{#if post.isVideo}<Play size={17} fill="currentColor" />{:else}<Image
							size={17}
						/>{/if}</span
				>
				<div>
					<strong
						>{post.user.fullName}<UserBadges
							verified={post.user.badgeVerified}
							role={post.user.role}
						/></strong
					><small>{post.likesCount} suka</small>
				</div>
			</a>
		{/each}
	</section>
	{#if data.exploreUnavailable}<p class="service-note">
			Konten jelajah sedang diperbarui. Pencarian pengguna tetap dapat digunakan.
		</p>{/if}
	{#if posts.length === 0}<p class="empty">Belum ada postingan untuk filter ini.</p>{/if}
	<InfiniteScrollTrigger
		{hasMore}
		loading={loadingMore}
		itemCount={posts.length}
		onLoad={loadMore}
		label="Memuat jelajah berikutnya…"
	/>
	{#if loadError}<p class="service-note" aria-live="polite">{loadError}</p>{/if}
</SectionPage>

<style>
	.search-row {
		display: flex;
		gap: 10px;
		margin-bottom: 13px;
	}
	.search-row label {
		display: flex;
		min-width: 0;
		height: 48px;
		flex: 1;
		align-items: center;
		gap: 9px;
		padding: 0 14px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 13px;
		color: var(--color-muted);
	}
	.search-row label:focus-within {
		border-color: var(--color-primary);
		box-shadow: var(--focus-ring);
	}
	.search-row input {
		min-width: 0;
		flex: 1;
		border: 0;
		outline: 0;
	}
	.filter-action {
		display: flex;
		align-items: center;
		gap: 7px;
		padding: 0 17px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 13px;
		font-weight: 680;
	}
	.filter-action.active {
		background: var(--color-text);
		border-color: var(--color-text);
		color: white;
	}
	.search-row .clear {
		display: grid;
		width: 30px;
		height: 30px;
		place-items: center;
		padding: 0;
		background: transparent;
		border: 0;
		color: var(--color-muted);
	}
	:global(.spin) {
		animation: spin 0.8s linear infinite;
	}
	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}
	.live-results {
		display: grid;
		gap: 2px;
		margin: -4px 0 13px;
		padding: 10px;
	}
	.live-results h2 {
		margin: 0 6px 4px;
		color: var(--color-muted);
		font-size: 0.7rem;
		text-transform: uppercase;
		letter-spacing: 0.05em;
	}
	.live-results > div {
		display: grid;
		grid-template-columns: auto 1fr;
		align-items: center;
		gap: 9px;
		padding: 7px;
		border-radius: 9px;
	}
	.live-results > div:hover {
		background: var(--color-surface-soft);
	}
	.live-results > div > a:last-child {
		display: grid;
	}
	.live-results strong {
		font-size: 0.76rem;
	}
	.live-results small,
	.live-results p {
		color: var(--color-muted);
		font-size: 0.68rem;
	}
	.live-results p {
		margin: 0;
		padding: 12px;
		text-align: center;
	}
	.filters {
		display: flex;
		align-items: center;
		gap: 8px;
		margin-bottom: 16px;
		padding: 10px 12px;
		border-radius: 14px;
		overflow-x: auto;
		scrollbar-width: none;
	}
	.filters-label {
		display: inline-flex;
		align-items: center;
		gap: 5px;
		padding-right: 2px;
		color: var(--color-muted);
		font-size: 0.68rem;
		font-weight: 750;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		white-space: nowrap;
	}
	.filters a,
	.people-toggle {
		display: flex;
		align-items: center;
		gap: 5px;
		min-height: 31px;
		flex: none;
		padding: 0 12px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 999px;
		color: var(--color-muted);
		font-size: 0.73rem;
		font-weight: 670;
		cursor: pointer;
	}
	.people-toggle {
		margin-left: auto;
	}
	.filters a.active,
	.people-toggle.active {
		background: var(--color-text);
		border-color: var(--color-text);
		color: white;
	}
	.explore-grid {
		display: grid;
		grid-template-columns: repeat(3, minmax(0, 1fr));
		gap: 4px;
		overflow: hidden;
		border-radius: var(--radius-lg);
	}
	.explore-grid > a {
		position: relative;
		aspect-ratio: 1;
		overflow: hidden;
		background: var(--color-canvas-deep);
	}
	.explore-grid > a.wide {
		grid-column: span 2;
		grid-row: span 2;
	}
	@media (min-width: 768px) {
		/* Desktop khusus: 4 kolom sama besar, mengalir ke bawah — tanpa tile lebar. */
		.explore-grid {
			grid-template-columns: repeat(4, minmax(0, 1fr));
		}
		.explore-grid > a.wide {
			grid-column: auto;
			grid-row: auto;
		}
	}
	.explore-grid img,
	.explore-grid video {
		width: 100%;
		height: 100%;
		object-fit: cover;
		transition: transform 250ms var(--ease);
	}
	.explore-grid > a:hover img {
		transform: scale(1.025);
	}
	.explore-grid > a > span {
		position: absolute;
		top: 10px;
		right: 10px;
		display: grid;
		width: 30px;
		height: 30px;
		place-items: center;
		background: rgb(20 16 12 / 54%);
		border-radius: 9px;
		color: white;
	}
	.explore-grid > a > div {
		position: absolute;
		right: 0;
		bottom: 0;
		left: 0;
		display: grid;
		padding: 28px 10px 9px;
		background: linear-gradient(transparent, rgb(15 12 9 / 65%));
		color: white;
		opacity: 0;
	}
	.explore-grid > a:hover > div {
		opacity: 1;
	}
	.explore-grid strong {
		font-size: 0.8rem;
	}
	.explore-grid small {
		font-size: 0.68rem;
	}
	.people {
		margin: 4px 0 18px;
		padding: 18px;
	}
	.people h2 {
		display: flex;
		align-items: center;
		gap: 7px;
		margin: 0 0 14px;
		font-size: 0.95rem;
	}
	.people > div {
		display: flex;
		gap: 12px;
		overflow-x: auto;
	}
	.people article {
		display: grid;
		min-width: 150px;
		justify-items: center;
		padding: 15px;
		border: 1px solid var(--color-border);
		border-radius: 14px;
		text-align: center;
	}
	.people article > a:last-child {
		display: grid;
		margin-top: 8px;
	}
	.people strong {
		font-size: 0.82rem;
	}
	.people small {
		color: var(--color-muted);
		font-size: 0.72rem;
	}
	.people-error,
	.empty {
		color: var(--color-muted);
		font-size: 0.78rem;
	}
	.service-note {
		margin: 10px 0;
		padding: 13px;
		background: var(--color-primary-soft);
		border-radius: 11px;
		color: var(--color-primary-strong);
		font-size: 0.76rem;
		text-align: center;
	}
	.empty {
		padding: 28px 16px;
		text-align: center;
	}
	@media (max-width: 767px) {
		.search-row,
		.filters {
			padding-inline: 16px;
		}
		.filter-action {
			width: 48px;
			padding: 0;
			justify-content: center;
			font-size: 0;
		}
		.explore-grid {
			border-radius: 0;
		}
		.explore-grid > a > div {
			display: none;
		}
		.people {
			border-inline: 0;
			border-radius: 0;
		}
	}
</style>
