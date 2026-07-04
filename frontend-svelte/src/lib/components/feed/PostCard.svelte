<script lang="ts">
	import { Bookmark, Heart, MapPin, MessageCircle, Music2, Send } from '@lucide/svelte';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import VerifiedBadge from '$lib/components/ui/VerifiedBadge.svelte';
	import { clientRequest } from '$lib/api/client';
	import type { PostPreview } from '$lib/types/domain';

	let { post }: { post: PostPreview } = $props();
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

	async function sharePost() {
		const url = new URL(`/posts/${post.id}`, window.location.origin).toString();
		try {
			if (navigator.share) await navigator.share({ title: post.mediaAlt, url });
			else {
				await navigator.clipboard.writeText(url);
				interactionError = 'Tautan postingan disalin.';
			}
		} catch (error) {
			if (error instanceof DOMException && error.name === 'AbortError') return;
			interactionError = 'Tautan belum dapat dibagikan.';
		}
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
					{#if post.user.badgeVerified}<VerifiedBadge />{/if}</strong
				>
				<small>@{post.user.username} · {post.createdLabel}</small>
			</a>
		</div>
	</header>

	{#if post.location || post.music}
		<div class="context-row">
			{#if post.location}<span><MapPin size={13} />{post.location}</span>{/if}
			{#if post.music}<span><Music2 size={13} />{post.music.title} — {post.music.artist}</span>{/if}
		</div>
	{/if}

	{#if post.isVideo}<div class="media">
			<video src={post.mediaUrl} poster={post.thumbnailUrl} controls preload="metadata" playsinline
				><track kind="captions" label="Takarir tidak tersedia" /></video
			>
		</div>{:else}<a
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
			{post.caption}
		</p>
		<a class="comments" href={`/posts/${post.id}#comments`}>Lihat percakapan</a>
	</div>
</article>

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
		display: block;
		aspect-ratio: 4 / 4.25;
		overflow: hidden;
		background: var(--color-canvas-deep);
	}

	.media img,
	.media video {
		width: 100%;
		height: 100%;
		object-fit: cover;
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
