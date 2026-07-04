<script lang="ts">
	import { Image, Play } from '@lucide/svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import type { PageProps } from './$types';
	let { data }: PageProps = $props();
</script>

<svelte:head><title>Postingan tersimpan — Portal SI</title></svelte:head>
<SectionPage
	eyebrow="Koleksi Anda"
	title="Postingan tersimpan"
	description="Konten yang Anda simpan untuk dilihat kembali."
	><div class="saved">
		{#each data.posts as post (post.id)}<a
				href={`/posts/${post.id}`}
				aria-label={`Buka postingan ${post.user.fullName}`}
			>
				{#if post.isVideo && !post.thumbnailUrl}<video
						src={post.mediaUrl}
						muted
						playsinline
						preload="metadata"
					></video>{:else}<img src={post.thumbnailUrl ?? post.mediaUrl} alt={post.mediaAlt} />{/if}
				<i
					>{#if post.isVideo}<Play size={16} fill="currentColor" />{:else}<Image
							size={16}
						/>{/if}</i
				>
				<span
					><strong>@{post.user.username}</strong><small>{post.caption || 'Tanpa caption'}</small
					></span
				>
			</a>{/each}{#if data.posts.length === 0}<p class="surface">
				Belum ada postingan tersimpan.
			</p>{/if}
	</div></SectionPage
>

<style>
	.saved {
		display: grid;
		grid-template-columns: repeat(3, minmax(0, 1fr));
		gap: 5px;
		margin: 0 auto;
	}
	.saved > a {
		position: relative;
		aspect-ratio: 1;
		overflow: hidden;
		background: var(--color-canvas-deep);
	}
	.saved img,
	.saved video {
		width: 100%;
		height: 100%;
		object-fit: cover;
		transition: transform 180ms ease;
	}
	.saved > a:hover img,
	.saved > a:hover video {
		transform: scale(1.03);
	}
	.saved i {
		position: absolute;
		top: 9px;
		right: 9px;
		display: grid;
		width: 28px;
		height: 28px;
		place-items: center;
		background: rgb(15 18 20 / 56%);
		border-radius: 9px;
		color: white;
		font-style: normal;
	}
	.saved span {
		position: absolute;
		right: 0;
		bottom: 0;
		left: 0;
		display: grid;
		padding: 30px 10px 9px;
		background: linear-gradient(transparent, rgb(10 12 14 / 72%));
		color: white;
		opacity: 0;
		transition: opacity 180ms ease;
	}
	.saved > a:hover span {
		opacity: 1;
	}
	.saved strong {
		font-size: 0.72rem;
	}
	.saved small {
		overflow: hidden;
		font-size: 0.64rem;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.saved > p {
		grid-column: 1 / -1;
		padding: 40px 20px;
		color: var(--color-muted);
		text-align: center;
	}
	@media (max-width: 600px) {
		.saved {
			grid-template-columns: repeat(2, minmax(0, 1fr));
		}
		.saved span {
			display: none;
		}
	}
</style>
