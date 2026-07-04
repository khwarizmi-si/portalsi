<script lang="ts">
	import { ArrowLeft, Crown, Shield, UserMinus, UserPlus, Volume2, VolumeX } from '@lucide/svelte';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import VerifiedBadge from '$lib/components/ui/VerifiedBadge.svelte';
	import { confirmFormSubmit } from '$lib/ui/confirm';
	import type { PageProps } from './$types';
	let { data, form }: PageProps = $props();
</script>

<svelte:head
	><title>{data.group.name} — Info grup</title><meta name="robots" content="noindex" /></svelte:head
>

<main class="info-page">
	<a class="back" href={`/messages/groups/${data.group.id}`}
		><ArrowLeft size={18} /> Kembali ke percakapan</a
	>
	<section class="hero surface">
		{#if data.group.coverUrl}<img
				class="cover"
				src={data.group.coverUrl}
				alt="Sampul {data.group.name}"
			/>{/if}
		<div class="identity">
			<Avatar name={data.group.name} src={data.group.avatarUrl ?? undefined} size="lg" />
			<div>
				<p>Info grup</p>
				<h1>{data.group.name}</h1>
				<span
					>{data.members.length} anggota · Anda {data.role === 'admin' ? 'admin' : 'anggota'}</span
				>
			</div>
		</div>
		{#if data.group.description}<p class="description">{data.group.description}</p>{/if}
	</section>

	{#if form?.message}<p class:success={form.success} class="notice" role="status">
			{form.message}
		</p>{/if}

	{#if data.isOwner}
		<details class="surface panel">
			<summary>Edit info grup</summary>
			<form method="POST" action="?/update" enctype="multipart/form-data">
				<label>Nama <input name="name" required maxlength="100" value={data.group.name} /></label>
				<label
					>Deskripsi <textarea name="description" rows="3">{data.group.description ?? ''}</textarea
					></label
				>
				<div class="file-grid">
					<label>Avatar <input name="avatar" type="file" accept="image/jpeg,image/png" /></label
					><label>Sampul <input name="cover" type="file" accept="image/jpeg,image/png" /></label>
				</div>
				<button type="submit">Simpan perubahan</button>
			</form>
		</details>
	{/if}

	{#if data.role === 'admin'}
		<section class="surface panel">
			<h2><UserPlus size={18} /> Tambah anggota</h2>
			<form class="add-member" method="POST" action="?/add">
				<label
					><span class="sr-only">Username atau email</span><input
						name="identifier"
						required
						placeholder="Username atau email"
					/></label
				><select name="role" aria-label="Peran anggota"
					><option value="member">Anggota</option><option value="admin">Admin</option></select
				><button type="submit">Tambahkan</button>
			</form>
		</section>
	{/if}

	<section class="surface panel">
		<h2>Anggota ({data.members.length})</h2>
		<div class="members">
			{#each data.members as member (member.user_id)}
				<article>
					<Avatar name={member.fullName} src={member.avatarUrl ?? undefined} size="md" />
					<div class="member-copy">
						<strong
							>{member.fullName}
							{#if member.is_verified}<VerifiedBadge />{/if}</strong
						><a href={`/u/${member.username}`}>@{member.username}</a><small
							>{member.role === 'admin' ? 'Admin' : 'Anggota'}{member.is_muted
								? ' · dibisukan'
								: ''}</small
						>
					</div>
					{#if data.role === 'admin' && member.user_id !== data.currentUserId && member.user_id !== data.group.owner.user_id}<div
							class="member-actions"
						>
							<form
								method="POST"
								action={member.role === 'admin'
									? `?/demote&userId=${member.user_id}`
									: `?/promote&userId=${member.user_id}`}
							>
								<button
									title={member.role === 'admin' ? 'Jadikan anggota' : 'Jadikan admin'}
									aria-label={member.role === 'admin' ? 'Jadikan anggota' : 'Jadikan admin'}
									>{#if member.role === 'admin'}<Shield size={15} />{:else}<Crown
											size={15}
										/>{/if}</button
								>
							</form>
							<form
								method="POST"
								action={member.is_muted
									? `?/unmute&userId=${member.user_id}`
									: `?/mute&userId=${member.user_id}`}
							>
								<button
									title={member.is_muted ? 'Bunyikan' : 'Bisukan'}
									aria-label={member.is_muted ? 'Bunyikan anggota' : 'Bisukan anggota'}
									>{#if member.is_muted}<Volume2 size={15} />{:else}<VolumeX
											size={15}
										/>{/if}</button
								>
							</form>
							<form method="POST" action={`?/remove&userId=${member.user_id}`}>
								<button class="danger" title="Keluarkan" aria-label="Keluarkan anggota"
									><UserMinus size={15} /></button
								>
							</form>
						</div>{/if}
				</article>
			{/each}
		</div>
	</section>

	<section class="danger-zone surface">
		<div>
			<h2>{data.isOwner ? 'Hapus grup' : 'Keluar dari grup'}</h2>
			<p>
				{data.isOwner
					? 'Grup dan riwayatnya akan dihapus oleh backend.'
					: 'Anda tidak akan menerima pesan baru dari grup ini.'}
			</p>
		</div>
		<form
			method="POST"
			action={data.isOwner ? '?/delete' : '?/leave'}
			onsubmit={(event) =>
				confirmFormSubmit(event, {
					title: data.isOwner ? 'Hapus grup?' : 'Keluar dari grup?',
					description: data.isOwner
						? 'Grup beserta riwayat percakapannya akan dihapus permanen.'
						: 'Anda tidak akan menerima pesan baru dari grup ini.',
					confirmLabel: data.isOwner ? 'Ya, hapus grup' : 'Ya, keluar',
					tone: 'danger'
				})}
		>
			<button>{data.isOwner ? 'Hapus grup' : 'Keluar grup'}</button>
		</form>
	</section>
</main>

<style>
	.info-page {
		display: grid;
		width: min(100% - 32px, 780px);
		gap: 14px;
		margin: 28px auto 60px;
	}
	.back {
		display: flex;
		width: fit-content;
		align-items: center;
		gap: 7px;
		color: var(--color-muted);
		font-size: 0.78rem;
		font-weight: 700;
	}
	.hero {
		overflow: hidden;
	}
	.cover {
		width: 100%;
		height: 180px;
		object-fit: cover;
	}
	.identity {
		display: flex;
		align-items: center;
		gap: 13px;
		padding: 20px 20px 12px;
	}
	.identity p,
	.identity span {
		margin: 0;
		color: var(--color-muted);
		font-size: 0.7rem;
	}
	.identity h1 {
		margin: 0;
		font-size: 1.35rem;
	}
	.description {
		margin: 0;
		padding: 0 20px 20px;
		color: var(--color-muted);
		font-size: 0.82rem;
		white-space: pre-wrap;
	}
	.panel {
		padding: 18px;
	}
	.panel summary {
		cursor: pointer;
		font-size: 0.9rem;
		font-weight: 740;
	}
	.panel h2 {
		display: flex;
		align-items: center;
		gap: 7px;
		margin: 0 0 13px;
		font-size: 0.92rem;
	}
	.panel form {
		display: grid;
		gap: 12px;
		margin-top: 16px;
	}
	.panel label {
		display: grid;
		gap: 6px;
		color: var(--color-muted);
		font-size: 0.72rem;
		font-weight: 680;
	}
	input,
	textarea,
	select {
		width: 100%;
		padding: 10px 11px;
		background: var(--color-canvas);
		border: 1px solid var(--color-border);
		border-radius: 10px;
		outline: 0;
	}
	.file-grid,
	.add-member {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 10px;
	}
	.add-member {
		grid-template-columns: 1fr 130px auto;
		margin-top: 0 !important;
	}
	.panel form > button,
	.add-member button {
		min-height: 40px;
		padding: 0 14px;
		background: var(--color-primary);
		border: 0;
		border-radius: 10px;
		color: white;
		font-size: 0.75rem;
		font-weight: 720;
	}
	.members {
		display: grid;
	}
	.members article {
		display: flex;
		min-width: 0;
		align-items: center;
		gap: 10px;
		padding: 11px 0;
		border-top: 1px solid var(--color-border);
	}
	.member-copy {
		display: grid;
		min-width: 0;
		margin-right: auto;
	}
	.member-copy strong {
		display: flex;
		align-items: center;
		gap: 4px;
		font-size: 0.8rem;
	}
	.member-copy a,
	.member-copy small {
		color: var(--color-muted);
		font-size: 0.68rem;
	}
	.member-actions {
		display: flex;
		gap: 4px;
	}
	.member-actions form {
		margin: 0;
	}
	.member-actions button {
		display: grid;
		width: 34px;
		height: 34px;
		place-items: center;
		background: var(--color-canvas);
		border: 1px solid var(--color-border);
		border-radius: 9px;
		color: var(--color-muted);
	}
	.member-actions button.danger {
		color: var(--color-danger);
	}
	.notice {
		margin: 0;
		padding: 10px 12px;
		background: var(--color-danger-soft);
		border-radius: 10px;
		color: var(--color-danger);
		font-size: 0.76rem;
	}
	.notice.success {
		background: var(--color-secondary-soft);
		color: var(--color-secondary);
	}
	.danger-zone {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 20px;
		padding: 18px;
		border-color: #f0c9c6;
	}
	.danger-zone h2 {
		margin: 0;
		font-size: 0.9rem;
	}
	.danger-zone p {
		margin: 2px 0 0;
		color: var(--color-muted);
		font-size: 0.72rem;
	}
	.danger-zone button {
		min-height: 40px;
		padding: 0 14px;
		background: var(--color-danger);
		border: 0;
		border-radius: 10px;
		color: white;
		font-size: 0.74rem;
		font-weight: 720;
	}
	@media (max-width: 600px) {
		.info-page {
			width: 100%;
			margin-top: 12px;
		}
		.surface {
			border-inline: 0;
			border-radius: 0;
		}
		.add-member,
		.file-grid {
			grid-template-columns: 1fr;
		}
		.danger-zone {
			align-items: flex-start;
			flex-direction: column;
		}
	}
</style>
