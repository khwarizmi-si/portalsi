<script lang="ts">
	import { ScrollText } from '@lucide/svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import type { PageProps } from './$types';
	let { data }: PageProps = $props();
</script>

<svelte:head><title>{data.doc.title} — Portal SI</title></svelte:head>

<SectionPage eyebrow="Dokumen" title={data.doc.title} description={data.doc.intro}>
	<article class="legal surface">
		<p class="updated"><ScrollText size={14} /> Diperbarui {data.doc.updated}</p>
		{#each data.doc.sections as section (section.h)}
			<section>
				<h2>{section.h}</h2>
				<p>{section.p}</p>
			</section>
		{/each}
		<nav class="legal-links" aria-label="Dokumen lain">
			<a href="/legal/privasi">Kebijakan Privasi</a>
			<a href="/legal/kebijakan">Kebijakan Komunitas</a>
			<a href="/legal/syarat">Syarat &amp; Ketentuan</a>
		</nav>
	</article>
</SectionPage>

<style>
	.legal {
		max-width: 760px;
		padding: clamp(20px, 4vw, 34px);
	}
	.updated {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		margin: 0 0 8px;
		color: var(--color-muted);
		font-size: 0.74rem;
	}
	.legal section {
		padding: 16px 0;
		border-top: 1px solid var(--color-border);
	}
	.legal h2 {
		margin: 0 0 6px;
		font-size: 1.02rem;
	}
	.legal section p {
		margin: 0;
		color: var(--color-muted);
		font-size: 0.9rem;
		line-height: 1.6;
	}
	.legal-links {
		display: flex;
		flex-wrap: wrap;
		gap: 8px;
		margin-top: 18px;
		padding-top: 16px;
		border-top: 1px solid var(--color-border);
	}
	.legal-links a {
		padding: 7px 12px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 999px;
		color: var(--color-primary-strong);
		font-size: 0.76rem;
		font-weight: 680;
	}
</style>
