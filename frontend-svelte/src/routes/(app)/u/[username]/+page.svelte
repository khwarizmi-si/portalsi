<script lang="ts">
	import { env } from '$env/dynamic/public';
	import {
		FileText,
		FolderKanban,
		Grid3X3,
		Image,
		Lock,
		MessageCircle,
		Share2,
		Play,
		UserCheck,
		UserPlus
	} from '@lucide/svelte';
	import { replaceState } from '$app/navigation';
	import { untrack } from 'svelte';
	import { ClientApiError, clientRequest } from '$lib/api/client';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import UserBadges from '$lib/components/ui/UserBadges.svelte';
	import InfiniteScrollTrigger from '$lib/components/ui/InfiniteScrollTrigger.svelte';
	import { profileResponseSchema, type ProfileResponse } from '$lib/schemas/profile';
	import { normalizeMediaUrl } from '$lib/utils/media';
	import { confirmAction } from '$lib/ui/confirm';
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
	let following = $state(untrack(() => data.isFollowing));
	let pending = $state(false);
	let connectionBusy = $state(false);
	let statusMessage = $state(
		untrack(() => (data.connectionUnavailable ? 'Status pertemanan belum dapat diperiksa.' : ''))
	);
	let hasMore = $state(untrack(() => data.hasMore));
	let nextPage = $state(2);
	let loadingPosts = $state(false);
	let activeTab = $state<'posts' | 'portfolio'>(untrack(() => data.initialTab));
	const portfolioLabels = {
		quran: 'Al-Qur’an',
		it: 'Teknologi',
		bahasa: 'Bahasa',
		karakter: 'Karakter'
	};
	let selectedPortfolio = $state<(typeof data.portfolio)[number] | null>(null);

	function selectTab(tab: typeof activeTab) {
		activeTab = tab;
		const target =
			tab === 'portfolio'
				? `/u/${data.profile.username}?tab=portfolio`
				: `/u/${data.profile.username}`;
		replaceState(target, {});
	}
	async function shareProfile() {
		try {
			const url = window.location.href;
			if (navigator.share) await navigator.share({ title: data.profile.fullName, url });
			else await navigator.clipboard.writeText(url);
		} catch {
			statusMessage = 'Profil belum dapat dibagikan.';
		}
	}

	function toGridPosts(profile: ProfileResponse) {
		return profile.recent_posts.map((post) => ({
			id: post.post_id,
			caption: post.caption?.trim() || `Postingan ${profile.username}`,
			mediaUrl: normalizeMediaUrl(post.media_url, mediaBaseUrl) || '/assets/logo.png',
			thumbnailUrl: normalizeMediaUrl(post.thumbnail_url, mediaBaseUrl),
			isVideo: post.is_video
		}));
	}

	async function toggleFollow() {
		if (!data.canFollow || connectionBusy || pending) return;
		connectionBusy = true;
		statusMessage = '';
		try {
			if (following) {
				const confirmed = await confirmAction({
					title: `Berhenti mengikuti ${data.profile.fullName}?`,
					description: `Postingan ${data.profile.fullName} tidak lagi diprioritaskan di beranda Anda. Anda tetap dapat mengikuti kembali kapan saja.`,
					confirmLabel: 'Berhenti mengikuti',
					tone: 'danger'
				});
				if (!confirmed) return;
				await clientRequest(`unfollow/${data.profile.id}`, { method: 'DELETE' });
				following = false;
				statusMessage = 'Berhenti mengikuti.';
			} else {
				const confirmed = await confirmAction({
					title: `Ikuti ${data.profile.fullName}?`,
					description: data.profile.isPrivate
						? 'Akun ini privat. Permintaan Anda akan menunggu persetujuan.'
						: `Postingan ${data.profile.fullName} akan mulai muncul di beranda Anda.`,
					confirmLabel: data.profile.isPrivate ? 'Kirim permintaan' : 'Ikuti sekarang'
				});
				if (!confirmed) return;
				const response = await clientRequest<{ status?: string; message?: string }>(
					`follow/${data.profile.id}`,
					{ method: 'POST' }
				);
				pending = response.status === 'pending';
				following = response.status === 'accepted';
				statusMessage =
					response.message || (pending ? 'Permintaan mengikuti dikirim.' : 'Sekarang mengikuti.');
			}
		} catch (error) {
			if (error instanceof ClientApiError && error.status === 409) {
				pending = true;
				statusMessage = 'Sudah mengikuti atau permintaan masih menunggu.';
			} else statusMessage = 'Perubahan belum dapat disimpan.';
		} finally {
			connectionBusy = false;
		}
	}

	async function loadMore() {
		if (!hasMore || loadingPosts) return;
		loadingPosts = true;
		statusMessage = '';
		try {
			const response = await clientRequest(
				`profile/${encodeURIComponent(data.profile.username)}?page=${nextPage}`,
				{ schema: profileResponseSchema }
			);
			const known = new Set(posts.map((post) => post.id));
			posts.push(...toGridPosts(response).filter((post) => !known.has(post.id)));
			hasMore = Boolean(
				response.pagination && response.pagination.current_page < response.pagination.last_page
			);
			nextPage = (response.pagination?.current_page ?? nextPage) + 1;
		} catch {
			statusMessage = 'Postingan berikutnya belum dapat dimuat.';
		} finally {
			loadingPosts = false;
		}
	}
</script>

<svelte:head>
	<title>{data.profile.fullName} — Portal SI</title>
	<meta name="description" content={`Lihat profil @${data.profile.username} di Portal SI.`} />
	<link rel="canonical" href={`https://portalsi.com/u/${data.profile.username}`} />
	<meta property="og:title" content={`${data.profile.fullName} — Portal SI`} />
	<meta
		property="og:description"
		content={data.profile.bio || `Profil @${data.profile.username}`}
	/>
	{#if data.profile.avatarUrl}<meta property="og:image" content={data.profile.avatarUrl} />{/if}
</svelte:head>

<div class="other-profile">
	<section class="hero surface">
		<div class="banner">
			{#if data.profile.bannerUrl}<img src={data.profile.bannerUrl} alt="" />{/if}
		</div>
		<div class="body">
			<StoryAvatarLink
				userId={data.profile.id}
				username={data.profile.username}
				name={data.profile.fullName}
				avatarUrl={data.profile.avatarUrl ?? undefined}
				size="xl"
				previewable
				hasStory={data.profile.hasStory}
				seen={data.profile.storyViewed}
			/>
			<div class="actions">
				{#if data.isAuthenticated}
					<button
						class:following
						onclick={toggleFollow}
						disabled={!data.canFollow || connectionBusy || pending}
					>
						{#if following}<UserCheck size={17} /> Mengikuti{:else}<UserPlus size={17} />
							{pending ? 'Menunggu' : 'Ikuti'}{/if}
					</button>
					<a
						href={`/messages/direct/${data.profile.id}?name=${encodeURIComponent(data.profile.fullName)}&username=${encodeURIComponent(data.profile.username)}${data.profile.avatarUrl ? `&avatar=${encodeURIComponent(data.profile.avatarUrl)}` : ''}`}
						><MessageCircle size={17} /> Pesan</a
					>
				{:else}
					<a href={`/login?next=${encodeURIComponent(`/u/${data.profile.username}`)}`}
						><UserPlus size={17} /> Masuk untuk mengikuti</a
					>
				{/if}
				<button onclick={shareProfile} aria-label="Bagikan profil"><Share2 size={18} /></button>
			</div>
			<h1>
				{data.profile.fullName}<UserBadges
					verified={data.profile.badgeVerified}
					role={data.profile.role}
				/>
			</h1>
			<p class="handle">
				@{data.profile.username}{#if data.profile.role !== 'student'}
					· {roleLabels[data.profile.role]}{/if}
			</p>
			<p class="bio"><MentionText text={data.profile.bio || 'Belum ada bio.'} /></p>
			<div class="stats">
				<span><strong>{data.profile.postsCount.toLocaleString('id-ID')}</strong> Postingan</span>
				<a href={`/u/${data.profile.username}/followers`}
					><strong>{data.profile.followersCount.toLocaleString('id-ID')}</strong> Pengikut</a
				>
				<a href={`/u/${data.profile.username}/following`}
					><strong>{data.profile.followingCount.toLocaleString('id-ID')}</strong> Mengikuti</a
				>
			</div>
			{#if data.isAuthenticated && !data.canFollow}<p class="verification-note">
					Verifikasi email untuk mengikuti akun.
				</p>{/if}
			{#if statusMessage}<p class="status" aria-live="polite">{statusMessage}</p>{/if}
		</div>
	</section>
	<nav aria-label="Konten profil">
		<button class:active={activeTab === 'posts'} onclick={() => selectTab('posts')}
			><Grid3X3 size={17} /> Postingan</button
		>
		{#if data.isAuthenticated}<button
				class:active={activeTab === 'portfolio'}
				onclick={() => selectTab('portfolio')}><FolderKanban size={17} /> Portfolio</button
			>{/if}
	</nav>
	{#if activeTab === 'posts' && posts.length > 0}
		<section class="grid">
			{#each posts as post (post.id)}<a href={`/posts/${post.id}`}
					>{#if post.isVideo && !post.thumbnailUrl}<video
							src={post.mediaUrl}
							muted
							playsinline
							preload="metadata"
						></video>{:else}<img
							src={post.thumbnailUrl ?? post.mediaUrl}
							alt={post.caption}
						/>{/if}{#if post.isVideo}<span><Play size={16} fill="currentColor" /></span>{/if}</a
				>{/each}
		</section>
		<InfiniteScrollTrigger
			{hasMore}
			loading={loadingPosts}
			itemCount={posts.length}
			onLoad={loadMore}
			label="Memuat postingan berikutnya…"
		/>
	{:else if activeTab === 'posts'}
		<section class="empty surface">
			{#if data.profile.isPrivate}<Lock size={24} />{:else}<Image size={24} />{/if}<strong
				>{data.profile.isPrivate ? 'Akun ini privat' : 'Belum ada postingan'}</strong
			><span>{data.profile.message || 'Postingan akan muncul di sini.'}</span>
		</section>
	{:else if data.portfolio.length > 0}
		<section class="portfolio-grid">
			{#each data.portfolio as item (item.id)}
				<button
					type="button"
					class="surface portfolio-card"
					onclick={() => (selectedPortfolio = item)}
				>
					{#if item.mediaUrl && item.mediaUrl.toLowerCase().includes('.pdf')}
						<span class="portfolio-media pdf"><FileText size={30} /><span>PDF</span></span>
					{:else if item.mediaUrl}
						<img src={item.mediaUrl} alt={item.title} />
					{:else}
						<span class="portfolio-media pdf"><FolderKanban size={26} /></span>
					{/if}
					<span class="card-body">
						<small>{portfolioLabels[item.aspect]} · {item.year || '—'}</small>
						<span class="card-title">{item.title}</span>
						<span class="card-desc">{item.description || 'Tanpa deskripsi.'}</span>
					</span>
				</button>
			{/each}
		</section>
	{:else}
		<section class="empty surface">
			<FolderKanban size={24} /><strong>Belum ada portfolio</strong><span
				>Karya dan pencapaian pengguna ini akan muncul di sini.</span
			>
		</section>
	{/if}
</div>

<svelte:window onkeydown={(e) => e.key === 'Escape' && (selectedPortfolio = null)} />

{#if selectedPortfolio}
	<!-- svelte-ignore a11y_click_events_have_key_events, a11y_no_static_element_interactions -->
	<div class="portfolio-modal" onclick={() => (selectedPortfolio = null)}>
		<div
			class="portfolio-dialog surface"
			role="dialog"
			aria-modal="true"
			aria-label={selectedPortfolio.title}
			onclick={(e) => e.stopPropagation()}
		>
			<button class="dialog-close" onclick={() => (selectedPortfolio = null)} aria-label="Tutup"
				>×</button
			>
			{#if selectedPortfolio.mediaUrl && selectedPortfolio.mediaUrl.toLowerCase().includes('.pdf')}
				<a
					class="dialog-media pdf"
					href={selectedPortfolio.mediaUrl}
					target="_blank"
					rel="noreferrer"><FileText size={34} /><span>Buka PDF</span></a
				>
			{:else if selectedPortfolio.mediaUrl}
				<img class="dialog-media" src={selectedPortfolio.mediaUrl} alt={selectedPortfolio.title} />
			{/if}
			<div class="dialog-body">
				<small>{portfolioLabels[selectedPortfolio.aspect]} · {selectedPortfolio.year || '—'}</small>
				<h2>{selectedPortfolio.title}</h2>
				<p>{selectedPortfolio.description || 'Tanpa deskripsi.'}</p>
				{#if selectedPortfolio.signed_by}<small class="signature"
						>Signed by {selectedPortfolio.signed_by.full_name ||
							`@${selectedPortfolio.signed_by.username}`}{selectedPortfolio.signed_by.role ===
						'teacher'
							? ' · Teacher'
							: ''}</small
					>{/if}
			</div>
		</div>
	</div>
{/if}

<style>
	.other-profile {
		width: min(100% - 32px, 860px);
		margin: 28px auto 50px;
	}
	.hero {
		overflow: hidden;
	}
	.banner {
		aspect-ratio: 5 / 1;
		background: linear-gradient(125deg, #f7d694, #4da99c);
	}
	.banner img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.body {
		position: relative;
		padding: 0 25px 24px;
	}
	.body > :global(.avatar-wrap) {
		margin-top: -40px;
		box-shadow: 0 0 0 5px white;
	}
	.actions {
		position: absolute;
		top: 14px;
		right: 22px;
		display: flex;
		gap: 7px;
	}
	.actions button,
	.actions a {
		display: flex;
		height: 40px;
		align-items: center;
		gap: 6px;
		padding: 0 13px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 11px;
		font-size: 0.76rem;
		font-weight: 700;
	}
	.actions button:first-child {
		background: var(--color-primary);
		border-color: var(--color-primary);
		color: white;
	}
	.actions button.following {
		background: white;
		color: var(--color-primary-strong);
	}
	.actions button:disabled {
		cursor: not-allowed;
		opacity: 0.68;
	}
	.body h1 {
		display: flex;
		align-items: center;
		gap: 5px;
		margin: 14px 0 0;
		font-size: 1.25rem;
	}
	.handle {
		margin: 1px 0 12px;
		color: var(--color-muted);
		font-size: 0.77rem;
	}
	.bio {
		max-width: 35rem;
		margin: 0;
		font-size: 0.84rem;
	}
	.stats {
		display: flex;
		gap: 24px;
		margin-top: 18px;
	}
	.stats span,
	.stats a {
		display: flex;
		gap: 5px;
		color: var(--color-muted);
		font-size: 0.72rem;
	}
	.stats strong {
		color: var(--color-text);
	}
	.status,
	.verification-note {
		margin: 12px 0 0;
		color: var(--color-primary-strong);
		font-size: 0.76rem;
	}
	nav {
		display: flex;
		justify-content: center;
		margin-top: 14px;
		border-bottom: 1px solid var(--color-border);
	}
	nav button {
		display: flex;
		min-height: 48px;
		align-items: center;
		gap: 6px;
		padding: 0 20px;
		background: transparent;
		border: 0;
		border-bottom: 2px solid transparent;
		color: var(--color-muted);
		font-size: 0.76rem;
		font-weight: 680;
	}
	nav button.active {
		border-bottom-color: var(--color-primary);
		color: var(--color-primary-strong);
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 4px;
		margin-top: 4px;
		overflow: hidden;
		border-radius: var(--radius-lg);
	}
	.grid a {
		position: relative;
		aspect-ratio: 1;
		overflow: hidden;
		background: var(--color-canvas-deep);
	}
	.grid img,
	.grid video {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.grid a span {
		position: absolute;
		top: 8px;
		right: 8px;
		color: white;
		filter: drop-shadow(0 1px 2px #000);
	}
	.portfolio-grid {
		display: grid;
		grid-template-columns: repeat(3, minmax(0, 1fr));
		gap: 12px;
		margin-top: 14px;
	}
	.portfolio-card {
		display: block;
		width: 100%;
		padding: 0;
		overflow: hidden;
		text-align: left;
		border: 1px solid var(--color-border);
		cursor: pointer;
		transition: border-color 140ms ease;
	}
	.portfolio-card:hover,
	.portfolio-card:focus-visible {
		border-color: var(--color-primary);
	}
	.portfolio-grid img,
	.portfolio-media {
		display: grid;
		width: 100%;
		aspect-ratio: 4 / 3;
		place-content: center;
		justify-items: center;
		gap: 6px;
		object-fit: cover;
		background: var(--color-secondary-soft);
		color: var(--color-secondary);
	}
	.card-body {
		display: block;
		padding: 13px;
	}
	.card-title {
		display: block;
		margin: 5px 0;
		overflow: hidden;
		font-size: 0.92rem;
		font-weight: 700;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.card-desc {
		display: -webkit-box;
		overflow: hidden;
		color: var(--color-muted);
		font-size: 0.74rem;
		-webkit-box-orient: vertical;
		-webkit-line-clamp: 2;
		line-clamp: 2;
	}
	.portfolio-grid small {
		color: var(--color-primary-strong);
		font-size: 0.66rem;
	}
	.portfolio-grid h2 {
		margin: 5px 0;
		font-size: 0.92rem;
	}
	.portfolio-grid p {
		margin: 0;
		color: var(--color-muted);
		font-size: 0.74rem;
	}
	.portfolio-grid .signature {
		display: block;
		margin-top: 8px;
		padding: 6px 8px;
		background: var(--color-secondary-soft);
		border-radius: 7px;
		color: var(--color-secondary);
	}
	.empty {
		display: grid;
		justify-items: center;
	}
	.empty {
		gap: 6px;
		margin-top: 18px;
		padding: 48px 20px;
		text-align: center;
	}
	.empty span {
		color: var(--color-muted);
		font-size: 0.8rem;
	}
	.portfolio-modal {
		position: fixed;
		inset: 0;
		z-index: 60;
		display: grid;
		place-items: center;
		padding: 18px;
		background: rgb(18 14 10 / 62%);
		backdrop-filter: blur(3px);
	}
	.portfolio-dialog {
		position: relative;
		width: min(100%, 520px);
		max-height: 90vh;
		overflow: auto;
	}
	.dialog-close {
		position: absolute;
		top: 10px;
		right: 10px;
		display: grid;
		width: 34px;
		height: 34px;
		place-items: center;
		background: rgb(0 0 0 / 45%);
		border: 0;
		border-radius: 50%;
		color: white;
		font-size: 1.3rem;
		line-height: 1;
		cursor: pointer;
	}
	.dialog-media {
		display: grid;
		width: 100%;
		max-height: 60vh;
		place-content: center;
		justify-items: center;
		gap: 6px;
		object-fit: contain;
		background: var(--color-secondary-soft);
		color: var(--color-secondary);
	}
	.dialog-body {
		padding: 16px 18px 20px;
	}
	.dialog-body small {
		color: var(--color-primary-strong);
		font-size: 0.68rem;
	}
	.dialog-body h2 {
		margin: 6px 0;
		font-size: 1.05rem;
	}
	.dialog-body p {
		margin: 0;
		color: var(--color-muted);
		font-size: 0.84rem;
		white-space: pre-wrap;
	}
	.dialog-body .signature {
		display: block;
		margin-top: 12px;
		padding: 7px 9px;
		background: var(--color-secondary-soft);
		border-radius: 7px;
		color: var(--color-secondary);
	}
	@media (max-width: 767px) {
		nav button,
		.profile-tabs a {
			flex: 1;
			justify-content: center;
			padding-inline: 6px;
		}
		.other-profile {
			width: 100%;
			margin-top: 0;
		}
		.hero {
			border-inline: 0;
			border-radius: 0;
		}
		.body {
			padding-inline: 16px;
		}
		.actions {
			right: 12px;
		}
		.actions button,
		.actions a {
			width: 40px;
			padding: 0;
			justify-content: center;
			font-size: 0;
		}
		.stats {
			justify-content: space-between;
			gap: 8px;
		}
		.grid {
			border-radius: 0;
		}
		.portfolio-grid {
			grid-template-columns: repeat(2, minmax(0, 1fr));
			padding-inline: 12px;
		}
	}
</style>
