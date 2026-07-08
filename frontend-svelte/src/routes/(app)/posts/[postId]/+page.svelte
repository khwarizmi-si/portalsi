<script lang="ts">
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import PostDetailView from '$lib/components/post/PostDetailView.svelte';
	import type { PageProps } from './$types';
	let { data, form }: PageProps = $props();
</script>

<svelte:head
	><title>Postingan — Portal SI</title><meta name="robots" content="noindex" /></svelte:head
>

<SectionPage eyebrow="Diskusi" title="Detail postingan">
	<PostDetailView {data} {form} />
</SectionPage>
