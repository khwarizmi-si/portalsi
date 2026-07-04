<script lang="ts">
	import VerifiedBadge from './VerifiedBadge.svelte';
	import DevBadge from './DevBadge.svelte';
	import type { UserRole } from '$lib/types/domain';
	let { verified = false, role = 'other' }: { verified?: boolean; role?: UserRole } = $props();
</script>

{#if verified || role === 'dev'}<span class="user-badges">
		{#if verified}<VerifiedBadge />{/if}
		{#if role === 'dev'}<DevBadge />{/if}
	</span>{/if}

<style>
	.user-badges {
		display: inline-flex;
		align-items: center;
		gap: 4px;
		vertical-align: middle;
	}
</style>
