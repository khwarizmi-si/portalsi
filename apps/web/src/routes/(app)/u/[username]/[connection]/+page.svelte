<script lang="ts">
	import ConnectionList from '$lib/components/profile/ConnectionList.svelte';
	import type { PageProps } from './$types';
	let { data, params }: PageProps = $props();
</script>

<ConnectionList title={data.title} backHref={`/u/${params.username}`} users={data.users} />
