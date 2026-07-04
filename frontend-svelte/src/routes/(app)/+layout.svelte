<script lang="ts">
	import type { Snippet } from 'svelte';
	import { page } from '$app/state';
	import AppShell from '$lib/components/layout/AppShell.svelte';
	import type { LayoutProps } from './$types';
	let { children, data }: { children: Snippet; data: LayoutProps['data'] } = $props();
	const immersive = $derived(/^\/(?:create|stories)\//.test(page.url.pathname));
</script>

{#if data.user && !immersive}
	<AppShell user={data.user}>{@render children()}</AppShell>
{:else}
	{@render children()}
{/if}
