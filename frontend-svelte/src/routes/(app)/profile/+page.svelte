<script lang="ts">
	import { env } from '$env/dynamic/public';
	import { Bookmark, Grid3X3, Layers, Maximize2, Play, Settings, Share2, X } from '@lucide/svelte';
	import { untrack } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import UserBadges from '$lib/components/ui/UserBadges.svelte';
	import InfiniteScrollTrigger from '$lib/components/ui/InfiniteScrollTrigger.svelte';
	import { profileResponseSchema, type ProfileResponse } from '$lib/schemas/profile';
	import { normalizeMediaUrl } from '$lib/utils/media';
	import type { PageProps } from './$types';
	import MentionText from '$lib/components/ui/MentionText.svelte';

	let { data }: PageProps = $props();
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	const roleLabels = {
		student: 'Siswa',
		parent: 'Orang tua',
		teacher: 'Guru',
		dev: 'Pengembang',
		other: 'Anggota'
	};
	let posts = $state(untrack(() => [...data.posts]));
	let hasMore = $state(untrack(() => data.hasMore));
	let nextPage = $state(2);
	let loading = $state(false);
	let loadError = $state('');
	let photoOpen = $state(false);
	async function shareProfile() {
		try {
			const url = new URL(`/u/${data.profile.username}`, window.location.origin).toString();
			if (navigator.share) await navigator.share({ title: data.profile.fullName, url });
			else await navigator.clipboard.writeText(url);
		} catch {
			loadError = 'Profil belum dapat dibagikan.';
		}
	}

	function toGridPosts(profile: ProfileResponse) {
		return profile.recent_posts.map((post) => ({
			id: post.post_id,
			caption: post.caption?.trim() || `Postingan ${profile.username}`,
			mediaUrl: normalizeMediaUrl(post.media_url, mediaBaseUrl) || '/assets/logo.png',
			thumbnailUrl: normalizeMediaUrl(post.thumbnail_url, mediaBaseUrl),
			isVideo: post.is_video,
			isMultiple: post.is_multiple
		}));
	}

	async function loadMore() {
		if (!hasMore || loading) return;
		loading = true;
		loadError = '';
		try {
			const response = await clientRequest(`user?page=${nextPage}`, {
				schema: profileResponseSchema
			});
			const known = new Set(posts.map((post) => post.id));
			posts.push(...toGridPosts(response).filter((post) => !known.has(post.id)));
			hasMore = Boolean(
				response.pagination && response.pagination.current_page < response.pagination.last_page
			);
			nextPage = (response.pagination?.current_page ?? nextPage) + 1;
		} catch {
			loadError = 'Postingan berikutnya belum dapat dimuat.';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head><title>Profil — Portal SI</title><meta name="robots" content="noindex" /></svelte:head>

<div class="profile-page">
	<section class="profile-hero surface">
		<div class="banner">
			{#if data.profile.bannerUrl}<img src={data.profile.bannerUrl} alt="Banner profil" />{/if}
		</div>
		<div class="profile-main">
			<div class="avatar-slot">
				<StoryAvatarLink
					userId={data.profile.id}
					username={data.profile.username}
					name={data.profile.fullName}
					avatarUrl={data.profile.avatarUrl ?? undefined}
					size="xl"
					hasStory={data.profile.hasStory}
					seen={data.profile.storyViewed}
					profileHref="/profile"
				/>
				{#if data.profile.avatarUrl}<button
						class="expand-photo"
						onclick={() => (photoOpen = true)}
						aria-label="Perbesar foto profil"><Maximize2 size={13} /></button
					>{/if}
			</div>
			<div class="profile-actions">
				<a href="/profile/edit">Edit profil</a>
				<a href="/settings" aria-label="Pengaturan"><Settings size={19} /></a>
				<button onclick={shareProfile} aria-label="Bagikan profil"><Share2 size={19} /></button>
			</div>
			<div class="identity">
				<h1>
					{data.profile.fullName}<UserBadges
						verified={data.profile.badgeVerified}
						role={data.profile.role}
					/>
				</h1>
				<p>
					@{data.profile.username}{#if data.profile.role !== 'student'} · {roleLabels[
							data.profile.role
						]}{/if}
				</p>
			</div>
			<p class="bio"><MentionText text={data.profile.bio || 'Belum ada bio.'} /></p>
			<div class="stats">
				<a href="/profile/followers">
					<strong>{data.profile.followersCount.toLocaleString('id-ID')}</strong><span>Pengikut</span
					>
				</a>
				<a href="/profile/following">
					<strong>{data.profile.followingCount.toLocaleString('id-ID')}</strong><span
						>Mengikuti</span
					>
				</a>
				<span>
					<strong>{data.profile.postsCount.toLocaleString('id-ID')}</strong><span>Postingan</span>
				</span>
			</div>
		</div>
	</section>

	<nav class="profile-tabs" aria-label="Konten profil">
		<a class="active" href="/profile"><Grid3X3 size={17} /> Postingan</a>
		<a href={`/portfolio?user_id=${data.profile.id}`}>Portfolio</a>
		<a href="/settings/saved"><Bookmark size={17} /> Tersimpan</a>
	</nav>

	{#if posts.length > 0}
		<section class="profile-grid" aria-label={`Postingan ${data.profile.fullName}`}>
			{#each posts as post (post.id)}
				<a href={`/posts/${post.id}`}>
					{#if post.isVideo && !post.thumbnailUrl}<video
							src={post.mediaUrl}
							muted
							playsinline
							preload="metadata"
						></video>{:else}<img src={post.thumbnailUrl ?? post.mediaUrl} alt={post.caption} />{/if}
					{#if post.isVideo}<span aria-label="Video"><Play size={14} fill="currentColor" /></span
						>{:else if post.isMultiple}<span aria-label="Beberapa foto"><Layers size={14} /></span
						>{/if}
				</a>
			{/each}
		</section>
		<InfiniteScrollTrigger
			{hasMore}
			{loading}
			itemCount={posts.length}
			onLoad={loadMore}
			label="Memuat postingan berikutnya…"
		/>
		{#if loadError}<p class="load-error" aria-live="polite">{loadError}</p>{/if}
	{:else}
		<section class="empty-profile surface">
			<strong>Belum ada postingan</strong><span>Karya yang Anda bagikan akan muncul di sini.</span>
		</section>
	{/if}
</div>

<svelte:window onkeydown={(event) => event.key === 'Escape' && (photoOpen = false)} />

{#if photoOpen && data.profile.avatarUrl}
	<!-- svelte-ignore a11y_click_events_have_key_events, a11y_no_static_element_interactions -->
	<div class="photo-modal" onclick={() => (photoOpen = false)}>
		<img
			class="photo-full"
			src={data.profile.avatarUrl}
			alt={`Foto profil ${data.profile.fullName}`}
			onclick={(event) => event.stopPropagation()}
		/>
		<button class="photo-close" onclick={() => (photoOpen = false)} aria-label="Tutup"
			><X size={20} /></button
		>
	</div>
{/if}

<style>
	.profile-page {
		width: min(100% - 32px, 920px);
		margin: 0 auto;
		padding: 28px 0 50px;
	}
	.profile-hero {
		overflow: hidden;
	}
	.banner {
		aspect-ratio: 5 / 1;
		background:
			radial-gradient(circle at 78% 25%, rgb(255 255 255 / 50%), transparent 12rem),
			linear-gradient(125deg, #f5c875, #86cfc3 62%, #3c9188);
	}
	.banner img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.profile-main {
		position: relative;
		padding: 0 28px 25px;
	}
	.profile-main > :global(.avatar-wrap) {
		margin-top: -42px;
		box-shadow: 0 0 0 5px white;
	}
	.avatar-slot {
		position: relative;
		display: inline-grid;
		margin-top: -42px;
	}
	.avatar-slot :global(.avatar-wrap) {
		margin-top: 0;
		box-shadow: 0 0 0 5px white;
	}
	.expand-photo {
		position: absolute;
		right: 2px;
		bottom: 2px;
		z-index: 2;
		display: grid;
		width: 26px;
		height: 26px;
		place-items: center;
		padding: 0;
		background: rgb(0 0 0 / 55%);
		border: 2px solid white;
		border-radius: 50%;
		color: white;
		cursor: pointer;
	}
	.photo-modal {
		position: fixed;
		inset: 0;
		z-index: 80;
		display: grid;
		place-items: center;
		padding: 24px;
		background: rgb(12 9 6 / 82%);
		backdrop-filter: blur(4px);
	}
	.photo-full {
		max-width: min(92vw, 520px);
		max-height: 82vh;
		object-fit: contain;
		border-radius: 16px;
		box-shadow: 0 30px 80px rgb(0 0 0 / 55%);
	}
	.photo-close {
		position: fixed;
		top: 18px;
		right: 18px;
		display: grid;
		width: 40px;
		height: 40px;
		place-items: center;
		background: rgb(255 255 255 / 15%);
		border: 0;
		border-radius: 50%;
		color: white;
		cursor: pointer;
	}
	.profile-actions {
		position: absolute;
		top: 14px;
		right: 24px;
		display: flex;
		gap: 7px;
	}
	.profile-actions a,
	.profile-actions button {
		display: grid;
		min-width: 42px;
		height: 42px;
		place-items: center;
		padding: 0 14px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 12px;
		font-size: 0.8rem;
		font-weight: 700;
	}
	.identity h1 {
		display: flex;
		align-items: center;
		gap: 5px;
		margin: 14px 0 0;
		font-size: 1.35rem;
		letter-spacing: -0.03em;
	}
	.identity p {
		margin: 2px 0 0;
		color: var(--color-muted);
		font-size: 0.8rem;
	}
	.bio {
		max-width: 38rem;
		margin: 14px 0 7px;
		font-size: 0.88rem;
	}
	.stats {
		display: flex;
		gap: 28px;
		margin-top: 22px;
		padding-top: 18px;
		border-top: 1px solid var(--color-border);
	}
	.stats > a,
	.stats > span {
		display: grid;
	}
	.stats strong {
		font-size: 0.94rem;
	}
	.stats span {
		color: var(--color-muted);
		font-size: 0.7rem;
	}
	.profile-tabs {
		display: flex;
		justify-content: center;
		gap: 8px;
		margin-top: 18px;
		border-bottom: 1px solid var(--color-border);
	}
	.profile-tabs a {
		display: flex;
		min-height: 48px;
		align-items: center;
		gap: 7px;
		padding: 0 20px;
		color: var(--color-muted);
		font-size: 0.78rem;
		font-weight: 680;
	}
	.profile-tabs a.active {
		border-bottom: 2px solid var(--color-primary);
		color: var(--color-primary-strong);
	}
	.profile-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 4px;
		margin-top: 4px;
		overflow: hidden;
		border-radius: var(--radius-lg);
	}
	.profile-grid a {
		position: relative;
		aspect-ratio: 1;
		overflow: hidden;
		background: var(--color-canvas-deep);
	}
	.profile-grid img,
	.profile-grid video {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.profile-grid a span {
		position: absolute;
		right: 7px;
		top: 7px;
		display: grid;
		place-items: center;
		width: 24px;
		height: 24px;
		background: rgb(22 17 12 / 55%);
		border-radius: 50%;
		color: white;
		filter: drop-shadow(0 1px 2px rgb(0 0 0 / 0.4));
	}
	.empty-profile {
		display: grid;
		justify-items: center;
		gap: 6px;
		text-align: center;
	}
	.empty-profile span {
		color: var(--color-muted);
		font-size: 0.78rem;
	}
	.empty-profile {
		margin-top: 18px;
		padding: 48px 20px;
	}
	@media (max-width: 767px) {
		.profile-page {
			width: 100%;
			padding-top: 0;
		}
		.profile-hero {
			border-inline: 0;
			border-radius: 0;
		}
		.profile-main {
			padding-inline: 16px;
		}
		.profile-actions {
			right: 14px;
		}
		.profile-actions a:first-child {
			padding-inline: 12px;
		}
		.stats {
			justify-content: space-between;
			gap: 8px;
		}
		.profile-tabs {
			justify-content: center;
		}
		.profile-tabs a {
			flex: 1;
			justify-content: center;
			padding-inline: 6px;
			white-space: nowrap;
		}
		.profile-grid {
			border-radius: 0;
		}
	}
</style>
