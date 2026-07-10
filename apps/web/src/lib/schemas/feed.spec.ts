import { describe, expect, it } from 'vitest';
import { feedResponseSchema, suggestionsResponseSchema } from './post';
import { storyFeedResponseSchema } from './story';

const compactUser = {
	user_id: 7,
	username: 'aisyah',
	full_name: 'Aisyah Putri',
	profile_picture_url: 'avatars/aisyah.jpg',
	role: 'student',
	is_verified: 1,
	is_private: 0
};

describe('feed contracts', () => {
	it('accepts the mixed post and suggestion feed emitted by Laravel', () => {
		const parsed = feedResponseSchema.parse({
			current_page: 1,
			per_page: 2,
			total: 3,
			next_page_url: 'https://api.portalsi.com/api/posts?page=2',
			prev_page_url: null,
			last_page_url: 'https://api.portalsi.com/api/posts?page=2',
			feed: [
				{
					type: 'post',
					post_id: 12,
					caption: 'Belajar bersama',
					media_url: 'posts/12.jpg',
					thumbnail_url: null,
					location: null,
					is_video: false,
					created_at: '2026-07-03T01:00:00Z',
					likes_count: 4,
					comments_count: 2,
					is_liked: 0,
					is_bookmarked: 1,
					music_track_name: null,
					music_artist_name: null,
					user: compactUser
				},
				{ type: 'suggestion', users: [{ ...compactUser, role: undefined }] }
			]
		});

		expect(parsed.feed[0].type).toBe('post');
		const suggestion = parsed.feed[1];
		expect(suggestion.type).toBe('suggestion');
		if (suggestion.type !== 'suggestion') throw new Error('Expected a suggestion feed entry.');
		expect(suggestion.users[0].role).toBe('other');
	});

	it('accepts the smaller standalone suggestions projection', () => {
		const parsed = suggestionsResponseSchema.parse({
			count: 1,
			users: [{ user_id: 9, username: 'hana', is_verified: false }]
		});
		expect(parsed.users[0]).toMatchObject({ role: 'other', is_private: false });
	});
});

describe('story contracts', () => {
	it('parses grouped stories and coerces database booleans', () => {
		const parsed = storyFeedResponseSchema.parse({
			stories: [
				{
					user_id: 7,
					username: 'aisyah',
					profile_picture_url: null,
					is_viewed: 0,
					stories: [
						{
							story_id: 32,
							type: 'image',
							media_url: 'stories/32.jpg',
							caption: null,
							created_at: '2026-07-03T01:00:00Z',
							expires_at: '2026-07-04T01:00:00Z',
							is_viewed: 1
						}
					]
				}
			],
			suggestions: []
		});

		expect(parsed.stories[0].is_viewed).toBe(false);
		expect(parsed.stories[0].stories[0].is_viewed).toBe(true);
	});
});
