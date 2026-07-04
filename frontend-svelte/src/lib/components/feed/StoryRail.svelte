<script lang="ts">
	import { Plus } from '@lucide/svelte';
	import StoryAvatarLink from '$lib/components/story/StoryAvatarLink.svelte';
	import type { StoryPreview } from '$lib/types/domain';
	let { stories }: { stories: StoryPreview[] } = $props();
</script>

<section class="story-section" aria-labelledby="story-title">
	<div class="section-title">
		<h2 id="story-title">Cerita hari ini</h2>
		<a href="/create/story">Buat cerita</a>
	</div>
	<div class="story-rail">
		{#each stories as story (story.id)}
			<div class="story-card">
				<span class="avatar-place">
					<StoryAvatarLink
						userId={story.user.id}
						username={story.user.username}
						name={story.user.fullName}
						avatarUrl={story.user.avatarUrl}
						size="lg"
						hasStory={story.user.hasStory}
						seen={story.user.storyViewed}
						profileHref={story.isOwn ? '/create/story' : `/u/${story.user.username}`}
					/>
					{#if story.isOwn && !story.user.hasStory}<a href="/create/story" aria-label="Buat cerita"
							><i><Plus size={13} strokeWidth={3} /></i></a
						>{/if}
				</span>
				<span>{story.isOwn ? 'Cerita Anda' : story.user.fullName.split(' ')[0]}</span>
			</div>
		{/each}
	</div>
</section>

<style>
	.story-section {
		min-width: 0;
		width: 100%;
		padding: 16px 16px 13px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-xs);
	}

	.section-title {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: 12px;
	}

	.section-title h2 {
		margin: 0;
		font-size: 0.96rem;
	}

	.section-title a {
		color: var(--color-primary-strong);
		font-size: 0.79rem;
		font-weight: 700;
	}

	.story-rail {
		display: flex;
		gap: 17px;
		overflow-x: auto;
		padding: 2px 1px 5px;
		scrollbar-width: none;
	}

	.story-rail::-webkit-scrollbar {
		display: none;
	}

	.story-card {
		display: grid;
		min-width: 64px;
		place-items: center;
		gap: 6px;
		font-size: 0.72rem;
		font-weight: 620;
	}

	.avatar-place {
		position: relative;
	}

	.avatar-place i {
		position: absolute;
		right: -1px;
		bottom: 0;
		display: grid;
		width: 20px;
		height: 20px;
		place-items: center;
		background: var(--color-primary);
		border: 2px solid white;
		border-radius: 50%;
		color: white;
	}

	@media (max-width: 767px) {
		.story-section {
			border-inline: 0;
			border-radius: 0;
		}
	}
</style>
