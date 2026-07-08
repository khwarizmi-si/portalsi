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
	isFollowing?: boolean;
	isRequested?: boolean;
	isSelf?: boolean;
}

export interface StoryPreview {
	id: number;
	user: PortalUser;
	isOwn?: boolean;
	recommended?: boolean;
}

export interface PostPreview {
	id: number;
	user: PortalUser;
	caption: string;
	mediaUrl: string;
	media?: string[];
	thumbnailUrl?: string;
	isVideo: boolean;
	mediaAlt: string;
	location?: string;
	createdLabel: string;
	likesCount: number;
	commentsCount: number;
	isLiked: boolean;
	isBookmarked: boolean;
	music?: {
		title: string;
		artist: string;
		previewUrl?: string;
		startSeconds: number;
		durationSeconds: number;
	};
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
