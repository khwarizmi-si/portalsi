<script lang="ts">
	import { LogIn } from '@lucide/svelte';
	import { page } from '$app/state';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import PostDetailView from '$lib/components/post/PostDetailView.svelte';
	import type { PageProps } from './$types';
	let { data, form }: PageProps = $props();
	const shareUrl = $derived(page.url.href);
</script>

<svelte:head>
	<title>{data.og.title}</title>
	<meta name="description" content={data.og.description} />
	<meta property="og:site_name" content="Portal SI" />
	<meta property="og:type" content="article" />
	<meta property="og:title" content={data.og.title} />
	<meta property="og:description" content={data.og.description} />
	<meta property="og:url" content={shareUrl} />
	{#if data.og.image}<meta property="og:image" content={data.og.image} />{/if}
	<meta name="twitter:card" content={data.og.image ? 'summary_large_image' : 'summary'} />
	<meta name="twitter:title" content={data.og.title} />
	<meta name="twitter:description" content={data.og.description} />
	{#if data.og.image}<meta name="twitter:image" content={data.og.image} />{/if}
	{#if data.isPublic}<meta name="robots" content="index" />{:else}<meta
			name="robots"
			content="noindex"
		/>{/if}
</svelte:head>

{#if data.isPublic}
	<main class="public-post">
		<div class="card surface">
			{#if data.og.image}<img src={data.og.image} alt="" />{/if}
			<div class="body">
				<p class="eyebrow">Postingan Portal SI</p>
				<h1>{data.author}</h1>
				<p class="desc">{data.og.description}</p>
				<a class="cta" href={`/login?next=${encodeURIComponent(`/posts/${data.postId}`)}`}>
					<LogIn size={18} /> Masuk untuk melihat
				</a>
				<a class="alt" href="/welcome">Belum punya akun? Daftar</a>
			</div>
		</div>
	</main>
{:else}
	<SectionPage eyebrow="Diskusi" title="Detail postingan">
		<PostDetailView {data} {form} />
	</SectionPage>
{/if}

<style>
	.public-post {
		display: grid;
		min-height: 100vh;
		place-items: center;
		padding: 24px;
		background: var(--color-canvas);
	}
	.card {
		width: min(100%, 440px);
		overflow: hidden;
		border-radius: 20px;
		text-align: center;
	}
	.card img {
		width: 100%;
		max-height: 340px;
		object-fit: cover;
	}
	.body {
		display: grid;
		justify-items: center;
		gap: 8px;
		padding: 22px 24px 26px;
	}
	.eyebrow {
		margin: 0;
		color: var(--color-primary-strong);
		font-size: 0.72rem;
		font-weight: 750;
		letter-spacing: 0.04em;
		text-transform: uppercase;
	}
	h1 {
		margin: 0;
		font-size: 1.25rem;
	}
	.desc {
		margin: 0;
		color: var(--color-muted);
		font-size: 0.88rem;
		line-height: 1.5;
	}
	.cta {
		display: inline-flex;
		align-items: center;
		gap: 8px;
		margin-top: 10px;
		padding: 12px 20px;
		background: var(--color-primary);
		border-radius: 12px;
		color: white;
		font-weight: 720;
	}
	.alt {
		color: var(--color-muted);
		font-size: 0.8rem;
		font-weight: 650;
	}
</style>
