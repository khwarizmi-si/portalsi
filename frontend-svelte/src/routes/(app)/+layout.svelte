<script lang="ts">
	import type { Snippet } from 'svelte';
	import AppShell from '$lib/components/layout/AppShell.svelte';
	import type { LayoutProps } from './$types';
	let { children, data }: { children: Snippet; data: LayoutProps['data'] } = $props();
</script>

{#if data.user}
	<AppShell user={data.user}>{@render children()}</AppShell>
{:else}
	{@render children()}
{/if}
