import { describe, expect, it } from 'vitest';
import { mapAnnouncement, mapPost, mapStoryGroups } from './mappers';

const sessionUser = {
	id: 1,
	username: 'naila',
	fullName: 'Naila Hasanah',
	email: 'naila@example.com',
	bio: null,
	avatarUrl: null,
	bannerUrl: null,
	role: 'student' as const,
	badgeVerified: false,
	emailVerified: true,
	isPrivate: false
};

describe('API view-model mappers', () => {
	it('normalizes post media and preserves interaction state', () => {
		const post = mapPost(
			{
				type: 'post',
				post_id: 4,
				caption: 'Catatan pagi',
				media_url: 'storage/posts/four.jpg',
				thumbnail_url: null,
				location: null,
				is_video: false,
				created_at: '2026-07-03T00:00:00Z',
				likes_count: 3,
				comments_count: 1,
				is_liked: true,
				is_bookmarked: false,
				music_track_name: null,
				music_artist_name: null,
				user: {
					user_id: 2,
					username: 'hana',
					full_name: 'Hana',
					profile_picture_url: 'avatars/hana.jpg',
					role: 'student',
					is_verified: false,
					is_private: false,
					has_story: true,
					story_viewed: false
				}
			},
			'https://cdn.example.com/storage'
		);

		expect(post.mediaUrl).toBe('https://cdn.example.com/storage/posts/four.jpg');
		expect(post.user.avatarUrl).toBe('https://cdn.example.com/storage/avatars/hana.jpg');
		expect(post.isLiked).toBe(true);
	});

	it('always puts the current user first in the story rail', () => {
		const stories = mapStoryGroups(
			{
				stories: [
					{
						user_id: 2,
						username: 'hana',
						profile_picture_url: null,
						is_viewed: false,
						stories: [
							{
								story_id: 9,
								type: 'image',
								media_url: null,
								caption: null,
								created_at: '2026-07-03T00:00:00Z',
								expires_at: '2026-07-04T00:00:00Z',
								is_viewed: false
							}
						]
					}
				],
				suggestions: []
			},
			sessionUser,
			'https://cdn.example.com/storage'
		);

		expect(stories[0]).toMatchObject({ id: 0, isOwn: true });
		expect(stories[1]).toMatchObject({ id: 9, user: { username: 'hana' } });
	});

	it('uses safe announcement fallbacks', () => {
		expect(
			mapAnnouncement({
				id: 3,
				title: null,
				content: null,
				created_at: '2026-07-03T00:00:00Z',
				pinned: true
			})
		).toMatchObject({ title: 'Pengumuman Portal SI', pinned: true });
	});
});
