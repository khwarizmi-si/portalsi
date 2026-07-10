<script lang="ts">
	import VerifiedBadge from './VerifiedBadge.svelte';
	import DevBadge from './DevBadge.svelte';
	import type { UserRole } from '$lib/types/domain';
	import RoleBadge from './RoleBadge.svelte';
	let { verified = false, role = 'other' }: { verified?: boolean; role?: UserRole } = $props();
</script>

{#if verified || ['dev', 'teacher', 'parent'].includes(role)}<span class="user-badges">
		{#if verified}<VerifiedBadge />{/if}
		{#if role === 'dev'}<DevBadge />{/if}
		{#if role === 'teacher' || role === 'parent'}<RoleBadge {role} />{/if}
	</span>{/if}

<style>
	.user-badges {
		display: inline-flex;
		align-items: center;
		gap: 4px;
		vertical-align: middle;
	}
</style>
