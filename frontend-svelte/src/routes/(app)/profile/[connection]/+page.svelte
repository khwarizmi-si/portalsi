<script lang="ts">
	import ConnectionList from '$lib/components/profile/ConnectionList.svelte';
	import type { PageProps } from './$types';
	let { data }: PageProps = $props();
</script>

<ConnectionList title={data.title} backHref="/profile" users={data.users} />
