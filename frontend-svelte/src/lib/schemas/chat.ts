import { z } from 'zod';

const booleanish = z.union([z.boolean(), z.literal(0), z.literal(1)]).transform(Boolean);

export const directPeerSchema = z.object({
	user_id: z.coerce.number().int().positive(),
	username: z.string().min(1),
	full_name: z.string().nullish(),
	profile_picture_url: z.string().nullish(),
	is_verified: booleanish.catch(false),
	role: z.enum(['student', 'parent', 'teacher', 'dev', 'other']).catch('other')
});

export const directChatListItemSchema = z.object({
	type: z.literal('user'),
	conversation: z.object({
		id: z.coerce.number().int().positive(),
		name: z.string().nullish(),
		username: z.string().nullish(),
		profile_picture_url: z.string().nullish(),
		is_verified: booleanish.catch(false)
	}),
	last_chat: z.object({
		content: z.string().nullish(),
		media: z.string().nullish(),
		sent_at: z.string().nullish(),
		is_read: booleanish.catch(false)
	})
});

export const groupChatListItemSchema = z.object({
	type: z.literal('group'),
	id: z.coerce.number().int().positive(),
	name: z.string().min(1),
	description: z.string().nullish(),
	avatar_url: z.string().nullish(),
	cover_url: z.string().nullish(),
	role: z.string(),
	is_muted: booleanish.catch(false),
	last_message: z.string().nullish(),
	last_media: z.string().nullish(),
	sent_at: z.string().nullish()
});

export const chatListSchema = z.array(
	z.discriminatedUnion('type', [directChatListItemSchema, groupChatListItemSchema])
);

export const directMessageSchema = z
	.object({
		message_id: z.coerce.number().int().positive(),
		sender_id: z.coerce.number().int().positive(),
		receiver_id: z.coerce.number().int().positive(),
		content: z.string().nullish(),
		media_url: z.string().nullish(),
		is_read: booleanish.catch(false),
		sent_at: z.string(),
		is_story_response: booleanish.catch(false),
		story_id: z.coerce.number().int().positive().nullish(),
		responded_media_url: z.string().nullish()
	})
	.passthrough();

export const directConversationSchema = z.array(directMessageSchema);
export const sentDirectMessageSchema = z.object({ message: z.string(), data: directMessageSchema });

export const groupSenderSchema = z.object({
	user_id: z.coerce.number().int().positive(),
	username: z.string().min(1),
	is_verified: booleanish.catch(false)
});

export const groupMessageSchema = z
	.object({
		id: z.coerce.number().int().positive(),
		sender: groupSenderSchema,
		content: z.string().nullish(),
		media_url: z.string().nullish(),
		is_pinned: booleanish.catch(false),
		is_edited: booleanish.catch(false),
		is_deleted: booleanish.catch(false),
		sent_at: z.string().nullish(),
		reply_to: z.unknown().nullable(),
		has_mention: booleanish.catch(false)
	})
	.passthrough();

export const groupMessagesResponseSchema = z.object({
	group_id: z.coerce.number().int().positive(),
	messages: z.array(groupMessageSchema)
});
export const sentGroupMessageSchema = z.object({ message: z.string(), data: groupMessageSchema });

export const groupDetailResponseSchema = z.object({
	group: z.object({
		id: z.coerce.number().int().positive(),
		name: z.string().min(1),
		description: z.string().nullish(),
		avatar_url: z.string().nullish(),
		cover_url: z.string().nullish(),
		owner: groupSenderSchema
	}),
	members: z.array(groupSenderSchema.extend({ role: z.string() }))
});

export const groupRoleResponseSchema = z.object({
	status: z.literal('success'),
	group_id: z.coerce.number().int().positive(),
	user_id: z.coerce.number().int().positive(),
	role: z.enum(['admin', 'member'])
});

export const groupMemberSchema = z
	.object({
		user_id: z.coerce.number().int().positive(),
		full_name: z.string().nullish(),
		username: z.string().min(1),
		profile_picture_url: z.string().nullish(),
		role: z.enum(['admin', 'member']),
		joined_at: z.string().nullish(),
		is_muted: booleanish.catch(false),
		is_verified: booleanish.catch(false),
		is_online: booleanish.catch(false),
		last_seen: z.string().nullish(),
		is_following: booleanish.catch(false)
	})
	.passthrough();

export const groupMembersResponseSchema = z.object({
	me: z.array(groupMemberSchema),
	following: z.array(groupMemberSchema),
	not_following: z.array(groupMemberSchema)
});

export const createdGroupResponseSchema = z.object({
	message: z.string(),
	group: z.object({ id: z.coerce.number().int().positive() }).passthrough()
});

export const specialGroupSchema = z.object({
	id: z.coerce.number().int().positive(),
	name: z.string().min(1),
	description: z.string().nullish(),
	avatar_url: z.string().nullish(),
	unread_message_count: z.coerce.number().int().nonnegative()
});

export const specialGroupsSchema = z.array(specialGroupSchema);
