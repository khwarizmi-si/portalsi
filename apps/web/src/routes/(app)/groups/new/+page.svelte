<script lang="ts">
	import { env } from '$env/dynamic/public';
	import { ImagePlus, LoaderCircle, Search, Users, X } from '@lucide/svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import UserBadges from '$lib/components/ui/UserBadges.svelte';
	import { clientRequest } from '$lib/api/client';
	import { mapCompactUser } from '$lib/api/mappers';
	import { userSearchResponseSchema } from '$lib/schemas/post';
	import type { PortalUser } from '$lib/types/domain';
	import type { PageProps } from './$types';

	let { form }: PageProps = $props();
	const mediaBaseUrl = env.PUBLIC_MEDIA_BASE_URL?.trim() || 'https://api.portalsi.com/storage';

	let query = $state('');
	let results = $state<PortalUser[]>([]);
	let searching = $state(false);
	let selected = $state<PortalUser[]>([]);

	const membersValue = $derived(selected.map((user) => user.username).join(','));
	const visibleResults = $derived(
		results.filter((user) => !selected.some((picked) => picked.id === user.id))
	);

	$effect(() => {
		const q = query.trim();
		if (q.length < 2) {
			results = [];
			searching = false;
			return;
		}
		searching = true;
		const controller = new AbortController();
		const timer = window.setTimeout(async () => {
			try {
				const encoded = encodeURIComponent(q);
				const response = await clientRequest(
					`users/search?username=${encoded}&full_name=${encoded}&per_page=8`,
					{ schema: userSearchResponseSchema, signal: controller.signal }
				);
				results = response.data.map((user) => mapCompactUser(user, mediaBaseUrl));
			} catch (error) {
				if (!(error instanceof DOMException && error.name === 'AbortError')) results = [];
			} finally {
				if (!controller.signal.aborted) searching = false;
			}
		}, 260);
		return () => {
			window.clearTimeout(timer);
			controller.abort();
		};
	});

	function addUser(user: PortalUser) {
		if (!selected.some((picked) => picked.id === user.id)) selected.push(user);
		query = '';
		results = [];
	}
	function removeUser(id: number) {
		selected = selected.filter((user) => user.id !== id);
	}
	function onSearchKeydown(event: KeyboardEvent) {
		if (event.key === 'Enter') {
			event.preventDefault();
			if (visibleResults[0]) addUser(visibleResults[0]);
		}
	}
</script>

<svelte:head
	><title>Buat grup — Portal SI</title><meta name="robots" content="noindex" /></svelte:head
>

<SectionPage
	eyebrow="Percakapan bersama"
	title="Buat grup"
	description="Mulai ruang diskusi dan undang anggota lewat pencarian."
>
	<form class="group-form surface" method="POST" enctype="multipart/form-data">
		<div class="intro">
			<span><Users size={24} /></span>
			<div>
				<strong>Grup baru</strong>
				<p>Anda akan menjadi admin pertama grup.</p>
			</div>
		</div>
		<label>Nama grup <input name="name" required maxlength="100" /></label>
		<label>Deskripsi <textarea name="description" rows="4" maxlength="2000"></textarea></label>
		<div class="media-grid">
			<label class="upload"
				><ImagePlus size={18} /> Avatar JPG/PNG<input
					name="avatar"
					type="file"
					accept="image/jpeg,image/png"
				/></label
			>
			<label class="upload"
				><ImagePlus size={18} /> Sampul JPG/PNG<input
					name="cover"
					type="file"
					accept="image/jpeg,image/png"
				/></label
			>
		</div>

		<div class="member-field">
			<span class="member-label">Undang anggota</span>
			{#if selected.length}<div class="chips">
					{#each selected as user (user.id)}
						<span class="chip">
							<Avatar name={user.fullName} src={user.avatarUrl} size="sm" />
							<span>@{user.username}</span>
							<button
								type="button"
								onclick={() => removeUser(user.id)}
								aria-label={`Hapus ${user.username}`}><X size={13} /></button
							>
						</span>
					{/each}
				</div>{/if}
			<div class="search-box">
				<Search size={18} />
				<input
					bind:value={query}
					placeholder="Cari nama atau username…"
					autocomplete="off"
					onkeydown={onSearchKeydown}
				/>
				{#if searching}<LoaderCircle class="member-spinner" size={16} />{/if}
			</div>
			{#if query.trim().length >= 2}<div class="results" aria-label="Hasil pencarian">
					{#each visibleResults as user (user.id)}<button
							type="button"
							class="result"
							onclick={() => addUser(user)}
						>
							<Avatar name={user.fullName} src={user.avatarUrl} size="sm" />
							<span
								><strong>{user.fullName}<UserBadges verified={user.badgeVerified} role={user.role} /></strong
								><small>@{user.username}</small></span
							>
						</button>{/each}
					{#if !searching && visibleResults.length === 0}<p class="no-result">
							Tidak ada pengguna yang cocok.
						</p>{/if}
				</div>{/if}
			<input type="hidden" name="members" value={membersValue} />
			<p class="hint">
				Cari, klik (atau tekan Enter) untuk menambah. Anda bisa menambah anggota lagi nanti dari info
				grup.
			</p>
		</div>

		{#if form?.message}<p class="error" role="alert">{form.message}</p>{/if}
		<div class="actions">
			<a href="/messages">Batal</a><button type="submit">Buat grup</button>
		</div>
	</form>
</SectionPage>

<style>
	.group-form {
		display: grid;
		gap: 18px;
		max-width: 720px;
		padding: 24px;
	}
	.intro {
		display: flex;
		align-items: center;
		gap: 12px;
	}
	.intro > span {
		display: grid;
		width: 48px;
		height: 48px;
		place-items: center;
		background: var(--color-secondary-soft);
		border-radius: 14px;
		color: var(--color-secondary);
	}
	.intro strong {
		font-size: 1rem;
	}
	.intro p,
	.hint {
		margin: 0;
		color: var(--color-muted);
		font-size: 0.76rem;
	}
	.group-form > label {
		display: grid;
		gap: 7px;
		font-size: 0.78rem;
		font-weight: 700;
	}
	input,
	textarea {
		width: 100%;
		padding: 11px 12px;
		background: var(--color-canvas);
		border: 1px solid var(--color-border);
		border-radius: 12px;
		outline: 0;
	}
	textarea {
		resize: vertical;
	}
	.media-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 12px;
	}
	.upload {
		display: flex;
		min-height: 48px;
		align-items: center;
		gap: 8px;
		padding: 10px 12px;
		border: 1px dashed var(--color-border-strong);
		border-radius: 12px;
		color: var(--color-muted);
		font-size: 0.76rem;
	}
	.upload input {
		padding: 0;
		background: transparent;
		border: 0;
		font-size: 0.7rem;
	}
	.member-field {
		display: grid;
		gap: 9px;
	}
	.member-label {
		font-size: 0.78rem;
		font-weight: 700;
	}
	.chips {
		display: flex;
		flex-wrap: wrap;
		gap: 7px;
	}
	.chip {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		padding: 4px 6px 4px 4px;
		background: var(--color-secondary-soft);
		border-radius: 999px;
		font-size: 0.74rem;
		font-weight: 650;
	}
	.chip button {
		display: grid;
		width: 20px;
		height: 20px;
		place-items: center;
		padding: 0;
		background: rgb(0 0 0 / 10%);
		border: 0;
		border-radius: 50%;
		color: inherit;
		cursor: pointer;
	}
	.search-box {
		position: relative;
		display: flex;
		align-items: center;
		gap: 9px;
		padding: 0 12px;
		background: var(--color-canvas);
		border: 1px solid var(--color-border);
		border-radius: 12px;
		color: var(--color-muted);
	}
	.search-box input {
		border: 0;
		background: transparent;
		padding-inline: 0;
	}
	.search-box :global(.member-spinner) {
		color: var(--color-primary);
		animation: member-spin 0.8s linear infinite;
	}
	@keyframes member-spin {
		to {
			transform: rotate(360deg);
		}
	}
	.results {
		display: grid;
		gap: 2px;
		padding: 6px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 12px;
	}
	.result {
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 8px;
		background: transparent;
		border: 0;
		border-radius: 9px;
		text-align: left;
		cursor: pointer;
	}
	.result:hover {
		background: var(--color-surface-soft);
	}
	.result span {
		display: grid;
	}
	.result strong {
		font-size: 0.8rem;
	}
	.result small {
		color: var(--color-muted);
		font-size: 0.7rem;
	}
	.no-result {
		margin: 0;
		padding: 10px;
		color: var(--color-muted);
		font-size: 0.74rem;
		text-align: center;
	}
	.actions {
		display: flex;
		justify-content: flex-end;
		gap: 8px;
	}
	.actions a,
	.actions button {
		min-height: 43px;
		padding: 0 16px;
		border: 0;
		border-radius: 12px;
		font-size: 0.78rem;
		font-weight: 730;
	}
	.actions a {
		display: flex;
		align-items: center;
		background: var(--color-canvas);
	}
	.actions button {
		background: var(--color-primary);
		color: white;
	}
	.error {
		margin: 0;
		padding: 10px 12px;
		background: var(--color-danger-soft);
		border-radius: 10px;
		color: var(--color-danger);
		font-size: 0.76rem;
	}
	@media (max-width: 600px) {
		.group-form {
			padding: 18px;
			border-inline: 0;
			border-radius: 0;
		}
		.media-grid {
			grid-template-columns: 1fr;
		}
	}
</style>
