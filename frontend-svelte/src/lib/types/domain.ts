export type UserRole = 'student' | 'parent' | 'teacher' | 'dev' | 'other';

export interface PortalUser {
	id: number;
	username: string;
	fullName: string;
	avatarUrl?: string;
	role: UserRole;
	badgeVerified: boolean;
	emailVerified: boolean;
	isPrivate: boolean;
	hasStory?: boolean;
	storyViewed?: boolean;
}

export interface StoryPreview {
	id: number;
	user: PortalUser;
	isOwn?: boolean;
}

export interface PostPreview {
	id: number;
	user: PortalUser;
	caption: string;
	mediaUrl: string;
	thumbnailUrl?: string;
	isVideo: boolean;
	mediaAlt: string;
	location?: string;
	createdLabel: string;
	likesCount: number;
	commentsCount: number;
	isLiked: boolean;
	isBookmarked: boolean;
	music?: { title: string; artist: string };
}

export interface AnnouncementPreview {
	id: number;
	title: string;
	content: string;
	createdLabel: string;
	pinned: boolean;
}

export interface NavItem {
	label: string;
	href: string;
	id: 'home' | 'explore' | 'create' | 'store' | 'profile' | 'messages' | 'notifications';
}
