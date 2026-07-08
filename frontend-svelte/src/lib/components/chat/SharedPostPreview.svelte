<script lang="ts">
	import { env } from '$env/dynamic/public';
	import { Images, ImageOff, Play } from '@lucide/svelte';
	import { z } from 'zod';
	import { clientRequest } from '$lib/api/client';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import UserBadges from '$lib/components/ui/UserBadges.svelte';
	import { normalizeMediaUrl } from '$lib/utils/media';

	let { postId }: { postId: number } = $props();

	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';

	const booleanish = z.union([z.boolean(), z.literal(0), z.literal(1)]).transform(Boolean);
	const sharedPostSchema = z
		.object({
			post_id: z.coerce.number(),
			caption: z.string().nullish(),
			media_url: z.string().nullish(),
			media_urls: z.array(z.string()).nullish(),
			thumbnail_url: z.string().nullish(),
			is_video: booleanish.catch(false),
			user: z
				.object({
					user_id: z.coerce.number(),
					username: z.string(),
					full_name: z.string().nullish(),
					profile_picture_url: z.string().nullish(),
					is_verified: booleanish.catch(false),
					role: z.enum(['student', 'parent', 'teacher', 'dev', 'other']).catch('other')
				})
				.passthrough()
		})
		.passthrough();

	type SharedPost = {
		id: number;
		caption: string;
		thumb: string | null;
		isVideo: boolean;
		multiple: boolean;
		username: string;
		fullName: string;
		avatarUrl: string | null;
		verified: boolean;
		role: 'student' | 'parent' | 'teacher' | 'dev' | 'other';
	};

	// Cache lintas-pesan agar postingan yang sama tidak di-fetch berulang.
	const cache = new Map<number, Promise<SharedPost>>();

	function fetchPost(id: number): Promise<SharedPost> {
		if (!cache.has(id)) {
			cache.set(
				id,
				clientRequest(`posts/${id}`, { schema: sharedPostSchema }).then((post) => {
					const gallery = post.media_urls ?? [];
					const thumb = post.is_video
						? (normalizeMediaUrl(post.thumbnail_url, mediaBaseUrl) ?? null)
						: (normalizeMediaUrl(post.media_url, mediaBaseUrl) ?? null);
					return {
						id: post.post_id,
						caption: post.caption?.trim() ?? '',
						thumb,
						isVideo: post.is_video,
						multiple: gallery.length > 1,
						username: post.user.username,
						fullName: post.user.full_name?.trim() || post.user.username,
						avatarUrl: normalizeMediaUrl(post.user.profile_picture_url, mediaBaseUrl) ?? null,
						verified: post.user.is_verified,
						role: post.user.role
					} satisfies SharedPost;
				})
			);
		}
		return cache.get(id)!;
	}

	const promise = $derived(fetchPost(postId));
</script>

{#await promise}
	<div class="shared-post loading" aria-busy="true">
		<div class="thumb"></div>
		<div class="meta">
			<div class="line short"></div>
			<div class="line"></div>
		</div>
	</div>
{:then post}
	<a class="shared-post" href={`/posts/${post.id}`} data-sveltekit-preload-data>
		<div class="thumb">
			{#if post.thumb}<img src={post.thumb} alt="" />{:else}<div class="ph">
					<ImageOff size={20} />
				</div>{/if}
			{#if post.isVideo}<span class="badge play"><Play size={13} fill="currentColor" /></span>
			{:else if post.multiple}<span class="badge"><Images size={13} /></span>{/if}
		</div>
		<div class="meta">
			<div class="author">
				<Avatar name={post.fullName} src={post.avatarUrl ?? undefined} size="sm" />
				<strong>@{post.username}</strong><UserBadges verified={post.verified} role={post.role} />
			</div>
			{#if post.caption}<p class="cap">{post.caption}</p>{/if}
			<span class="cta">Lihat postingan</span>
		</div>
	</a>
{:catch}
	<a class="shared-post unavailable" href={`/posts/${postId}`}>
		<div class="thumb"><div class="ph"><ImageOff size={20} /></div></div>
		<div class="meta">
			<strong>Postingan</strong>
			<p class="cap">Ketuk untuk membuka. Postingan mungkin privat atau telah dihapus.</p>
		</div>
	</a>
{/await}

<style>
	.shared-post {
		display: grid;
		grid-template-columns: 84px 1fr;
		width: min(260px, 74vw);
		overflow: hidden;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 14px;
		color: inherit;
	}
	.shared-post:hover {
		border-color: var(--color-primary);
	}
	.thumb {
		position: relative;
		aspect-ratio: 1/1;
		background: var(--color-canvas-deep, #efe9df);
	}
	.thumb img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.thumb .ph {
		display: grid;
		width: 100%;
		height: 100%;
		place-items: center;
		color: var(--color-muted);
	}
	.badge {
		position: absolute;
		top: 6px;
		right: 6px;
		display: grid;
		width: 22px;
		height: 22px;
		place-items: center;
		background: rgb(0 0 0 / 55%);
		border-radius: 50%;
		color: white;
	}
	.meta {
		display: grid;
		align-content: start;
		gap: 5px;
		padding: 9px 11px;
		min-width: 0;
	}
	.author {
		display: flex;
		align-items: center;
		gap: 6px;
		min-width: 0;
	}
	.author strong {
		overflow: hidden;
		font-size: 0.74rem;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.cap {
		display: -webkit-box;
		-webkit-box-orient: vertical;
		-webkit-line-clamp: 2;
		line-clamp: 2;
		overflow: hidden;
		margin: 0;
		color: var(--color-muted);
		font-size: 0.72rem;
		line-height: 1.35;
	}
	.cta {
		margin-top: 2px;
		color: var(--color-primary-strong);
		font-size: 0.7rem;
		font-weight: 700;
	}
	.loading .thumb,
	.loading .line {
		background: linear-gradient(100deg, #e9e3d7 30%, #f5f1e9 50%, #e9e3d7 70%);
		background-size: 200% 100%;
		animation: shared-shimmer 1.2s ease-in-out infinite;
	}
	.loading .meta {
		gap: 8px;
		align-content: center;
	}
	.loading .line {
		height: 9px;
		border-radius: 6px;
	}
	.loading .line.short {
		width: 55%;
	}
	@keyframes shared-shimmer {
		0% {
			background-position: 160% 0;
		}
		100% {
			background-position: -60% 0;
		}
	}
</style>
