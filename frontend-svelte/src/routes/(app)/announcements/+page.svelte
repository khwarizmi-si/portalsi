<script lang="ts">
	import { CalendarDays, ImagePlus, Megaphone, Pencil, Pin, Trash2 } from '@lucide/svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import type { PageProps } from './$types';
	import { confirmButtonAction } from '$lib/ui/confirm';
	let { data, form }: PageProps = $props();
</script>

<svelte:head
	><title>Pengumuman — Portal SI</title><meta name="robots" content="noindex" /></svelte:head
><SectionPage
	eyebrow="Informasi resmi"
	title="Pengumuman"
	description="Kabar penting dari guru dan pengelola Portal SI."
	>{#if data.canManage}<details class="manager surface">
			<summary><Megaphone size={18} /> Buat pengumuman</summary>
			<form method="POST" action="?/create" enctype="multipart/form-data">
				<label>Judul <input name="title" maxlength="255" /></label><label
					>Konten <textarea name="content" rows="5"></textarea></label
				><label class="image"
					><ImagePlus size={17} /> Gambar opsional<input
						name="image"
						type="file"
						accept="image/*"
					/></label
				><label class="check"
					><input name="pinned" type="checkbox" value="1" /> Sematkan pengumuman</label
				><button type="submit">Terbitkan</button>
			</form>
		</details>{/if}
	{#if form?.message}<p class:success={form.success} class="notice" role="status">
			{form.message}
		</p>{/if}
	<div class="announcement-list">
		{#each data.items as item (item.id)}<article class="surface" class:pinned={item.pinned}>
				<span
					>{#if item.pinned}<Megaphone size={22} />{:else}<CalendarDays size={22} />{/if}</span
				>
				<div>
					<p>
						{#if item.pinned}<Pin size={13} />Disematkan ·
						{/if}{item.createdLabel}
					</p>
					<h2>{item.title}</h2>
					<small>Oleh {item.creatorName}</small>
					<div>{item.content}</div>
					{#if item.imageUrl}<a href={item.imageUrl} target="_blank" rel="noreferrer"
							><img src={item.imageUrl} alt="Gambar pengumuman {item.title}" /></a
						>{/if}
					{#if data.canManage && item.createdBy === data.currentUserId}<details class="edit">
							<summary><Pencil size={14} /> Kelola</summary>
							<form method="POST" action={`?/update&id=${item.id}`} enctype="multipart/form-data">
								<label>Judul <input name="title" maxlength="255" value={item.title} /></label><label
									>Konten <textarea name="content" rows="4">{item.content}</textarea></label
								><label class="image"
									><ImagePlus size={15} /> Ganti gambar<input
										name="image"
										type="file"
										accept="image/*"
									/></label
								><label class="check"
									><input name="pinned" type="checkbox" value="1" checked={item.pinned} /> Disematkan</label
								>
								<div class="manage-actions">
									<button type="submit">Simpan</button><button
										class="delete"
										type="submit"
										formaction={`?/delete&id=${item.id}`}
										onclick={(event) =>
											confirmButtonAction(event, {
												title: 'Hapus pengumuman?',
												description: 'Pengumuman ini akan dihapus dari semua pengguna.',
												confirmLabel: 'Hapus pengumuman',
												tone: 'danger'
											})}><Trash2 size={14} /> Hapus</button
									>
								</div>
							</form>
						</details>{/if}
				</div>
			</article>{/each}{#if data.items.length === 0}<p class="surface empty">
				Belum ada pengumuman.
			</p>{/if}
	</div></SectionPage
>

<style>
	.manager {
		margin-bottom: 14px;
		padding: 18px;
	}
	.manager summary,
	.edit summary {
		display: flex;
		width: fit-content;
		cursor: pointer;
		align-items: center;
		gap: 7px;
		font-size: 0.82rem;
		font-weight: 740;
	}
	.manager form,
	.edit form {
		display: grid;
		gap: 12px;
		margin-top: 16px;
	}
	.manager label,
	.edit label {
		display: grid;
		gap: 5px;
		color: var(--color-muted);
		font-size: 0.72rem;
		font-weight: 680;
	}
	.manager input,
	.manager textarea,
	.edit input,
	.edit textarea {
		width: 100%;
		padding: 10px 11px;
		background: var(--color-canvas);
		border: 1px solid var(--color-border);
		border-radius: 10px;
		outline: 0;
	}
	.manager .image,
	.edit .image {
		display: flex;
		align-items: center;
		gap: 7px;
	}
	.manager .image input,
	.edit .image input {
		flex: 1;
		padding: 7px;
	}
	.manager .check,
	.edit .check {
		display: flex;
		align-items: center;
		gap: 7px;
	}
	.manager .check input,
	.edit .check input {
		width: auto;
	}
	.manager button,
	.edit button {
		width: fit-content;
		min-height: 39px;
		padding: 0 14px;
		background: var(--color-primary);
		border: 0;
		border-radius: 10px;
		color: white;
		font-size: 0.74rem;
		font-weight: 720;
	}
	.notice {
		margin: 0 0 14px;
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
	.announcement-list {
		display: grid;
		gap: 13px;
	}
	.announcement-list article {
		display: grid;
		grid-template-columns: auto 1fr;
		gap: 14px;
		padding: 18px;
	}
	.announcement-list article > span {
		display: grid;
		width: 44px;
		height: 44px;
		place-items: center;
		background: var(--color-secondary-soft);
		border-radius: 13px;
		color: var(--color-secondary);
	}
	.announcement-list .pinned {
		background: linear-gradient(125deg, #fff9ec, #fff);
	}
	.announcement-list .pinned > span {
		background: #ffe8b9;
		color: #9a4c00;
	}
	.announcement-list p {
		display: flex;
		align-items: center;
		gap: 4px;
		margin: 0 0 3px;
		color: var(--color-muted);
		font-size: 0.7rem;
	}
	.announcement-list h2 {
		margin: 0 0 5px;
		font-size: 1rem;
	}
	.announcement-list small {
		display: block;
		margin: -2px 0 7px;
		color: var(--color-subtle);
		font-size: 0.66rem;
	}
	.announcement-list img {
		width: min(100%, 560px);
		max-height: 360px;
		margin-top: 12px;
		border-radius: 12px;
		object-fit: cover;
	}
	.edit {
		margin-top: 14px;
		padding-top: 12px;
		border-top: 1px solid var(--color-border);
	}
	.manage-actions {
		display: flex;
		gap: 8px;
	}
	.edit button.delete {
		display: flex;
		align-items: center;
		gap: 5px;
		background: var(--color-danger);
	}
	.announcement-list article div div {
		color: var(--color-muted);
		font-size: 0.83rem;
		white-space: pre-wrap;
	}
	.empty {
		padding: 36px;
		color: var(--color-muted);
		text-align: center;
	}
	@media (max-width: 767px) {
		.announcement-list article {
			border-inline: 0;
			border-radius: 0;
		}
	}
</style>
