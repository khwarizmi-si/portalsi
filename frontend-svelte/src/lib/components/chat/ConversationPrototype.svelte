<script lang="ts">
	import { env } from '$env/dynamic/public';
	import {
		ArrowLeft,
		CheckCheck,
		CornerDownRight,
		FileText,
		ImagePlus,
		Info,
		Pin,
		Send,
		Trash2,
		Users,
		X
	} from '@lucide/svelte';
	import { onMount, tick, untrack } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import { subscribePrivate } from '$lib/realtime/client';
	import {
		directConversationSchema,
		groupMessagesResponseSchema,
		sentDirectMessageSchema,
		sentGroupMessageSchema
	} from '$lib/schemas/chat';
	import { normalizeMediaUrl } from '$lib/utils/media';
	import { relativeTimeId } from '$lib/utils/time';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import { confirmAction } from '$lib/ui/confirm';
	import MentionText from '$lib/components/ui/MentionText.svelte';
	import MentionTextarea from '$lib/components/ui/MentionTextarea.svelte';

	type ChatMessage = {
		id: number;
		senderId: number;
		senderName: string;
		mine: boolean;
		text: string;
		mediaUrl: string | null;
		time: string;
		isRead: boolean;
		isPinned: boolean;
	};
	let {
		mode,
		targetId,
		title,
		subtitle,
		avatarUrl,
		currentUserId,
		messages: initialMessages,
		canPin = false
	}: {
		mode: 'direct' | 'group';
		targetId: number;
		title: string;
		subtitle: string;
		avatarUrl: string | null;
		currentUserId: number;
		messages: ChatMessage[];
		canPin?: boolean;
	} = $props();
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';
	let messages = $state(untrack(() => structuredClone(initialMessages)));
	let content = $state('');
	let media = $state<File | null>(null);
	let sending = $state(false);
	let statusMessage = $state('');
	let messagePane = $state<HTMLDivElement>();
	let realtimeConnected = $state(false);
	let replyingTo = $state<{ id: number; name: string } | null>(null);

	function mediaKind(url: string) {
		// Jangan pakai window.location di sini: fungsi ini dipanggil saat render (SSR),
		// dan `window` tidak ada di server → ReferenceError → halaman 500.
		const pathname = url.split(/[?#]/)[0].toLowerCase();
		if (/\.(jpg|jpeg|png|gif|webp)$/.test(pathname)) return 'image';
		if (/\.(mp4|mov|webm)$/.test(pathname)) return 'video';
		return 'file';
	}

	async function scrollToBottom(behavior: ScrollBehavior = 'smooth') {
		await tick();
		messagePane?.scrollTo({ top: messagePane.scrollHeight, behavior });
	}

	async function refresh() {
		try {
			const incoming: ChatMessage[] =
				mode === 'direct'
					? (
							await clientRequest(`messages/conversation/${targetId}`, {
								schema: directConversationSchema
							})
						).map((message) => ({
							id: message.message_id,
							senderId: message.sender_id,
							senderName: message.sender_id === currentUserId ? 'Anda' : title,
							mine: message.sender_id === currentUserId,
							text: message.content || '',
							mediaUrl: normalizeMediaUrl(message.media_url, mediaBaseUrl),
							time: relativeTimeId(message.sent_at),
							isRead: message.is_read,
							isPinned: false
						}))
					: (
							await clientRequest(`groups/${targetId}/messages`, {
								schema: groupMessagesResponseSchema
							})
						).messages.map((message) => ({
							id: message.id,
							senderId: message.sender.user_id,
							senderName: message.sender.username,
							mine: message.sender.user_id === currentUserId,
							text: message.content || '',
							mediaUrl: normalizeMediaUrl(message.media_url, mediaBaseUrl),
							time: message.sent_at ? relativeTimeId(message.sent_at) : '',
							isRead: false,
							isPinned: message.is_pinned
						}));
			const known = new Set(messages.map((message) => message.id));
			const additions = incoming.filter((message) => !known.has(message.id));
			if (additions.length) {
				messages.push(...additions);
				await scrollToBottom();
			}
		} catch {
			statusMessage = 'Pembaruan pesan tertunda; mencoba lagi otomatis.';
		}
	}

	onMount(() => {
		void scrollToBottom('auto');
		if (mode === 'direct')
			void clientRequest(`messages/user/${targetId}/read`, { method: 'PATCH' })
				.then(() => window.dispatchEvent(new Event('portal:messages-read')))
				.catch(() => undefined);
		else
			for (const message of messages)
				void clientRequest(`groups/${targetId}/messages/${message.id}/read`, {
					method: 'POST'
				}).catch(() => undefined);
		const channelName =
			mode === 'direct'
				? `dm.${[currentUserId, targetId].sort((a, b) => a - b).join('-')}`
				: `group.${targetId}`;
		const unsubscribe = subscribePrivate(
			channelName,
			mode === 'direct' ? 'dm.new' : 'group.new',
			() =>
				void refresh().then(() => {
					if (mode === 'direct')
						void clientRequest(`messages/user/${targetId}/read`, { method: 'PATCH' })
							.then(() => window.dispatchEvent(new Event('portal:messages-read')))
							.catch(() => undefined);
				}),
			(status) => {
				realtimeConnected = status === 'connected';
				if (status === 'connected') statusMessage = '';
			}
		);
		const timer = window.setInterval(() => {
			if (!realtimeConnected) void refresh();
		}, 12_000);
		return () => {
			unsubscribe();
			window.clearInterval(timer);
		};
	});

	function chooseMedia(candidate?: File) {
		if (!candidate) return;
		if (candidate.size > 50 * 1024 * 1024) {
			statusMessage = 'Lampiran maksimal 50 MB.';
			return;
		}
		if (!/^(image|video)\//.test(candidate.type) && candidate.type !== 'application/pdf') {
			statusMessage = 'Lampiran harus berupa gambar, video, atau PDF.';
			return;
		}
		media = candidate;
		statusMessage = '';
	}

	function composerKeydown(event: KeyboardEvent) {
		// Desktop: Enter mengirim, Shift+Enter baris baru. Di layar sentuh, Enter tetap baris baru.
		if (event.key !== 'Enter' || event.shiftKey) return;
		if (typeof window !== 'undefined' && window.matchMedia('(pointer: coarse)').matches) return;
		event.preventDefault();
		(event.currentTarget as HTMLFormElement).requestSubmit();
	}

	async function send(event: SubmitEvent) {
		event.preventDefault();
		if ((!content.trim() && !media) || sending) return;
		sending = true;
		statusMessage = '';
		const body = new FormData();
		if (content.trim()) body.set('content', content.trim());
		if (media) body.set('media', media);
		if (mode === 'group' && replyingTo) body.set('reply_to', String(replyingTo.id));
		try {
			let created: ChatMessage;
			if (mode === 'direct') {
				body.set('receiver_id', String(targetId));
				const response = await clientRequest('messages/send', {
					method: 'POST',
					body,
					schema: sentDirectMessageSchema
				});
				created = {
					id: response.data.message_id,
					senderId: currentUserId,
					senderName: 'Anda',
					mine: true,
					text: response.data.content || '',
					mediaUrl: normalizeMediaUrl(response.data.media_url, mediaBaseUrl),
					time: 'baru saja',
					isRead: false,
					isPinned: false
				};
			} else {
				const response = await clientRequest(`groups/${targetId}/messages`, {
					method: 'POST',
					body,
					schema: sentGroupMessageSchema
				});
				created = {
					id: response.data.id,
					senderId: currentUserId,
					senderName: response.data.sender.username,
					mine: true,
					text: response.data.content || '',
					mediaUrl: normalizeMediaUrl(response.data.media_url, mediaBaseUrl),
					time: 'baru saja',
					isRead: false,
					isPinned: response.data.is_pinned
				};
			}
			messages.push(created);
			content = '';
			media = null;
			replyingTo = null;
			await scrollToBottom();
		} catch (error) {
			statusMessage = error instanceof Error ? error.message : 'Pesan belum dapat dikirim.';
		} finally {
			sending = false;
		}
	}

	async function deleteMessage(message: ChatMessage) {
		if (
			!(await confirmAction({
				title: 'Hapus pesan ini?',
				description: 'Pesan akan dihapus dari percakapan Anda.',
				confirmLabel: 'Hapus pesan',
				tone: 'danger'
			}))
		)
			return;
		try {
			await clientRequest(
				mode === 'group' ? `groups/${targetId}/messages/${message.id}` : `messages/${message.id}`,
				{ method: 'DELETE' }
			);
			messages = messages.filter((item) => item.id !== message.id);
		} catch {
			statusMessage = 'Pesan belum dapat dihapus.';
		}
	}

	async function togglePin(message: ChatMessage) {
		const previous = message.isPinned;
		message.isPinned = !previous;
		try {
			await clientRequest(`groups/${targetId}/messages/${message.id}/pin`, { method: 'POST' });
		} catch {
			message.isPinned = previous;
			statusMessage = 'Pin pesan belum dapat diperbarui.';
		}
	}
</script>

<svelte:head
	><title>{title} — Pesan Portal SI</title><meta name="robots" content="noindex" /></svelte:head
>

<div class="conversation-page surface">
	<header>
		<a href="/messages" aria-label="Kembali ke inbox"><ArrowLeft size={20} /></a>
		{#if mode === 'group' && !avatarUrl}<span class="group-avatar"><Users size={20} /></span
			>{:else}<Avatar name={title} src={avatarUrl ?? undefined} size="md" />{/if}
		<div>
			<h1>{title}</h1>
			<p>{subtitle}</p>
		</div>
		{#if mode === 'group'}<a
				class="info-link"
				href={`/groups/${targetId}/info`}
				aria-label="Info grup"><Info size={19} /></a
			>{/if}
	</header>
	<div class="messages" bind:this={messagePane} aria-label={`Percakapan dengan ${title}`}>
		<div class="date">Percakapan</div>
		{#each messages as message (message.id)}
			<article class:mine={message.mine}>
				{#if !message.mine && mode === 'group'}<Avatar name={message.senderName} size="sm" />{/if}
				<div>
					{#if !message.mine && mode === 'group'}<strong>{message.senderName}</strong>{/if}
					{#if message.isPinned}<span class="pinned"><Pin size={11} /> Disematkan</span>{/if}
					{#if message.text}<p><MentionText text={message.text} /></p>{/if}
					{#if message.mediaUrl}
						{#if mediaKind(message.mediaUrl) === 'image'}<a
								href={message.mediaUrl}
								target="_blank"
								rel="noreferrer"><img src={message.mediaUrl} alt="Lampiran gambar" /></a
							>
						{:else if mediaKind(message.mediaUrl) === 'video'}<video
								src={message.mediaUrl}
								controls
								preload="metadata"><track kind="captions" label="Takarir tidak tersedia" /></video
							>
						{:else}<a class="file" href={message.mediaUrl} target="_blank" rel="noreferrer"
								><FileText size={18} /> Buka lampiran</a
							>{/if}
					{/if}
					<small
						>{message.time}{#if message.mine}<CheckCheck
								size={13}
								class={message.isRead ? 'read' : undefined}
							/>{/if}</small
					>
					<div class="message-tools">
						{#if mode === 'group'}<button
								onclick={() => (replyingTo = { id: message.id, name: message.senderName })}
								><CornerDownRight size={12} /> Balas</button
							>{/if}
						{#if mode === 'group' && canPin}<button onclick={() => togglePin(message)}
								><Pin size={12} /> {message.isPinned ? 'Lepas pin' : 'Pin'}</button
							>{/if}
						{#if message.mine}<button onclick={() => deleteMessage(message)}
								><Trash2 size={12} /> Hapus</button
							>{/if}
					</div>
				</div>
			</article>
		{/each}
		{#if messages.length === 0}<p class="empty">
				Belum ada pesan. Mulai percakapan dengan sapaan.
			</p>{/if}
	</div>
	{#if replyingTo}<div class="attachment replying">
			<span>Membalas {replyingTo.name}</span><button
				onclick={() => (replyingTo = null)}
				aria-label="Batal membalas"><X size={15} /></button
			>
		</div>{/if}
	{#if media}<div class="attachment">
			<span>{media.name}</span><button onclick={() => (media = null)} aria-label="Hapus lampiran"
				><X size={15} /></button
			>
		</div>{/if}
	<form class="composer" onsubmit={send} onkeydown={composerKeydown}>
		<label class="media-button" aria-label="Pilih media"
			><ImagePlus size={20} /><input
				type="file"
				accept="image/*,video/*,application/pdf"
				onchange={(event) => chooseMedia(event.currentTarget.files?.[0])}
			/></label
		>
		<label
			><span class="sr-only">Tulis pesan</span><MentionTextarea
				bind:value={content}
				name="content"
				maxlength={5000}
				rows={1}
				placeholder="Tulis pesan…"
			/></label
		>
		<button
			type="submit"
			class="send"
			aria-label="Kirim pesan"
			disabled={(!content.trim() && !media) || sending}><Send size={19} /></button
		>
	</form>
	{#if statusMessage}<p class="status" aria-live="polite">{statusMessage}</p>{/if}
</div>

<style>
	.conversation-page {
		display: grid;
		width: min(100% - 32px, 900px);
		height: calc(100vh - 40px);
		grid-template-rows: auto 1fr auto auto auto;
		margin: 20px auto;
		overflow: hidden;
	}
	@media (max-width: 767px) {
		.conversation-page {
			width: 100%;
			height: 100dvh;
			margin: 0;
			border-radius: 0;
		}
	}
	.conversation-page > header {
		display: flex;
		min-height: 68px;
		align-items: center;
		gap: 9px;
		padding: 9px 14px;
		border-bottom: 1px solid var(--color-border);
	}
	header > a:first-child {
		display: grid;
		width: 40px;
		height: 40px;
		place-items: center;
		border-radius: 50%;
	}
	header > div {
		display: grid;
		min-width: 0;
		margin-right: auto;
	}
	.info-link {
		display: grid;
		width: 40px;
		height: 40px;
		place-items: center;
		border-radius: 50%;
		color: var(--color-muted);
	}
	header h1 {
		margin: 0;
		font-size: 0.9rem;
	}
	header p {
		margin: 0;
		color: var(--color-muted);
		font-size: 0.68rem;
	}
	.group-avatar {
		display: grid;
		width: 44px;
		height: 44px;
		place-items: center;
		background: var(--color-secondary-soft);
		border-radius: 50%;
		color: var(--color-secondary);
	}
	.messages {
		display: flex;
		min-height: 0;
		flex-direction: column;
		gap: 9px;
		overflow-y: auto;
		padding: 20px;
		background:
			linear-gradient(rgb(255 253 248 / 92%), rgb(255 250 240 / 92%)),
			url('/assets/images/background.png') center/cover;
	}
	.date {
		align-self: center;
		padding: 4px 9px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 99px;
		color: var(--color-muted);
		font-size: 0.65rem;
	}
	.messages article {
		display: flex;
		max-width: 72%;
		align-items: end;
		gap: 7px;
	}
	.messages article.mine {
		align-self: flex-end;
	}
	.messages article > div {
		min-width: 80px;
		padding: 9px 11px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 14px 14px 14px 4px;
		box-shadow: var(--shadow-xs);
	}
	.messages article.mine > div {
		background: var(--color-primary);
		border-color: var(--color-primary);
		border-radius: 14px 14px 4px;
		color: white;
	}
	.messages p {
		margin: 0;
		font-size: 0.82rem;
		white-space: pre-wrap;
		overflow-wrap: anywhere;
	}
	.messages strong {
		display: block;
		margin-bottom: 3px;
		color: var(--color-secondary);
		font-size: 0.67rem;
	}
	.messages small {
		display: flex;
		align-items: center;
		justify-content: flex-end;
		gap: 3px;
		margin-top: 4px;
		color: var(--color-muted);
		font-size: 0.6rem;
	}
	.messages article.mine small {
		color: rgb(255 255 255 / 75%);
	}
	.message-tools {
		display: flex;
		gap: 8px;
		margin-top: 5px;
	}
	.message-tools button {
		display: flex;
		width: auto;
		height: auto;
		align-items: center;
		gap: 3px;
		padding: 0;
		background: transparent;
		border: 0;
		border-radius: 0;
		color: inherit;
		font-size: 0.58rem;
		opacity: 0.72;
	}
	.messages img,
	.messages video {
		width: min(100%, 280px);
		max-height: 300px;
		margin-top: 6px;
		border-radius: 9px;
		object-fit: cover;
	}
	.file,
	.pinned {
		display: flex;
		align-items: center;
		gap: 5px;
	}
	.file {
		margin-top: 6px;
		font-size: 0.72rem;
		text-decoration: underline;
	}
	.pinned {
		margin-bottom: 4px;
		font-size: 0.62rem;
		opacity: 0.8;
	}
	.empty {
		align-self: center;
		margin: auto;
		color: var(--color-muted);
		font-size: 0.78rem;
	}
	.attachment {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 8px 14px;
		background: var(--color-primary-soft);
		color: var(--color-primary-strong);
		font-size: 0.72rem;
	}
	.attachment button {
		display: grid;
		place-items: center;
		background: transparent;
		border: 0;
	}
	.attachment.replying {
		background: var(--color-secondary-soft);
		color: var(--color-secondary);
	}
	.composer {
		display: grid;
		grid-template-columns: auto 1fr auto;
		align-items: end;
		gap: 6px;
		padding: 10px 12px;
		border-top: 1px solid var(--color-border);
	}
	.media-button,
	.composer > button {
		display: grid;
		width: 42px;
		height: 42px;
		place-items: center;
		background: transparent;
		border: 0;
		border-radius: 12px;
		color: var(--color-muted);
	}
	.media-button input {
		position: absolute;
		width: 1px;
		height: 1px;
		opacity: 0;
	}
	.composer :global(.mention-field textarea) {
		width: 100%;
		height: 42px;
		max-height: 100px;
		padding: 10px 12px;
		resize: none;
		background: var(--color-surface-soft);
		border: 1px solid var(--color-border);
		border-radius: 12px;
	}
	.composer .send {
		background: var(--color-primary);
		color: white;
	}
	.composer .send:disabled {
		opacity: 0.45;
	}
	.status {
		margin: 0;
		padding: 7px 12px;
		color: var(--color-primary-strong);
		font-size: 0.68rem;
		text-align: center;
	}
	@media (max-width: 767px) {
		.conversation-page {
			width: 100%;
			height: calc(100vh - 132px);
			margin: 0;
			border: 0;
			border-radius: 0;
		}
		.messages article {
			max-width: 86%;
		}
	}
</style>
