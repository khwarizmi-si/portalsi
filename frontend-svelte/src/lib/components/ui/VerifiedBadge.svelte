<script lang="ts">
	import { BadgeCheck } from '@lucide/svelte';
	let { label = 'Akun terverifikasi' }: { label?: string } = $props();
</script>

<BadgeCheck size={16} strokeWidth={2.6} aria-label={label} class="badge" />

<style>
	:global(.badge) {
		color: var(--color-secondary);
		flex: none;
	}
</style>
