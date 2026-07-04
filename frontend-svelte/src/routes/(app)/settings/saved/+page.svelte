<script lang="ts">
	import PostCard from '$lib/components/feed/PostCard.svelte';
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
		{#each data.posts as post (post.id)}<PostCard {post} />{/each}{#if data.posts.length === 0}<p
				class="surface"
			>
				Belum ada postingan tersimpan.
			</p>{/if}
	</div></SectionPage
>

<style>
	.saved {
		display: grid;
		width: min(100%, 620px);
		gap: 16px;
		margin: 0 auto;
	}
	.saved > p {
		padding: 40px 20px;
		color: var(--color-muted);
		text-align: center;
	}
</style>
