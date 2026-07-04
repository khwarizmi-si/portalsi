<script lang="ts">
	import { ChevronRight, Circle } from '@lucide/svelte';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import VerifiedBadge from '$lib/components/ui/VerifiedBadge.svelte';
	import type { PortalUser } from '$lib/types/domain';
	let {
		suggestions,
		onlineUsers = [],
		onlineCount = null
	}: {
		suggestions: PortalUser[];
		onlineUsers?: PortalUser[];
		onlineCount?: number | null;
	} = $props();
	const currentYear = new Date().getFullYear();
</script>

<aside class="right-rail" aria-label="Konteks dan saran">
	<section class="rail-card online">
		<div class="section-head">
			<h2>Sedang aktif</h2>
			<span
				><Circle size={8} fill="currentColor" />{onlineCount === null
					? 'Status tidak tersedia'
					: `${onlineCount} online`}</span
			>
		</div>
		<div class="online-avatars">
			{#each onlineUsers as user (user.id)}<StoryAvatarLink
					userId={user.id}
					username={user.username}
					name={user.fullName}
					avatarUrl={user.avatarUrl}
					size="md"
					hasStory={user.hasStory}
					seen={user.storyViewed}
				/>{/each}
			{#if onlineUsers.length === 0}<small>Belum ada pengikut aktif.</small>{/if}
		</div>
	</section>

	<section class="rail-card suggestions">
		<div class="section-head">
			<h2>Temukan teman</h2>
			<a href="/explore">Lihat semua</a>
		</div>
		{#each suggestions as user (user.id)}
			<div class="suggestion">
				<StoryAvatarLink
					userId={user.id}
					username={user.username}
					name={user.fullName}
					avatarUrl={user.avatarUrl}
					size="sm"
					hasStory={user.hasStory}
					seen={user.storyViewed}
				/>
				<a href={`/u/${user.username}`} class="user-copy">
					<strong
						>{user.fullName}{#if user.badgeVerified}<VerifiedBadge />{/if}</strong
					>
					<small>@{user.username}</small>
				</a>
				<a href={`/u/${user.username}`} aria-label={`Lihat profil ${user.fullName}`}
					><ChevronRight size={18} /></a
				>
			</div>
		{/each}
	</section>

	<footer>
		<a href="/settings">Privasi</a><span>·</span><a href="/announcements">Pengumuman</a><span
			>·</span
		><a href="/store">Store</a>
		<p>© {currentYear} Portal SI</p>
	</footer>
</aside>

<style>
	.right-rail {
		display: grid;
		align-content: start;
		gap: 16px;
		width: var(--right-rail-width);
	}

	.rail-card {
		padding: 17px;
		background: rgb(255 255 255 / 82%);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-xs);
		backdrop-filter: blur(12px);
	}

	.section-head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: 14px;
	}

	.section-head h2 {
		margin: 0;
		font-size: 0.9rem;
	}

	.section-head span,
	.section-head a {
		display: flex;
		align-items: center;
		gap: 5px;
		color: var(--color-secondary);
		font-size: 0.72rem;
		font-weight: 700;
	}

	.online-avatars {
		display: flex;
	}

	.online-avatars > small {
		color: var(--color-muted);
		font-size: 0.7rem;
	}

	.online-avatars :global(a + a) {
		margin-left: -9px;
	}

	.online-avatars :global(a) {
		border-radius: 50%;
	}

	.suggestion {
		display: grid;
		grid-template-columns: auto 1fr auto;
		align-items: center;
		gap: 9px;
		padding: 9px 0;
	}

	.suggestion + .suggestion {
		border-top: 1px solid var(--color-border);
	}

	.user-copy {
		display: grid;
		min-width: 0;
	}

	.user-copy strong {
		display: flex;
		align-items: center;
		gap: 3px;
		font-size: 0.8rem;
	}

	.user-copy small {
		color: var(--color-muted);
		font-size: 0.72rem;
	}

	footer {
		padding: 0 6px;
		color: var(--color-subtle);
		font-size: 0.7rem;
	}

	footer a:hover {
		color: var(--color-text);
	}

	footer span {
		margin: 0 5px;
	}

	footer p {
		margin-top: 7px;
	}
</style>
