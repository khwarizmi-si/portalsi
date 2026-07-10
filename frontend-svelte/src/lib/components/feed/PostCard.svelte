<script lang="ts">
	import {
		Bookmark,
		ChevronLeft,
		ChevronRight,
		Heart,
		MapPin,
		Maximize2,
		MessageCircle,
		Send
	} from '@lucide/svelte';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import UserBadges from '$lib/components/ui/UserBadges.svelte';
	import SmartVideo from '$lib/components/media/SmartVideo.svelte';
	import ViewportMusic from '$lib/components/media/ViewportMusic.svelte';
	import MediaLightbox from '$lib/components/media/MediaLightbox.svelte';
	import { clientRequest } from '$lib/api/client';
	import type { PostPreview } from '$lib/types/domain';
	import MentionText from '$lib/components/ui/MentionText.svelte';
	import SharePostSheet from '$lib/components/feed/SharePostSheet.svelte';

	let {
		post,
		zoomable = false,
		autoplay = false,
		preferSound = false
	}: { post: PostPreview; zoomable?: boolean; autoplay?: boolean; preferSound?: boolean } = $props();
	let lightboxOpen = $state(false);
	let lightboxIndex = $state(0);
	let shareOpen = $state(false);

	// Galeri multi-foto (Instagram-style). Video selalu tunggal.
	const gallery = $derived(post.media && post.media.length > 0 ? post.media : [post.mediaUrl]);
	const isGallery = $derived(!post.isVideo && gallery.length > 1);
	let slide = $state(0);
	let trackEl = $state<HTMLDivElement>();
	function onTrackScroll() {
		if (!trackEl) return;
		slide = Math.round(trackEl.scrollLeft / (trackEl.clientWidth || 1));
	}
	function goSlide(index: number) {
		if (!trackEl) return;
		const clamped = Math.max(0, Math.min(gallery.length - 1, index));
		trackEl.scrollTo({ left: clamped * trackEl.clientWidth, behavior: 'smooth' });
	}
	function openLightbox(index: number) {
		lightboxIndex = index;
		lightboxOpen = true;
	}
	function initialInteractionState() {
		return {
			liked: post.isLiked,
			bookmarked: post.isBookmarked,
			likesCount: post.likesCount
		};
	}
	let interaction = $state(initialInteractionState());
	let liking = $state(false);
	let bookmarking = $state(false);
	let interactionError = $state('');

	async function toggleLike() {
		if (liking) return;
		liking = true;
		interactionError = '';
		interaction.liked = !interaction.liked;
		interaction.likesCount += interaction.liked ? 1 : -1;
		try {
			await clientRequest(`posts/${post.id}/like`, { method: 'POST' });
		} catch {
			interaction.liked = !interaction.liked;
			interaction.likesCount += interaction.liked ? 1 : -1;
			interactionError = 'Like belum tersimpan. Coba lagi.';
		} finally {
			liking = false;
		}
	}

	async function toggleBookmark() {
		if (bookmarking) return;
		bookmarking = true;
		interactionError = '';
		interaction.bookmarked = !interaction.bookmarked;
		try {
			await clientRequest(`bookmarks/${post.id}`, {
				method: interaction.bookmarked ? 'POST' : 'DELETE'
			});
		} catch {
			interaction.bookmarked = !interaction.bookmarked;
			interactionError = 'Perubahan simpan belum berhasil.';
		} finally {
			bookmarking = false;
		}
	}

	const shareUrl = $derived(
		typeof window !== 'undefined'
			? new URL(`/posts/${post.id}`, window.location.origin).toString()
			: `https://app.portalsi.com/posts/${post.id}`
	);
	function sharePost() {
		shareOpen = true;
	}
</script>

<article class="post-card" aria-labelledby={`post-${post.id}-author`}>
	<header>
		<div class="author">
			<StoryAvatarLink
				userId={post.user.id}
				username={post.user.username}
				name={post.user.fullName}
				avatarUrl={post.user.avatarUrl}
				size="md"
				hasStory={post.user.hasStory}
				seen={post.user.storyViewed}
			/>
			<a href={`/u/${post.user.username}`} class="author-copy">
				<strong id={`post-${post.id}-author`}
					>{post.user.fullName}
					<UserBadges verified={post.user.badgeVerified} role={post.user.role} /></strong
				>
				<small>@{post.user.username} · {post.createdLabel}</small>
			</a>
		</div>
	</header>

	{#if post.location || post.music}
		<div class="context-row">
			{#if post.location}<span><MapPin size={13} />{post.location}</span>{/if}
			{#if post.music}<ViewportMusic
					src={post.music.previewUrl}
					title={post.music.title}
					artist={post.music.artist}
					start={post.music.startSeconds}
					clipDuration={post.music.durationSeconds}
				/>{/if}
		</div>
	{/if}

	{#if post.isVideo}<div class="media" class:zoomable>
			<SmartVideo
				src={post.mediaUrl}
				poster={post.thumbnailUrl}
				label={post.mediaAlt}
				{autoplay}
				forceMuted={post.videoMuted || Boolean(post.music)}
				preferSound={preferSound || zoomable}
			/>
			{#if zoomable}<button
					class="expand-media"
					onclick={() => openLightbox(0)}
					aria-label="Perbesar video"><Maximize2 size={19} /></button
				>{/if}
		</div>{:else if isGallery}<div class="media gallery">
			<div class="gallery-track" bind:this={trackEl} onscroll={onTrackScroll}>
				{#each gallery as src, index (index)}
					{#if zoomable}<button class="slide" onclick={() => openLightbox(index)}
							><img src={src} alt={`${post.mediaAlt} (${index + 1})`} /></button
						>{:else}<a class="slide" href={`/posts/${post.id}`}
							><img src={src} alt={`${post.mediaAlt} (${index + 1})`} /></a
						>{/if}
				{/each}
			</div>
			<span class="counter">{slide + 1}/{gallery.length}</span>
			{#if slide > 0}<button
					class="nav prev"
					onclick={() => goSlide(slide - 1)}
					aria-label="Foto sebelumnya"><ChevronLeft size={20} /></button
				>{/if}
			{#if slide < gallery.length - 1}<button
					class="nav next"
					onclick={() => goSlide(slide + 1)}
					aria-label="Foto berikutnya"><ChevronRight size={20} /></button
				>{/if}
			<div class="dots">
				{#each gallery as _, index (index)}<span class:on={index === slide}></span>{/each}
			</div>
		</div>{:else if zoomable}<button
			class="media zoomable"
			onclick={() => openLightbox(0)}
			aria-label={`Perbesar postingan ${post.user.fullName}`}
			><img src={post.mediaUrl} alt={post.mediaAlt} /><span class="zoom-cue"
				><Maximize2 size={20} /> Perbesar</span
			></button
		>{:else}<a
			class="media"
			href={`/posts/${post.id}`}
			aria-label={`Buka postingan ${post.user.fullName}`}
			><img src={post.mediaUrl} alt={post.mediaAlt} /></a
		>{/if}

	<div class="actions">
		<div>
			<button
				class:active={interaction.liked}
				onclick={toggleLike}
				disabled={liking}
				aria-pressed={interaction.liked}
				aria-label={interaction.liked ? 'Batal menyukai' : 'Sukai'}
			>
				<Heart size={22} fill={interaction.liked ? 'currentColor' : 'none'} />
			</button>
			<a href={`/posts/${post.id}#comments`} aria-label="Komentar"><MessageCircle size={22} /></a>
			<button onclick={sharePost} aria-label="Bagikan"><Send size={21} /></button>
		</div>
		<button
			class:active={interaction.bookmarked}
			onclick={toggleBookmark}
			disabled={bookmarking}
			aria-pressed={interaction.bookmarked}
			aria-label={interaction.bookmarked ? 'Hapus dari tersimpan' : 'Simpan'}
		>
			<Bookmark size={22} fill={interaction.bookmarked ? 'currentColor' : 'none'} />
		</button>
	</div>

	<div class="post-copy">
		{#if interactionError}<p class="interaction-status" aria-live="polite">
				{interactionError}
			</p>{/if}
		<p class="counts">
			<b>{interaction.likesCount.toLocaleString('id-ID')}</b> suka ·
			<a href={`/posts/${post.id}#comments`}>{post.commentsCount} komentar</a>
		</p>
		<p class="caption">
			<a href={`/u/${post.user.username}`}>@{post.user.username}</a>
			<MentionText text={post.caption} />
		</p>
		<a class="comments" href={`/posts/${post.id}#comments`}>Lihat percakapan</a>
	</div>
</article>

<MediaLightbox
	open={lightboxOpen}
	src={post.isVideo ? post.mediaUrl : (gallery[lightboxIndex] ?? post.mediaUrl)}
	alt={post.mediaAlt}
	isVideo={post.isVideo}
	poster={post.thumbnailUrl}
	onClose={() => (lightboxOpen = false)}
/>

{#if shareOpen}
	<SharePostSheet postId={post.id} {shareUrl} onClose={() => (shareOpen = false)} />
{/if}

<style>
	.post-card {
		overflow: hidden;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-xs);
	}

	header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 14px 15px 11px;
	}

	.author {
		display: flex;
		min-width: 0;
		align-items: center;
		gap: 10px;
	}

	.author-copy {
		display: grid;
		min-width: 0;
	}

	.author strong {
		display: flex;
		align-items: center;
		gap: 4px;
		font-size: 0.91rem;
	}

	.author small {
		color: var(--color-muted);
		font-size: 0.76rem;
	}

	.actions button,
	.actions a {
		display: grid;
		width: 42px;
		height: 42px;
		place-items: center;
		padding: 0;
		background: transparent;
		border: 0;
		border-radius: 50%;
		cursor: pointer;
	}

	.actions button:hover,
	.actions a:hover {
		background: var(--color-primary-soft);
	}

	.context-row {
		display: flex;
		gap: 12px;
		padding: 0 16px 10px 69px;
		overflow: hidden;
		color: var(--color-muted);
		font-size: 0.72rem;
	}

	.context-row span {
		display: flex;
		min-width: 0;
		align-items: center;
		gap: 4px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.media {
		position: relative;
		display: block;
		width: 100%;
		padding: 0;
		overflow: hidden;
		background: var(--color-canvas-deep);
		border: 0;
	}
	.media.zoomable {
		cursor: zoom-in;
	}
	.media.zoomable img {
		transition: transform 220ms ease;
	}
	.media.zoomable:hover img {
		transform: scale(1.018);
	}
	.expand-media,
	.zoom-cue {
		position: absolute;
		z-index: 3;
		right: 14px;
		bottom: 14px;
		display: flex;
		align-items: center;
		gap: 6px;
		padding: 9px 11px;
		background: rgb(0 0 0 / 58%);
		border: 1px solid rgb(255 255 255 / 20%);
		border-radius: 999px;
		color: white;
		font-size: 0.68rem;
		font-weight: 700;
		backdrop-filter: blur(8px);
	}
	.expand-media {
		width: 42px;
		height: 42px;
		justify-content: center;
		padding: 0;
	}
	.zoom-cue {
		opacity: 0;
		transform: translateY(5px);
		transition: 170ms ease;
	}
	.media.zoomable:hover .zoom-cue,
	.media.zoomable:focus-visible .zoom-cue {
		opacity: 1;
		transform: translateY(0);
	}

	.media img {
		display: block;
		width: 100%;
		max-height: 82vh;
		object-fit: contain;
	}

	/* Galeri multi-foto */
	.gallery {
		position: relative;
	}
	.gallery-track {
		display: flex;
		overflow-x: auto;
		scroll-snap-type: x mandatory;
		scrollbar-width: none;
		-webkit-overflow-scrolling: touch;
	}
	.gallery-track::-webkit-scrollbar {
		display: none;
	}
	.gallery .slide {
		flex: 0 0 100%;
		scroll-snap-align: center;
		padding: 0;
		border: 0;
		background: var(--color-canvas-deep);
		cursor: pointer;
	}
	.gallery .slide img {
		max-height: 82vh;
	}
	.gallery .counter {
		position: absolute;
		top: 12px;
		right: 12px;
		z-index: 3;
		padding: 4px 10px;
		background: rgb(0 0 0 / 60%);
		border-radius: 999px;
		color: white;
		font-size: 0.68rem;
		font-weight: 700;
		backdrop-filter: blur(6px);
	}
	.gallery .nav {
		position: absolute;
		top: 50%;
		z-index: 3;
		display: grid;
		width: 32px;
		height: 32px;
		place-items: center;
		padding: 0;
		background: rgb(255 255 255 / 82%);
		border: 0;
		border-radius: 50%;
		color: #1d1915;
		transform: translateY(-50%);
		box-shadow: 0 2px 8px rgb(0 0 0 / 22%);
	}
	.gallery .nav.prev {
		left: 10px;
	}
	.gallery .nav.next {
		right: 10px;
	}
	.gallery .dots {
		position: absolute;
		bottom: 12px;
		left: 0;
		right: 0;
		z-index: 3;
		display: flex;
		justify-content: center;
		gap: 5px;
		pointer-events: none;
	}
	.gallery .dots span {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background: rgb(255 255 255 / 55%);
		box-shadow: 0 0 3px rgb(0 0 0 / 40%);
		transition: background 160ms ease;
	}
	.gallery .dots span.on {
		background: white;
	}
	@media (hover: none) {
		.gallery .nav {
			display: none;
		}
	}

	.actions,
	.actions > div {
		display: flex;
		align-items: center;
	}

	.actions {
		justify-content: space-between;
		padding: 7px 9px 0;
	}

	.actions .active {
		color: var(--color-primary-strong);
	}

	.actions button:disabled {
		cursor: wait;
		opacity: 0.6;
	}

	.post-copy {
		padding: 0 16px 16px;
	}

	.post-copy p {
		margin-bottom: 6px;
	}

	.post-copy .interaction-status {
		margin-top: 2px;
		color: var(--color-primary-strong);
		font-size: 0.75rem;
	}

	.counts {
		font-size: 0.81rem;
	}

	.caption {
		font-size: 0.91rem;
		line-height: 1.5;
		/* Pertahankan baris baru & spasi seperti yang diketik user (paragraf). */
		white-space: pre-wrap;
		overflow-wrap: anywhere;
	}

	.caption a {
		font-weight: 720;
	}

	.comments {
		color: var(--color-muted);
		font-size: 0.82rem;
		font-weight: 580;
	}

	@media (max-width: 767px) {
		.post-card {
			border-inline: 0;
			border-radius: 0;
		}
	}
</style>
