<script lang="ts">
	import { BadgeCheck } from '@lucide/svelte';
	let { label = 'Akun terverifikasi' }: { label?: string } = $props();
</script>

<BadgeCheck size={16} strokeWidth={2.6} aria-label={label} class="badge" />

<style>
	:global(.badge) {
		color: #1687e8;
		filter: drop-shadow(0 1px 2px rgb(22 135 232 / 22%));
		flex: none;
	}
</style>
