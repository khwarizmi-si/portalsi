<script lang="ts">
	import { Clock, UserCheck, UserPlus } from '@lucide/svelte';
	import { clientRequest } from '$lib/api/client';
	import type { PortalUser } from '$lib/types/domain';

	let { user, size = 'md' }: { user: PortalUser; size?: 'sm' | 'md' } = $props();

	let following = $state(user.isFollowing ?? false);
	let requested = $state(user.isRequested ?? false);
	let busy = $state(false);

	async function toggle(event: MouseEvent) {
		event.preventDefault();
		event.stopPropagation();
		if (busy || user.isSelf) return;
		busy = true;
		const prevFollowing = following;
		const prevRequested = requested;
		try {
			if (following || requested) {
				following = false;
				requested = false;
				await clientRequest(`unfollow/${user.id}`, { method: 'DELETE' });
			} else {
				await clientRequest(`follow/${user.id}`, { method: 'POST' });
				// Akun privat → jadi "diminta" (menunggu ACC); publik → langsung "diikuti".
				if (user.isPrivate) requested = true;
				else following = true;
			}
		} catch {
			following = prevFollowing;
			requested = prevRequested;
		} finally {
			busy = false;
		}
	}
</script>

{#if !user.isSelf}
	<button
		class="follow-btn"
		class:sm={size === 'sm'}
		class:active={following || requested}
		disabled={busy}
		onclick={toggle}
		aria-pressed={following || requested}
	>
		{#if following}<UserCheck size={15} /> Diikuti
		{:else if requested}<Clock size={15} /> Diminta
		{:else}<UserPlus size={15} /> Ikuti{/if}
	</button>
{/if}

<style>
	.follow-btn {
		display: inline-flex;
		flex: none;
		align-items: center;
		gap: 5px;
		min-height: 34px;
		padding: 0 14px;
		background: var(--color-primary);
		border: 1px solid var(--color-primary);
		border-radius: 999px;
		color: white;
		font-size: 0.76rem;
		font-weight: 720;
		cursor: pointer;
		transition:
			background 140ms ease,
			color 140ms ease;
	}
	.follow-btn.sm {
		min-height: 30px;
		padding: 0 11px;
		font-size: 0.72rem;
	}
	.follow-btn.active {
		background: var(--color-surface);
		border-color: var(--color-border);
		color: var(--color-text);
	}
	.follow-btn:disabled {
		opacity: 0.6;
		cursor: default;
	}
</style>
