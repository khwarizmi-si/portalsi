<script lang="ts">
	import '../app.css';
	import { afterNavigate, beforeNavigate } from '$app/navigation';
	import type { Snippet } from 'svelte';
	import ConfirmDialog from '$lib/components/ui/ConfirmDialog.svelte';
	import GlobalProgress from '$lib/components/ui/GlobalProgress.svelte';
	import { finishProgress, startProgress } from '$lib/ui/progress';

	let { children }: { children: Snippet } = $props();
	const calmRoutes = new Set([
		'/home',
		'/explore',
		'/create/post',
		'/marketplace',
		'/notifications',
		'/messages',
		'/profile'
	]);
	const calmPath = (pathname: string) =>
		calmRoutes.has(pathname) || /^\/messages\/?$/.test(pathname);
	beforeNavigate(({ from, to }) => {
		if (from?.url.href !== to?.url.href && !(from && to && calmPath(from.url.pathname) && calmPath(to.url.pathname))) {
			startProgress();
		}
	});
	afterNavigate(() => finishProgress(true));
</script>

<svelte:head>
	<meta name="description" content="Portal SI — ruang berbagi, belajar, dan bertumbuh bersama." />
</svelte:head>

<GlobalProgress />
<ConfirmDialog />
{@render children()}
