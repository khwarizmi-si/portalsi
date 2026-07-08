<script lang="ts">
	import { env } from '$env/dynamic/public';
	import { Check, Copy, LoaderCircle, Search, Send, Share2, Users, X } from '@lucide/svelte';
	import { untrack } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import { userSearchResponseSchema } from '$lib/schemas/post';
	import { chatListSchema } from '$lib/schemas/chat';
	import { normalizeMediaUrl } from '$lib/utils/media';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import UserBadges from '$lib/components/ui/UserBadges.svelte';

	type Target = {
		key: string;
		kind: 'user' | 'group';
		id: number;
		name: string;
		handle: string;
		avatarUrl: string | null;
		verified: boolean;
		role: 'student' | 'parent' | 'teacher' | 'dev' | 'other';
	};

	let {
		postId,
		shareUrl,
		onClose
	}: { postId: number; shareUrl: string; onClose: () => void } = $props();

	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';

	let recentTargets = $state<Target[]>([]);
	let searchTargets = $state<Target[]>([]);
	let query = $state('');
	let loading = $state(true);
	let searching = $state(false);
	let selected = $state<Set<string>>(new Set());
	let note = $state('');
	let sending = $state(false);
	let status = $state('');
	let copied = $state(false);
	let done = $state(false);

	const shownTargets = $derived(query.trim().length >= 2 ? searchTargets : recentTargets);

	function userTarget(user: {
		user_id: number;
		username: string;
		full_name?: string | null;
		profile_picture_url?: string | null;
		is_verified?: boolean;
		role?: Target['role'];
	}): Target {
		return {
			key: `user:${user.user_id}`,
			kind: 'user',
			id: user.user_id,
			name: user.full_name?.trim() || user.username,
			handle: `@${user.username}`,
			avatarUrl: normalizeMediaUrl(user.profile_picture_url, mediaBaseUrl) ?? null,
			verified: Boolean(user.is_verified),
			role: user.role ?? 'other'
		};
	}

	// Daftar awal = obrolan terbaru (grup & pribadi), urut berdasarkan waktu chat terakhir.
	$effect(() => {
		let active = true;
		untrack(async () => {
			try {
				const list = await clientRequest('messages/chat-list', { schema: chatListSchema });
				const withTime = list.map((item) => ({
					item,
					at: item.type === 'user' ? item.last_chat.sent_at : item.sent_at
				}));
				withTime.sort(
					(a, b) => (b.at ? Date.parse(b.at) : 0) - (a.at ? Date.parse(a.at) : 0)
				);
				const targets = withTime.map(({ item }): Target =>
					item.type === 'user'
						? {
								key: `user:${item.conversation.id}`,
								kind: 'user',
								id: item.conversation.id,
								name:
									item.conversation.name || item.conversation.username || 'Pengguna Portal SI',
								handle: item.conversation.username ? `@${item.conversation.username}` : 'Pesan',
								avatarUrl:
									normalizeMediaUrl(item.conversation.profile_picture_url, mediaBaseUrl) ?? null,
								verified: false,
								role: 'other'
							}
						: {
								key: `group:${item.id}`,
								kind: 'group',
								id: item.id,
								name: item.name,
								handle: 'Grup',
								avatarUrl: normalizeMediaUrl(item.avatar_url, mediaBaseUrl) ?? null,
								verified: false,
								role: 'other'
							}
				);
				if (active) recentTargets = targets;
			} catch {
				if (active) status = 'Daftar obrolan belum dapat dimuat.';
			} finally {
				if (active) loading = false;
			}
		});
		return () => {
			active = false;
		};
	});

	// Pencarian pengguna (untuk mengirim ke orang yang belum pernah dichat).
	$effect(() => {
		const q = query.trim();
		if (q.length < 2) {
			searching = false;
			return;
		}
		searching = true;
		const controller = new AbortController();
		const timer = window.setTimeout(async () => {
			try {
				const encoded = encodeURIComponent(q);
				const response = await clientRequest(
					`users/search?username=${encoded}&full_name=${encoded}&per_page=20`,
					{ schema: userSearchResponseSchema, signal: controller.signal }
				);
				const groups = recentTargets.filter(
					(target) => target.kind === 'group' && target.name.toLowerCase().includes(q.toLowerCase())
				);
				searchTargets = [...groups, ...response.data.map(userTarget)];
			} catch (error) {
				if (!(error instanceof DOMException && error.name === 'AbortError'))
					status = 'Pencarian gagal.';
			} finally {
				if (!controller.signal.aborted) searching = false;
			}
		}, 280);
		return () => {
			window.clearTimeout(timer);
			controller.abort();
		};
	});

	function toggle(key: string) {
		const next = new Set(selected);
		if (next.has(key)) next.delete(key);
		else next.add(key);
		selected = next;
	}

	async function copyLink() {
		try {
			await navigator.clipboard.writeText(shareUrl);
			copied = true;
			window.setTimeout(() => (copied = false), 1800);
		} catch {
			status = 'Tautan belum dapat disalin.';
		}
	}

	async function nativeShare() {
		try {
			if (navigator.share) await navigator.share({ url: shareUrl });
		} catch (error) {
			if (error instanceof DOMException && error.name === 'AbortError') return;
			status = 'Bagikan gagal.';
		}
	}

	async function sendToSelected() {
		if (sending || selected.size === 0) return;
		sending = true;
		status = '';
		const content = note.trim() ? `${note.trim()}\n${shareUrl}` : shareUrl;
		const keys = [...selected];
		try {
			for (const key of keys) {
				const [kind, idString] = key.split(':');
				const id = Number(idString);
				const body = new FormData();
				body.set('content', content);
				if (kind === 'group') {
					await clientRequest(`groups/${id}/messages`, { method: 'POST', body });
				} else {
					body.set('receiver_id', String(id));
					await clientRequest('messages/send', { method: 'POST', body });
				}
			}
			done = true;
			status = `Postingan dikirim ke ${keys.length} obrolan.`;
			window.setTimeout(onClose, 1100);
		} catch {
			status = 'Sebagian pesan gagal terkirim. Coba lagi.';
		} finally {
			sending = false;
		}
	}

	// Cegah scroll body saat sheet terbuka.
	$effect(() => {
		void postId;
		const previous = document.body.style.overflow;
		document.body.style.overflow = 'hidden';
		return () => {
			document.body.style.overflow = previous;
		};
	});
</script>

<div
	class="share-overlay"
	role="button"
	tabindex="-1"
	aria-label="Tutup"
	onclick={onClose}
	onkeydown={(event) => {
		if (event.key === 'Escape') onClose();
	}}
></div>

<section class="share-sheet" role="dialog" aria-modal="true" aria-label="Bagikan postingan">
	<header>
		<strong>Bagikan</strong>
		<button onclick={onClose} aria-label="Tutup"><X size={19} /></button>
	</header>

	<div class="quick">
		<button onclick={copyLink}>
			<i>{#if copied}<Check size={19} />{:else}<Copy size={19} />{/if}</i>
			<span>{copied ? 'Tersalin' : 'Salin tautan'}</span>
		</button>
		<button onclick={nativeShare}>
			<i><Share2 size={19} /></i>
			<span>Bagikan ke…</span>
		</button>
	</div>

	<div class="search">
		<Search size={17} />
		<input placeholder="Cari orang atau grup untuk dikirimi" bind:value={query} />
		{#if searching}<LoaderCircle class="spin" size={16} />{/if}
	</div>

	<div class="people">
		{#if loading}
			<p class="hint">Memuat obrolan…</p>
		{:else if shownTargets.length === 0}
			<p class="hint">Tidak ada yang cocok.</p>
		{:else}
			{#each shownTargets as target (target.key)}
				<button
					class="person"
					class:selected={selected.has(target.key)}
					onclick={() => toggle(target.key)}
					aria-pressed={selected.has(target.key)}
				>
					{#if target.kind === 'group' && !target.avatarUrl}
						<span class="group-avatar"><Users size={17} /></span>
					{:else}
						<Avatar name={target.name} src={target.avatarUrl ?? undefined} size="sm" />
					{/if}
					<span class="who">
						<strong
							>{target.name}{#if target.kind === 'user'}<UserBadges
									verified={target.verified}
									role={target.role}
								/>{/if}</strong
						>
						<small>{target.handle}</small>
					</span>
					<span class="check" aria-hidden="true">
						{#if selected.has(target.key)}<Check size={15} />{/if}
					</span>
				</button>
			{/each}
		{/if}
	</div>

	{#if selected.size > 0}
		<input class="note" placeholder="Tambahkan pesan (opsional)" bind:value={note} />
	{/if}

	{#if status}<p class="status" class:ok={done} aria-live="polite">{status}</p>{/if}

	<button class="send" disabled={selected.size === 0 || sending} onclick={sendToSelected}>
		{#if sending}<LoaderCircle class="spin" size={17} />{:else}<Send size={17} />{/if}
		Kirim{selected.size > 0 ? ` (${selected.size})` : ''}
	</button>
</section>

<style>
	.share-overlay {
		position: fixed;
		z-index: 1200;
		inset: 0;
		background: rgb(20 15 10 / 45%);
		backdrop-filter: blur(2px);
	}
	.share-sheet {
		position: fixed;
		z-index: 1201;
		right: 0;
		bottom: 0;
		left: 0;
		display: flex;
		max-height: 82vh;
		flex-direction: column;
		margin: 0 auto;
		padding: 8px 16px calc(16px + var(--safe-bottom));
		background: var(--color-surface);
		border-radius: 20px 20px 0 0;
		box-shadow: 0 -18px 44px rgb(0 0 0 / 22%);
	}
	.share-sheet header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 8px 2px 12px;
	}
	.share-sheet header strong {
		font-size: 1rem;
	}
	.share-sheet header button {
		display: grid;
		width: 34px;
		height: 34px;
		place-items: center;
		border: 0;
		border-radius: 50%;
		background: var(--color-canvas-deep, #f1ece3);
		color: var(--color-muted);
	}
	.quick {
		display: flex;
		gap: 10px;
		padding-bottom: 12px;
	}
	.quick button {
		display: flex;
		flex: 1;
		align-items: center;
		gap: 9px;
		padding: 11px 13px;
		background: var(--color-canvas-deep, #f4efe6);
		border: 1px solid var(--color-border);
		border-radius: 13px;
		font-size: 0.8rem;
		font-weight: 650;
	}
	.quick button i {
		display: grid;
		width: 34px;
		height: 34px;
		flex: none;
		place-items: center;
		background: var(--color-primary-soft);
		border-radius: 10px;
		color: var(--color-primary-strong);
	}
	.search {
		display: flex;
		height: 44px;
		align-items: center;
		gap: 8px;
		padding: 0 12px;
		background: var(--color-canvas-deep, #f4efe6);
		border: 1px solid var(--color-border);
		border-radius: 12px;
		color: var(--color-muted);
	}
	.search input {
		flex: 1;
		min-width: 0;
		background: transparent;
		border: 0;
		outline: 0;
		font-size: 0.85rem;
	}
	:global(.share-sheet .spin) {
		color: var(--color-primary);
		animation: share-spin 0.8s linear infinite;
	}
	@keyframes share-spin {
		to {
			transform: rotate(360deg);
		}
	}
	.people {
		display: grid;
		flex: 1;
		gap: 2px;
		overflow-y: auto;
		margin: 8px -6px;
		padding: 0 6px;
	}
	.hint {
		padding: 22px;
		color: var(--color-muted);
		font-size: 0.78rem;
		text-align: center;
	}
	.person {
		display: flex;
		align-items: center;
		gap: 11px;
		padding: 8px 10px;
		background: transparent;
		border: 0;
		border-radius: 12px;
		text-align: left;
	}
	.person:hover {
		background: var(--color-canvas-deep, #f4efe6);
	}
	.person.selected {
		background: var(--color-primary-soft);
	}
	.person .group-avatar {
		display: grid;
		width: 34px;
		height: 34px;
		flex: none;
		place-items: center;
		background: var(--color-secondary-soft, #d9efe6);
		border-radius: 50%;
		color: var(--color-secondary, #178f72);
	}
	.person .who {
		display: grid;
		flex: 1;
		min-width: 0;
	}
	.person .who strong {
		display: flex;
		align-items: center;
		gap: 3px;
		font-size: 0.82rem;
	}
	.person .who small {
		color: var(--color-muted);
		font-size: 0.7rem;
	}
	.person .check {
		display: grid;
		width: 24px;
		height: 24px;
		flex: none;
		place-items: center;
		border: 2px solid var(--color-border);
		border-radius: 50%;
		color: white;
	}
	.person.selected .check {
		background: var(--color-primary);
		border-color: var(--color-primary);
	}
	.note {
		height: 42px;
		margin-top: 6px;
		padding: 0 13px;
		background: var(--color-canvas-deep, #f4efe6);
		border: 1px solid var(--color-border);
		border-radius: 12px;
		font-size: 0.85rem;
	}
	.status {
		margin: 8px 2px 0;
		color: var(--color-danger);
		font-size: 0.76rem;
	}
	.status.ok {
		color: var(--color-primary-strong);
	}
	.send {
		display: flex;
		height: 48px;
		align-items: center;
		justify-content: center;
		gap: 8px;
		margin-top: 12px;
		background: var(--color-primary);
		border: 0;
		border-radius: 13px;
		color: white;
		font-size: 0.88rem;
		font-weight: 720;
	}
	.send:disabled {
		opacity: 0.5;
	}
	@media (min-width: 620px) {
		.share-sheet {
			right: 50%;
			bottom: auto;
			left: 50%;
			top: 50%;
			width: 440px;
			max-height: 78vh;
			transform: translate(-50%, -50%);
			border-radius: 20px;
		}
	}
</style>
