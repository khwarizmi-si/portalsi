<script lang="ts">
	import { Edit3, Plus, Search, Users, X } from '@lucide/svelte';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	let query = $state('');
	let filter = $state<'all' | 'unread' | 'group'>('all');
	const chats = $derived(
		data.chats.filter((chat) => {
			const matchesQuery = `${chat.name} ${chat.handle}`
				.toLowerCase()
				.includes(query.toLowerCase());
			const matchesFilter =
				filter === 'all' ||
				(filter === 'unread' && chat.unread) ||
				(filter === 'group' && chat.type === 'group');
			return matchesQuery && matchesFilter;
		})
	);
</script>

<svelte:head><title>Pesan — Portal SI</title><meta name="robots" content="noindex" /></svelte:head>

<SectionPage
	eyebrow="Percakapan"
	title="Pesan"
	description="Kirim pesan dan tetap terhubung dengan teman maupun grup."
>
	{#snippet actions()}<div class="page-actions">
			<a class="new-message secondary" href="/groups/new"><Plus size={18} /> Buat grup</a><a
				class="new-message"
				href="/messages/new"><Edit3 size={18} /> Pesan baru</a
			>
		</div>{/snippet}
	<div class="messages-shell surface">
		<section class="inbox" aria-label="Daftar percakapan">
			<div class="inbox-head">
				<div><strong>Kotak masuk</strong><small>{data.chats.length} percakapan</small></div>
				<a href="/messages/new" aria-label="Tulis pesan baru"><Edit3 size={17} /></a>
			</div>
			{#if data.specialGroups.length}<div class="special-groups">
					<strong>Grup sekolah</strong>
					<div>
						{#each data.specialGroups as group (group.id)}<a href={`/messages/groups/${group.id}`}
								><Avatar name={group.name} src={group.avatarUrl ?? undefined} size="sm" /><span
									>{group.name}</span
								>{#if group.unread_message_count > 0}<i>{group.unread_message_count}</i>{/if}</a
							>{/each}
					</div>
				</div>{/if}
			<label class="chat-search"
				><Search size={17} /><span class="sr-only">Cari percakapan</span><input
					bind:value={query}
					placeholder="Cari percakapan"
				/>{#if query}<button onclick={() => (query = '')} aria-label="Hapus pencarian"
						><X size={15} /></button
					>{/if}</label
			>
			<div class="inbox-tabs">
				<button class:active={filter === 'all'} onclick={() => (filter = 'all')}>Semua</button>
				<button class:active={filter === 'unread'} onclick={() => (filter = 'unread')}
					>Belum dibaca</button
				>
				<button class:active={filter === 'group'} onclick={() => (filter = 'group')}>Grup</button>
			</div>
			<div class="chat-list">
				{#each chats as chat (chat.type + chat.id)}
					<a
						href={chat.type === 'group'
							? `/messages/groups/${chat.id}`
							: `/messages/direct/${chat.id}`}
					>
						{#if chat.type === 'group' && !chat.avatarUrl}<span class="group-avatar"
								><Users size={20} /></span
							>{:else}<Avatar name={chat.name} src={chat.avatarUrl ?? undefined} size="md" />{/if}
						<span class="chat-copy"
							><strong>{chat.name}</strong><small>{chat.handle}</small><small
								class:unread={chat.unread}>{chat.text}</small
							></span
						>
						<span class="chat-meta"
							><time>{chat.time}</time>{#if chat.unreadCount > 0}<i class="count" aria-label={`${chat.unreadCount} belum dibaca`}>{chat.unreadCount > 99 ? '99+' : chat.unreadCount}</i>{:else if chat.unread}<i aria-label="Belum dibaca"></i>{/if}</span
						>
					</a>
				{/each}
				{#if chats.length === 0}<p class="empty-list">
						{query.trim()
							? 'Tidak ada percakapan yang cocok.'
							: 'Belum ada percakapan. Mulai pesan baru untuk menyapa teman.'}
					</p>{/if}
			</div>
		</section>
		<section class="conversation-empty" aria-label="Pilih percakapan">
			<div class="message-art"><span></span><span></span><Edit3 size={26} /></div>
			<h2>Pilih percakapan</h2>
			<p>Buka pesan yang sudah ada atau mulai percakapan baru dengan teman di Portal SI.</p>
			<a href="/messages/new">Mulai pesan baru</a>
		</section>
	</div>
</SectionPage>

<style>
	.page-actions {
		display: flex;
		gap: 8px;
	}
	.new-message {
		display: flex;
		min-height: 44px;
		align-items: center;
		gap: 8px;
		padding: 0 15px;
		background: var(--color-primary);
		border-radius: 12px;
		color: white;
		font-size: 0.82rem;
		font-weight: 720;
	}
	.new-message.secondary {
		background: var(--color-secondary);
	}
	.special-groups {
		display: grid;
		gap: 8px;
		padding: 14px 16px 4px;
	}
	.special-groups > strong {
		color: var(--color-muted);
		font-size: 0.68rem;
		text-transform: uppercase;
		letter-spacing: 0.06em;
	}
	.special-groups > div {
		display: flex;
		gap: 8px;
		overflow-x: auto;
	}
	.special-groups a {
		position: relative;
		display: grid;
		min-width: 70px;
		justify-items: center;
		gap: 3px;
		color: var(--color-muted);
		font-size: 0.64rem;
		text-align: center;
	}
	.special-groups i {
		position: absolute;
		top: -3px;
		right: 5px;
		min-width: 18px;
		padding: 1px 4px;
		background: var(--color-danger);
		border-radius: 99px;
		color: white;
		font-size: 0.58rem;
		font-style: normal;
	}
	.messages-shell {
		display: grid;
		min-height: 650px;
		grid-template-columns: minmax(330px, 390px) 1fr;
		overflow: hidden;
	}
	.inbox {
		border-right: 1px solid var(--color-border);
	}
	.inbox-head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 16px 16px 2px;
	}
	.inbox-head > div {
		display: grid;
	}
	.inbox-head strong {
		font-size: 0.9rem;
	}
	.inbox-head small {
		color: var(--color-muted);
		font-size: 0.66rem;
	}
	.inbox-head a {
		display: grid;
		width: 36px;
		height: 36px;
		place-items: center;
		background: var(--color-primary-soft);
		border-radius: 11px;
		color: var(--color-primary-strong);
	}
	.chat-search {
		display: flex;
		height: 43px;
		align-items: center;
		gap: 8px;
		margin: 16px 16px 10px;
		padding: 0 12px;
		background: var(--color-canvas);
		border: 1px solid var(--color-border);
		border-radius: 12px;
		color: var(--color-muted);
	}
	.chat-search input {
		min-width: 0;
		flex: 1;
		background: transparent;
		border: 0;
		outline: 0;
		font-size: 0.82rem;
	}
	.chat-search button {
		display: grid;
		width: 28px;
		height: 28px;
		padding: 0;
		place-items: center;
		background: transparent;
		border: 0;
		border-radius: 8px;
		color: var(--color-muted);
	}
	.inbox-tabs {
		display: flex;
		gap: 6px;
		padding: 0 16px 12px;
		border-bottom: 1px solid var(--color-border);
	}
	.inbox-tabs button {
		min-height: 34px;
		padding: 0 12px;
		background: transparent;
		border: 0;
		border-radius: 10px;
		color: var(--color-muted);
		font-size: 0.72rem;
		font-weight: 670;
	}
	.inbox-tabs button.active {
		background: var(--color-primary-soft);
		color: var(--color-primary-strong);
	}
	.chat-list > a {
		display: grid;
		grid-template-columns: auto minmax(0, 1fr) auto;
		align-items: center;
		gap: 10px;
		min-height: 76px;
		padding: 10px 15px;
		border-bottom: 1px solid var(--color-border);
	}
	.chat-list > a:hover {
		background: var(--color-surface-soft);
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
	.chat-copy {
		display: grid;
		min-width: 0;
	}
	.chat-copy strong,
	.chat-copy small {
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.chat-copy strong {
		font-size: 0.84rem;
	}
	.chat-copy small {
		color: var(--color-subtle);
		font-size: 0.68rem;
	}
	.chat-copy small:last-child {
		color: var(--color-muted);
		font-size: 0.74rem;
	}
	.chat-copy small.unread {
		color: var(--color-text);
		font-weight: 680;
	}
	.chat-meta {
		display: grid;
		justify-items: end;
		gap: 7px;
	}
	.chat-meta time {
		color: var(--color-subtle);
		font-size: 0.66rem;
	}
	.chat-meta i {
		display: block;
		width: 9px;
		height: 9px;
		background: var(--color-primary);
		border-radius: 50%;
	}
	.chat-meta i.count {
		display: grid;
		width: auto;
		min-width: 20px;
		height: 20px;
		padding: 0 6px;
		place-items: center;
		color: white;
		border-radius: 999px;
		font-size: 0.64rem;
		font-weight: 800;
		font-style: normal;
	}
	.empty-list {
		padding: 28px 18px;
		color: var(--color-muted);
		font-size: 0.78rem;
		text-align: center;
	}
	.conversation-empty {
		display: grid;
		align-content: center;
		justify-items: center;
		padding: 32px;
		text-align: center;
	}
	.message-art {
		position: relative;
		display: grid;
		width: 92px;
		height: 92px;
		margin-bottom: 18px;
		place-items: center;
		background: var(--color-primary-soft);
		border-radius: 30px;
		color: var(--color-primary-strong);
		transform: rotate(-4deg);
	}
	.message-art span {
		position: absolute;
		width: 18px;
		height: 18px;
		background: var(--color-secondary-soft);
		border-radius: 6px;
	}
	.message-art span:first-child {
		top: -8px;
		right: 8px;
	}
	.message-art span:nth-child(2) {
		bottom: 8px;
		left: -10px;
	}
	.conversation-empty h2 {
		margin: 0 0 6px;
		font-size: 1.1rem;
	}
	.conversation-empty p {
		max-width: 24rem;
		margin: 0;
		color: var(--color-muted);
		font-size: 0.83rem;
	}
	.conversation-empty a {
		margin-top: 16px;
		color: var(--color-primary-strong);
		font-size: 0.8rem;
		font-weight: 730;
	}
	@media (max-width: 767px) {
		.page-actions {
			gap: 5px;
		}
		.new-message {
			width: 44px;
			padding: 0;
			justify-content: center;
			font-size: 0;
		}
		.new-message.secondary {
			display: flex;
		}
		.messages-shell {
			min-height: 0;
			grid-template-columns: 1fr;
			border-inline: 0;
			border-radius: 0;
		}
		.inbox {
			border: 0;
		}
		.conversation-empty {
			display: none;
		}
	}
</style>
