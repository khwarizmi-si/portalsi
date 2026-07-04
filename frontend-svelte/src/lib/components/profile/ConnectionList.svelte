<script lang="ts">
	import { ArrowLeft } from '@lucide/svelte';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import VerifiedBadge from '$lib/components/ui/VerifiedBadge.svelte';
	import type { PortalUser } from '$lib/types/domain';
	let { title, backHref, users }: { title: string; backHref: string; users: PortalUser[] } =
		$props();
</script>

<svelte:head><title>{title} — Portal SI</title></svelte:head>
<main class="connections surface">
	<header>
		<a href={backHref} aria-label="Kembali"><ArrowLeft size={19} /></a>
		<h1>{title}</h1>
	</header>
	<div>
		{#each users as user (user.id)}<div class="person">
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
							>{user.fullName}{#if user.badgeVerified}<VerifiedBadge />{/if}</strong
						><small>@{user.username}</small></span
					></a
				>
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
	.person > a:last-child {
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
