<script lang="ts">
	import ConversationPrototype from '$lib/components/chat/ConversationPrototype.svelte';
	import type { PageProps } from './$types';
	let { data }: PageProps = $props();
</script>

<ConversationPrototype {...data} />
