<script lang="ts">
	import { ArrowLeft } from '@lucide/svelte';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import UserBadges from '$lib/components/ui/UserBadges.svelte';
	import FollowButton from '$lib/components/ui/FollowButton.svelte';
	import type { PortalUser } from '$lib/types/domain';
	let { title, backHref, users }: { title: string; backHref: string; users: PortalUser[] } =
		$props();

	let sortMode = $state<'unfollowed' | 'alphabet'>('unfollowed');

	// Urutan stabil: pakai status follow AWAL (klik tombol tak memindah baris).
	const sortedUsers = $derived(
		[...users].sort((a, b) => {
			if (sortMode === 'alphabet') return a.fullName.localeCompare(b.fullName, 'id');
			const rank = (u: PortalUser) => (u.isSelf ? 2 : u.isFollowing || u.isRequested ? 1 : 0);
			const diff = rank(a) - rank(b);
			return diff !== 0 ? diff : a.fullName.localeCompare(b.fullName, 'id');
		})
	);
</script>

<svelte:head><title>{title} — Portal SI</title></svelte:head>
<main class="connections surface">
	<header>
		<a href={backHref} aria-label="Kembali"><ArrowLeft size={19} /></a>
		<h1>{title}</h1>
	</header>
	{#if users.length > 1}
		<nav class="sort-bar" aria-label="Urutkan">
			<button class:active={sortMode === 'unfollowed'} onclick={() => (sortMode = 'unfollowed')}
				>Belum diikuti</button
			>
			<button class:active={sortMode === 'alphabet'} onclick={() => (sortMode = 'alphabet')}
				>A–Z</button
			>
		</nav>
	{/if}
	<div>
		{#each sortedUsers as user (user.id)}<div class="person">
				<StoryAvatarLink
					userId={user.id}
					username={user.username}
					name={user.fullName}
					avatarUrl={user.avatarUrl}
					size="md"
					hasStory={user.hasStory}
					seen={user.storyViewed}
				/><a href={`/u/${user.username}`}
					><span
						><strong
							>{user.fullName}<UserBadges verified={user.badgeVerified} role={user.role} /></strong
						><small>@{user.username}</small></span
					></a
				>
				<FollowButton {user} size="sm" />
			</div>{/each}{#if users.length === 0}<p>Belum ada pengguna di daftar ini.</p>{/if}
	</div>
</main>

<style>
	.connections {
		width: min(100% - 32px, 580px);
		min-height: 520px;
		margin: 28px auto;
		overflow: hidden;
	}
	header {
		display: flex;
		min-height: 64px;
		align-items: center;
		gap: 10px;
		padding: 0 14px;
		border-bottom: 1px solid var(--color-border);
	}
	header a {
		display: grid;
		width: 40px;
		height: 40px;
		place-items: center;
	}
	h1 {
		margin: 0;
		font-size: 1rem;
	}
	.sort-bar {
		display: flex;
		gap: 8px;
		padding: 11px 16px;
		border-bottom: 1px solid var(--color-border);
	}
	.sort-bar button {
		min-height: 30px;
		padding: 0 13px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 999px;
		color: var(--color-muted);
		font-size: 0.73rem;
		font-weight: 680;
		cursor: pointer;
	}
	.sort-bar button.active {
		background: var(--color-text);
		border-color: var(--color-text);
		color: white;
	}
	.connections > div > .person {
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 12px 16px;
		border-bottom: 1px solid var(--color-border);
	}
	.connections > div > .person:hover {
		background: var(--color-surface-soft);
	}
	.person > a:last-of-type {
		display: block;
		min-width: 0;
		flex: 1;
	}
	.person span {
		display: grid;
	}
	strong {
		display: flex;
		align-items: center;
		gap: 4px;
		font-size: 0.84rem;
	}
	small {
		color: var(--color-muted);
		font-size: 0.72rem;
	}
	.connections p {
		padding: 40px 20px;
		color: var(--color-muted);
		font-size: 0.78rem;
		text-align: center;
	}
	@media (max-width: 767px) {
		.connections {
			width: 100%;
			margin: 0;
			border: 0;
			border-radius: 0;
		}
	}
</style>
