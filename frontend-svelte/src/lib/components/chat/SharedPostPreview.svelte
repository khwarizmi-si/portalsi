<script lang="ts">
	import { env } from '$env/dynamic/public';
	import { Copy, ImageOff, Play } from '@lucide/svelte';
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
		thumb: string | null;
		isVideo: boolean;
		multiple: boolean;
		username: string;
		fullName: string;
		avatarUrl: string | null;
		verified: boolean;
		role: 'student' | 'parent' | 'teacher' | 'dev' | 'other';
	};

	// Cache lintas-pesan — HANYA hasil sukses; kegagalan tidak di-cache agar bisa dicoba lagi.
	const cache = new Map<number, Promise<SharedPost>>();

	async function load(id: number): Promise<SharedPost> {
		let lastError: unknown;
		for (let attempt = 0; attempt < 2; attempt += 1) {
			try {
				const post = await clientRequest(`posts/${id}`, { schema: sharedPostSchema });
				const gallery = post.media_urls ?? [];
				return {
					id: post.post_id,
					thumb: post.is_video
						? (normalizeMediaUrl(post.thumbnail_url, mediaBaseUrl) ??
							normalizeMediaUrl(post.media_url, mediaBaseUrl) ??
							null)
						: (normalizeMediaUrl(post.media_url, mediaBaseUrl) ?? null),
					isVideo: post.is_video,
					multiple: gallery.length > 1,
					username: post.user.username,
					fullName: post.user.full_name?.trim() || post.user.username,
					avatarUrl: normalizeMediaUrl(post.user.profile_picture_url, mediaBaseUrl) ?? null,
					verified: post.user.is_verified,
					role: post.user.role
				} satisfies SharedPost;
			} catch (error) {
				lastError = error;
			}
		}
		throw lastError;
	}

	function fetchPost(id: number): Promise<SharedPost> {
		const existing = cache.get(id);
		if (existing) return existing;
		const pending = load(id).catch((error) => {
			cache.delete(id);
			throw error;
		});
		cache.set(id, pending);
		return pending;
	}

	const promise = $derived(fetchPost(postId));
</script>

{#await promise}
	<span class="sp loading" aria-busy="true"></span>
{:then post}
	<a class="sp" href={`/posts/${post.id}`} data-sveltekit-preload-data aria-label={`Postingan @${post.username}`}>
		{#if post.thumb}<img src={post.thumb} alt="" />{:else}<span class="ph"><ImageOff size={26} /></span
			>{/if}
		<span class="top">
			<Avatar name={post.fullName} src={post.avatarUrl ?? undefined} size="sm" />
			<strong>@{post.username}</strong><UserBadges verified={post.verified} role={post.role} />
		</span>
		{#if post.isVideo}<span class="badge"><Play size={14} fill="currentColor" /></span>
		{:else if post.multiple}<span class="badge"><Copy size={14} /></span>{/if}
	</a>
{:catch}
	<a class="sp unavailable" href={`/posts/${postId}`}>
		<span class="ph"><ImageOff size={26} /><small>Ketuk untuk membuka</small></span>
	</a>
{/await}

<style>
	.sp {
		position: relative;
		display: block;
		width: min(240px, 72vw);
		aspect-ratio: 4 / 5;
		overflow: hidden;
		border-radius: 16px;
		background: var(--color-canvas-deep, #efe9df);
		color: white;
		box-shadow: 0 4px 14px rgb(0 0 0 / 12%);
	}
	.sp img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.top {
		position: absolute;
		top: 0;
		right: 0;
		left: 0;
		display: flex;
		align-items: center;
		gap: 7px;
		padding: 9px 10px 20px;
		background: linear-gradient(rgb(0 0 0 / 62%), transparent);
	}
	.top strong {
		overflow: hidden;
		font-size: 0.78rem;
		text-overflow: ellipsis;
		white-space: nowrap;
		text-shadow: 0 1px 3px rgb(0 0 0 / 55%);
	}
	.badge {
		position: absolute;
		top: 9px;
		right: 9px;
		display: grid;
		width: 26px;
		height: 26px;
		place-items: center;
		background: rgb(0 0 0 / 55%);
		border-radius: 50%;
		color: white;
	}
	.ph {
		display: grid;
		width: 100%;
		height: 100%;
		place-content: center;
		justify-items: center;
		gap: 8px;
		background: var(--color-canvas-deep, #efe9df);
		color: var(--color-muted);
	}
	.ph small {
		font-size: 0.74rem;
	}
	.loading {
		background: linear-gradient(100deg, #e9e3d7 30%, #f5f1e9 50%, #e9e3d7 70%);
		background-size: 200% 100%;
		animation: shared-shimmer 1.2s ease-in-out infinite;
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
