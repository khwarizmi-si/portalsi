<script lang="ts">
	import { CornerDownRight, Heart, Pencil, Send, Trash2, Users, X } from '@lucide/svelte';
	import { untrack } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import PostCard from '$lib/components/feed/PostCard.svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import UserBadges from '$lib/components/ui/UserBadges.svelte';
	import { createdCommentResponseSchema } from '$lib/schemas/comment';
	import type { PageProps } from './$types';
	import { confirmAction, confirmButtonAction } from '$lib/ui/confirm';
	import MentionText from '$lib/components/ui/MentionText.svelte';
	import MentionTextarea from '$lib/components/ui/MentionTextarea.svelte';
	import GifPicker from '$lib/components/comment/GifPicker.svelte';

	let { data, form }: PageProps = $props();
	let comments = $state(untrack(() => structuredClone(data.comments)));
	let content = $state('');
	let replyTo = $state<{ id: number; name: string } | null>(null);
	let submitting = $state(false);
	let formMessage = $state('');
	let commentCount = $state(untrack(() => data.post.commentsCount));
	let gifOpen = $state(false);

	async function sendComment(gifUrl: string | null = null) {
		const text = content.trim();
		if ((!text && !gifUrl) || submitting) return;
		submitting = true;
		formMessage = '';
		try {
			const response = await clientRequest(`posts/${data.post.id}/comments`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					content: text,
					gif_url: gifUrl,
					parent_comment_id: replyTo?.id ?? null
				}),
				schema: createdCommentResponseSchema
			});
			const created = {
				id: response.data.comment_id,
				user: data.currentUser,
				text: response.data.content,
				gifUrl: response.data.gif_url ?? gifUrl ?? null,
				createdLabel: 'baru saja',
				likesCount: 0,
				isLiked: false,
				parentId: response.data.parent_comment_id
			};
			if (replyTo) {
				const parent = comments.find((comment) => comment.id === replyTo?.id);
				parent?.replies.push(created);
			} else comments.unshift({ ...created, parentId: null, replies: [] });
			content = '';
			replyTo = null;
			commentCount += 1;
			formMessage = gifUrl ? 'GIF terkirim.' : 'Komentar terkirim.';
		} catch {
			formMessage = 'Komentar belum dapat dikirim.';
		} finally {
			submitting = false;
		}
	}

	function submitComment(event?: SubmitEvent) {
		event?.preventDefault();
		void sendComment(null);
	}

	function pickGif(url: string) {
		gifOpen = false;
		void sendComment(url);
	}

	async function toggleCommentLike(id: number, reply = false) {
		const item = reply
			? comments.flatMap((comment) => comment.replies).find((entry) => entry.id === id)
			: comments.find((entry) => entry.id === id);
		if (!item) return;
		const wasLiked = item.isLiked;
		item.isLiked = !wasLiked;
		item.likesCount += wasLiked ? -1 : 1;
		try {
			await clientRequest(`comments/${id}/like`, { method: wasLiked ? 'DELETE' : 'POST' });
		} catch {
			item.isLiked = wasLiked;
			item.likesCount += wasLiked ? 1 : -1;
			formMessage = 'Like komentar belum tersimpan.';
		}
	}

	async function editComment(id: number, reply = false) {
		const item = reply
			? comments.flatMap((comment) => comment.replies).find((entry) => entry.id === id)
			: comments.find((entry) => entry.id === id);
		if (!item) return;
		const text = window.prompt('Edit komentar', item.text)?.trim();
		if (!text || text === item.text) return;
		try {
			await clientRequest(`comments/${id}`, {
				method: 'PUT',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ content: text })
			});
			item.text = text;
		} catch {
			formMessage = 'Komentar belum dapat diedit.';
		}
	}

	async function deleteComment(id: number, reply = false) {
		if (
			!(await confirmAction({
				title: 'Hapus komentar?',
				description: 'Komentar ini akan dihapus dari percakapan.',
				confirmLabel: 'Hapus komentar',
				tone: 'danger'
			}))
		)
			return;
		try {
			await clientRequest(`comments/${id}`, { method: 'DELETE' });
			if (reply) {
				for (const comment of comments)
					comment.replies = comment.replies.filter((entry) => entry.id !== id);
			} else comments = comments.filter((entry) => entry.id !== id);
			commentCount = Math.max(0, commentCount - 1);
		} catch {
			formMessage = 'Komentar belum dapat dihapus.';
		}
	}
</script>

<svelte:head
	><title>Postingan — Portal SI</title><meta name="robots" content="noindex" /></svelte:head
>

<SectionPage eyebrow="Diskusi" title="Detail postingan">
	<div class="post-detail-layout">
		<div class="post-column">
			{#if data.post.user.id === data.currentUser.id}<details class="owner-tools surface">
					<summary><Pencil size={15} /> Kelola postingan</summary>
					<form method="POST" action="?/update">
						<label>Caption <textarea name="caption" rows="4">{data.post.caption}</textarea></label
						><small
							>Media, musik, dan lokasi tidak dapat diganti setelah postingan diterbitkan.</small
						>
						<div>
							<button type="submit">Simpan</button><button
								class="delete"
								type="submit"
								formaction="?/delete"
								onclick={(event) =>
									confirmButtonAction(event, {
										title: 'Hapus postingan?',
										description:
											'Foto atau video, komentar, dan interaksi pada postingan ini akan dihapus permanen.',
										confirmLabel: 'Hapus postingan',
										tone: 'danger'
									})}><Trash2 size={14} /> Hapus</button
							>
						</div>
					</form>
				</details>{/if}
			{#if form?.message}<p class:success={form.success} class="notice" role="status">
					{form.message}
				</p>{/if}
			<PostCard post={data.post} zoomable autoplay />
			<details class="likers surface">
				<summary
					><Users size={16} /> {data.likers.length.toLocaleString('id-ID')} orang menyukai</summary
				>
				<div>
					{#each data.likers as user (user.id)}<a href={`/u/${user.username}`}
							><Avatar name={user.fullName} src={user.avatarUrl} size="sm" /><span
								><strong
									>{user.fullName}<UserBadges
										verified={user.badgeVerified}
										role={user.role}
									/></strong
								><small>@{user.username}{user.isFollowing ? ' · Diikuti' : ''}</small></span
							></a
						>{/each}{#if data.likers.length === 0}<p>Belum ada yang menyukai.</p>{/if}
				</div>
			</details>
		</div>
		<section class="comments surface" id="comments">
			<header>
				<h2>Komentar</h2>
				<span>{commentCount}</span>
			</header>
			<div class="comment-list">
				{#each comments as comment (comment.id)}
					<article>
						<Avatar name={comment.user.fullName} src={comment.user.avatarUrl} size="sm" />
						<div>
							<p>
								<strong
									>{comment.user.fullName}<UserBadges
										verified={comment.user.badgeVerified}
										role={comment.user.role}
									/></strong
								>
								{#if !comment.gifUrl}<MentionText text={comment.text} />{/if}
							</p>
							{#if comment.gifUrl}<img
									class="comment-gif"
									src={comment.gifUrl}
									alt="Komentar GIF"
									loading="lazy"
								/>{/if}
							<footer>
								<time>{comment.createdLabel}</time><button
									class:active={comment.isLiked}
									onclick={() => toggleCommentLike(comment.id)}
									><Heart size={13} fill={comment.isLiked ? 'currentColor' : 'none'} />
									{comment.likesCount}</button
								><button onclick={() => (replyTo = { id: comment.id, name: comment.user.fullName })}
									>Balas</button
								>
								{#if comment.user.id === data.currentUser.id}<button
										onclick={() => editComment(comment.id)}>Edit</button
									><button onclick={() => deleteComment(comment.id)}>Hapus</button>{/if}
							</footer>
							{#each comment.replies as reply (reply.id)}
								<div class="reply">
									<CornerDownRight size={15} class="reply-arrow" /><Avatar
										name={reply.user.fullName}
										src={reply.user.avatarUrl}
										size="sm"
									/>
									<div>
										<p>
											<strong
												>{reply.user.fullName}<UserBadges
													verified={reply.user.badgeVerified}
													role={reply.user.role}
												/></strong
											>
											{#if !reply.gifUrl}<MentionText text={reply.text} />{/if}
										</p>
										{#if reply.gifUrl}<img
												class="comment-gif"
												src={reply.gifUrl}
												alt="Balasan GIF"
												loading="lazy"
											/>{/if}
										<footer>
											<time>{reply.createdLabel}</time><button
												class:active={reply.isLiked}
												onclick={() => toggleCommentLike(reply.id, true)}
												><Heart size={13} fill={reply.isLiked ? 'currentColor' : 'none'} />
												{reply.likesCount}</button
											>
											{#if reply.user.id === data.currentUser.id}<button
													onclick={() => editComment(reply.id, true)}>Edit</button
												><button onclick={() => deleteComment(reply.id, true)}>Hapus</button>{/if}
										</footer>
									</div>
								</div>
							{/each}
						</div>
					</article>
				{/each}
				{#if comments.length === 0}<p class="empty">Jadilah yang pertama berkomentar.</p>{/if}
			</div>
			{#if replyTo}<div class="replying">
					Membalas {replyTo.name}<button
						onclick={() => (replyTo = null)}
						aria-label="Batal membalas"><X size={14} /></button
					>
				</div>{/if}
			<form class="comment-form" onsubmit={submitComment}>
				<Avatar name={data.currentUser.fullName} src={data.currentUser.avatarUrl} size="sm" />
				<label
					><span class="sr-only">Tulis komentar</span><MentionTextarea
						bind:value={content}
						name="comment"
						maxlength={2000}
						rows={1}
						placeholder={replyTo ? 'Tulis balasan…' : 'Tulis komentar…'}
						onEnter={() => submitComment()}
					/></label
				>
				<button
					type="button"
					class="gif-btn"
					onclick={() => (gifOpen = true)}
					disabled={submitting}
					aria-label="Kirim GIF">GIF</button
				>
				<button type="submit" aria-label="Kirim komentar" disabled={!content.trim() || submitting}
					><Send size={18} /></button
				>
			</form>
			{#if formMessage}<p class="form-message" aria-live="polite">{formMessage}</p>{/if}
			{#if gifOpen}<GifPicker onSelect={pickGif} onClose={() => (gifOpen = false)} />{/if}
		</section>
	</div>
</SectionPage>

<style>
	.post-column {
		display: grid;
		gap: 12px;
	}
	.owner-tools,
	.likers {
		padding: 14px 16px;
	}
	.owner-tools summary,
	.likers summary {
		display: flex;
		width: fit-content;
		cursor: pointer;
		align-items: center;
		gap: 7px;
		font-size: 0.76rem;
		font-weight: 730;
	}
	.owner-tools form {
		display: grid;
		gap: 10px;
		margin-top: 14px;
	}
	.owner-tools label {
		display: grid;
		gap: 5px;
		color: var(--color-muted);
		font-size: 0.7rem;
		font-weight: 680;
	}
	.owner-tools form > small {
		color: var(--color-muted);
		font-size: 0.68rem;
	}
	.owner-tools textarea {
		width: 100%;
		padding: 9px 10px;
		background: var(--color-canvas);
		border: 1px solid var(--color-border);
		border-radius: 9px;
		outline: 0;
	}
	.owner-tools form > div {
		display: flex;
		gap: 7px;
	}
	.owner-tools button {
		display: flex;
		min-height: 38px;
		align-items: center;
		gap: 5px;
		padding: 0 13px;
		background: var(--color-primary);
		border: 0;
		border-radius: 9px;
		color: white;
		font-size: 0.72rem;
		font-weight: 720;
	}
	.owner-tools button.delete {
		background: var(--color-danger);
	}
	.notice {
		margin: 0;
		padding: 9px 11px;
		background: var(--color-danger-soft);
		border-radius: 9px;
		color: var(--color-danger);
		font-size: 0.72rem;
	}
	.notice.success {
		background: var(--color-secondary-soft);
		color: var(--color-secondary);
	}
	.likers > div {
		display: grid;
		max-height: 260px;
		margin-top: 10px;
		overflow-y: auto;
	}
	.likers a {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 8px 0;
		border-top: 1px solid var(--color-border);
	}
	.likers a span {
		display: grid;
	}
	.likers strong {
		font-size: 0.74rem;
	}
	.likers small,
	.likers p {
		color: var(--color-muted);
		font-size: 0.66rem;
	}
	.post-detail-layout {
		display: grid;
		grid-template-columns: minmax(0, 620px) minmax(300px, 1fr);
		gap: 18px;
		align-items: start;
	}
	.comments {
		position: sticky;
		top: 20px;
		overflow: hidden;
	}
	.comments > header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 15px 17px;
		border-bottom: 1px solid var(--color-border);
	}
	.comments h2 {
		margin: 0;
		font-size: 0.94rem;
	}
	.comments > header span {
		display: grid;
		min-width: 25px;
		height: 25px;
		place-items: center;
		background: var(--color-primary-soft);
		border-radius: 99px;
		color: var(--color-primary-strong);
		font-size: 0.7rem;
		font-weight: 720;
	}
	.comment-list {
		max-height: 600px;
		overflow: auto;
	}
	.comment-list > article {
		display: grid;
		grid-template-columns: auto 1fr;
		gap: 9px;
		padding: 14px 15px;
		border-bottom: 1px solid var(--color-border);
	}
	article p {
		margin: 0;
		font-size: 0.8rem;
		overflow-wrap: anywhere;
	}
	article footer {
		display: flex;
		align-items: center;
		gap: 12px;
		margin-top: 6px;
		color: var(--color-muted);
		font-size: 0.66rem;
	}
	article footer button {
		display: flex;
		align-items: center;
		gap: 4px;
		padding: 0;
		background: transparent;
		border: 0;
		color: inherit;
		font-size: inherit;
		cursor: pointer;
	}
	article footer button.active {
		color: var(--color-primary-strong);
	}
	.reply {
		display: grid;
		grid-template-columns: auto auto 1fr;
		gap: 7px;
		margin-top: 13px;
		color: var(--color-muted);
	}
	:global(.reply-arrow) {
		margin-top: 8px;
	}
	.reply p {
		color: var(--color-text);
	}
	.replying {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 8px 14px;
		background: var(--color-primary-soft);
		color: var(--color-primary-strong);
		font-size: 0.72rem;
	}
	.replying button {
		display: grid;
		place-items: center;
		padding: 3px;
		background: transparent;
		border: 0;
	}
	.comment-form {
		display: grid;
		grid-template-columns: auto minmax(0, 1fr) auto auto;
		align-items: center;
		gap: 8px;
		padding: 12px;
		border-top: 1px solid var(--color-border);
	}
	.comment-form label {
		display: block;
		min-width: 0;
	}
	.comment-form :global(.mention-field textarea) {
		display: block;
		width: 100%;
		min-height: 42px;
		max-height: 120px;
		padding: 10px 13px;
		background: var(--color-canvas);
		border: 1px solid var(--color-border);
		border-radius: 12px;
		outline: 0;
		font: inherit;
		line-height: 1.35;
		resize: none;
	}
	.comment-form button {
		display: grid;
		width: 42px;
		height: 42px;
		flex: none;
		place-items: center;
		background: var(--color-primary);
		border: 0;
		border-radius: 12px;
		color: white;
	}
	.comment-form .gif-btn {
		background: var(--color-secondary-soft, #d9efe6);
		color: var(--color-secondary, #178f72);
		font-size: 0.7rem;
		font-weight: 800;
		letter-spacing: 0.02em;
	}
	.comment-form button:disabled {
		opacity: 0.45;
	}
	.comment-gif {
		max-width: min(220px, 68%);
		margin: 6px 0 2px;
		border-radius: 12px;
		border: 1px solid var(--color-border);
	}
	.form-message,
	.empty {
		margin: 0;
		padding: 10px 14px;
		color: var(--color-muted);
		font-size: 0.72rem;
		text-align: center;
	}
	@media (max-width: 950px) {
		.post-detail-layout {
			grid-template-columns: 1fr;
		}
		.comments {
			position: static;
		}
	}
	@media (max-width: 767px) {
		.post-detail-layout {
			gap: 10px;
		}
		.comments {
			border-inline: 0;
			border-radius: 0;
		}
	}
</style>
