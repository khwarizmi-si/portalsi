<script lang="ts">
	import { Bookmark, Heart, MessageCircle, Music2, Send } from '@lucide/svelte';
	import { clientRequest } from '$lib/api/client';
	import SmartVideo from '$lib/components/media/SmartVideo.svelte';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import UserBadges from '$lib/components/ui/UserBadges.svelte';
	import { untrack } from 'svelte';
	import type { PageProps } from './$types';
	let { data }: PageProps = $props();
	let liked = $state(untrack(() => data.clip.isLiked));
	let bookmarked = $state(untrack(() => data.clip.isBookmarked));
	let likes = $state(untrack(() => data.clip.likesCount));
	let message = $state('');
	async function like() {
		const previous = liked;
		liked = !liked;
		likes += liked ? 1 : -1;
		try {
			await clientRequest(`posts/${data.clip.id}/like`, { method: 'POST' });
		} catch {
			liked = previous;
			likes += liked ? 1 : -1;
			message = 'Like belum tersimpan.';
		}
	}
	async function bookmark() {
		const previous = bookmarked;
		bookmarked = !bookmarked;
		try {
			await clientRequest(`bookmarks/${data.clip.id}`, { method: bookmarked ? 'POST' : 'DELETE' });
		} catch {
			bookmarked = previous;
			message = 'Simpan belum berhasil.';
		}
	}
	async function share() {
		const url = location.href;
		try {
			if (navigator.share) await navigator.share({ title: data.clip.mediaAlt, url });
			else {
				await navigator.clipboard.writeText(url);
				message = 'Tautan disalin.';
			}
		} catch {
			message = 'Clips belum dapat dibagikan.';
		}
	}
</script>

<svelte:head><title>Clips — Portal SI</title><meta name="robots" content="noindex" /></svelte:head>
<div class="clips-page">
	<article>
		<SmartVideo
			src={data.clip.mediaUrl}
			poster={data.clip.thumbnailUrl}
			label={data.clip.mediaAlt}
			fill
		/>
		<header>
			<StoryAvatarLink
				userId={data.clip.user.id}
				username={data.clip.user.username}
				name={data.clip.user.fullName}
				avatarUrl={data.clip.user.avatarUrl}
				size="sm"
				hasStory={data.clip.user.hasStory}
				seen={data.clip.user.storyViewed}
			/><strong
				>{data.clip.user.fullName}<UserBadges
					verified={data.clip.user.badgeVerified}
					role={data.clip.user.role}
				/></strong
			><a href={`/u/${data.clip.user.username}`}>Lihat profil</a>
		</header>
		<div class="caption">
			<p>{data.clip.caption}</p>
			<span
				><Music2 size={14} />{data.clip.music
					? `${data.clip.music.title} — ${data.clip.music.artist}`
					: `Suara asli · ${data.clip.user.fullName}`}</span
			>{#if message}<small aria-live="polite">{message}</small>{/if}
		</div>
		<aside>
			<button class:active={liked} onclick={like}
				><Heart size={25} fill={liked ? 'currentColor' : 'none'} /><small>{likes}</small></button
			><a href={`/posts/${data.clip.id}#comments`}
				><MessageCircle size={25} /><small>{data.clip.commentsCount}</small></a
			><button onclick={share}><Send size={24} /><small>Bagikan</small></button><button
				class:active={bookmarked}
				onclick={bookmark}
				><Bookmark size={24} fill={bookmarked ? 'currentColor' : 'none'} /></button
			>{#if data.nextId}<a href={`/clips/${data.nextId}`}><small>Clips<br />berikutnya</small></a
				>{/if}
		</aside>
	</article>
</div>

<style>
	.clips-page {
		display: grid;
		min-height: 100vh;
		place-items: center;
		padding: 20px;
		background: #17130f;
	}
	.clips-page article {
		position: relative;
		width: min(100%, 470px);
		height: calc(100vh - 40px);
		overflow: hidden;
		background: #31251b;
		border-radius: 18px;
		color: white;
	}
	.clips-page article::after {
		position: absolute;
		inset: 45% 0 0;
		background: linear-gradient(transparent, rgb(0 0 0/0.72));
		pointer-events: none;
		content: '';
	}
	header {
		position: absolute;
		z-index: 3;
		right: 70px;
		bottom: 145px;
		left: 18px;
		display: flex;
		align-items: center;
		gap: 8px;
	}
	header strong {
		font-size: 0.82rem;
	}
	header a {
		margin-left: auto;
		padding: 5px 9px;
		border: 1px solid rgb(255 255 255/0.55);
		border-radius: 8px;
		font-size: 0.68rem;
		font-weight: 700;
	}
	.caption {
		position: absolute;
		z-index: 3;
		right: 70px;
		bottom: 68px;
		left: 18px;
	}
	.caption p {
		display: -webkit-box;
		margin: 0 0 8px;
		overflow: hidden;
		-webkit-box-orient: vertical;
		-webkit-line-clamp: 2;
		line-clamp: 2;
		font-size: 0.82rem;
	}
	.caption span {
		display: flex;
		align-items: center;
		gap: 5px;
		font-size: 0.68rem;
	}
	.caption small {
		display: block;
		margin-top: 5px;
		color: #ffd18a;
		font-size: 0.64rem;
	}
	aside {
		position: absolute;
		z-index: 3;
		right: 10px;
		bottom: 62px;
		display: grid;
		gap: 8px;
	}
	aside button,
	aside a {
		display: grid;
		width: 48px;
		min-height: 48px;
		place-items: center;
		background: rgb(0 0 0/0.28);
		border: 0;
		border-radius: 50%;
		color: white;
	}
	aside button.active {
		color: #ffb23e;
	}
	aside small {
		font-size: 0.58rem;
		text-align: center;
	}
	@media (max-width: 767px) {
		.clips-page {
			min-height: calc(100vh - 64px);
			padding: 0;
		}
		.clips-page article {
			height: calc(100vh - 132px);
			border-radius: 0;
		}
	}
</style>
