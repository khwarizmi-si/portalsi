<script lang="ts">
	import { FileText, Pencil, Plus, Trash2 } from '@lucide/svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import type { PageProps } from './$types';
	import { confirmButtonAction } from '$lib/ui/confirm';
	let { data, form }: PageProps = $props();
	const labels = { quran: 'Al-Qur’an', it: 'Teknologi', bahasa: 'Bahasa', karakter: 'Karakter' };
</script>

<svelte:head><title>Portfolio — Portal SI</title></svelte:head><SectionPage
	eyebrow="Karya komunitas"
	title="Portfolio"
	description="Dokumentasi karya, pencapaian, dan proses belajar."
	>{#snippet actions()}{#if data.canCreate}<a class="new" href="/portfolio/new"
				><Plus size={17} />Tambah karya</a
			>{/if}{/snippet}
	<nav>
		<a class:active={!data.aspect} href="/portfolio">Semua</a
		>{#each Object.entries(labels) as [key, label] (key)}<a
				class:active={data.aspect === key}
				href={`/portfolio?aspect=${key}`}>{label}</a
			>{/each}
	</nav>
	{#if form?.message}<p class:success={form.success} class="notice" role="status">
			{form.message}
		</p>{/if}
	<section class="grid">
		{#each data.items as item (item.id)}<article class="surface">
				{#if item.mediaUrl}{#if item.mediaUrl.toLowerCase().includes('.pdf')}<a
							class="media pdf"
							href={item.mediaUrl}
							target="_blank"
							rel="noreferrer"><FileText size={30} /><span>Buka PDF</span></a
						>{:else}<img src={item.mediaUrl} alt={item.title} />{/if}{/if}
				<div>
					<small>{labels[item.aspect]} · {item.year || 'Tanpa tahun'}</small>
					<h2>{item.title}</h2>
					<p>{item.description || 'Tanpa deskripsi.'}</p>
					{#if item.user_name}<a href={`/u/${item.user_name}`}>@{item.user_name}</a>{/if}
					{#if item.signed_by}<p class="signature">
							Ditandatangani oleh <a href={`/u/${item.signed_by.username}`}
								>{item.signed_by.full_name || `@${item.signed_by.username}`}</a
							>{item.signed_by.role === 'teacher' ? ' · Teacher' : ''}
						</p>{/if}
					{#if data.canCreate}<details class="manage">
							<summary><Pencil size={13} /> Kelola</summary>
							<form method="POST" action={`?/update&id=${item.id}`} enctype="multipart/form-data">
								<label
									>Kategori <select name="aspect" value={item.aspect}
										><option value="quran">Al-Qur’an</option><option value="it">Teknologi</option
										><option value="bahasa">Bahasa</option><option value="karakter">Karakter</option
										></select
									></label
								><label
									>Judul <input name="title" maxlength="255" required value={item.title} /></label
								><label
									>Deskripsi <textarea name="description" rows="3"
										>{item.description ?? ''}</textarea
									></label
								><label
									>Tahun <input
										name="year"
										type="number"
										min="2000"
										max={new Date().getFullYear()}
										value={item.year ?? ''}
									/></label
								><label
									>Ganti media <input
										name="media"
										type="file"
										accept="image/jpeg,image/png,application/pdf"
									/></label
								>
								<div>
									<button type="submit">Simpan</button><button
										class="delete"
										type="submit"
										formaction={`?/delete&id=${item.id}`}
										onclick={(event) =>
											confirmButtonAction(event, {
												title: 'Hapus portfolio?',
												description: 'Karya ini akan dihapus permanen dari portfolio.',
												confirmLabel: 'Hapus karya',
												tone: 'danger'
											})}><Trash2 size={13} /> Hapus</button
									>
								</div>
							</form>
						</details>{/if}
				</div>
			</article>{/each}
	</section>
	{#if data.items.length === 0}<p class="empty surface">
			Belum ada karya untuk kategori ini.
		</p>{/if}</SectionPage
>

<style>
	.notice {
		margin: 0 0 14px;
		padding: 10px 12px;
		background: var(--color-danger-soft);
		border-radius: 10px;
		color: var(--color-danger);
		font-size: 0.74rem;
	}
	.notice.success {
		background: var(--color-secondary-soft);
		color: var(--color-secondary);
	}
	.new {
		display: flex;
		min-height: 42px;
		align-items: center;
		gap: 6px;
		padding: 0 14px;
		background: var(--color-primary);
		border-radius: 11px;
		color: white;
		font-size: 0.78rem;
		font-weight: 700;
	}
	nav {
		display: flex;
		gap: 7px;
		margin-bottom: 16px;
		overflow: auto;
	}
	nav a {
		flex: none;
		padding: 9px 13px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 999px;
		color: var(--color-muted);
		font-size: 0.74rem;
		font-weight: 680;
	}
	nav a.active {
		background: var(--color-text);
		color: white;
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 14px;
	}
	.grid article {
		overflow: hidden;
	}
	.grid img,
	.media {
		width: 100%;
		aspect-ratio: 4/3;
		object-fit: cover;
	}
	.media {
		display: grid;
		place-content: center;
		justify-items: center;
		gap: 6px;
		background: var(--color-secondary-soft);
		color: var(--color-secondary);
		font-size: 0.72rem;
	}
	.grid article > div {
		padding: 15px;
	}
	.grid small {
		color: var(--color-primary-strong);
		font-size: 0.68rem;
		font-weight: 700;
	}
	.grid h2 {
		margin: 5px 0;
		font-size: 0.95rem;
	}
	.grid p {
		display: -webkit-box;
		overflow: hidden;
		-webkit-box-orient: vertical;
		-webkit-line-clamp: 2;
		line-clamp: 2;
		margin: 0;
		color: var(--color-muted);
		font-size: 0.76rem;
	}
	.grid article > div > a {
		display: block;
		margin-top: 10px;
		color: var(--color-secondary);
		font-size: 0.7rem;
	}
	.signature {
		margin-top: 9px !important;
		padding: 7px 9px;
		background: var(--color-secondary-soft);
		border-radius: 8px;
		color: var(--color-secondary) !important;
		font-size: 0.66rem !important;
	}
	.signature a {
		font-weight: 750;
	}
	.manage {
		margin-top: 12px;
		padding-top: 10px;
		border-top: 1px solid var(--color-border);
	}
	.manage summary {
		display: flex;
		width: fit-content;
		cursor: pointer;
		align-items: center;
		gap: 5px;
		color: var(--color-muted);
		font-size: 0.68rem;
		font-weight: 700;
	}
	.manage form {
		display: grid;
		gap: 8px;
		margin-top: 10px;
	}
	.manage label {
		display: grid;
		gap: 3px;
		color: var(--color-muted);
		font-size: 0.64rem;
		font-weight: 680;
	}
	.manage input,
	.manage textarea,
	.manage select {
		width: 100%;
		padding: 7px 8px;
		background: var(--color-canvas);
		border: 1px solid var(--color-border);
		border-radius: 8px;
		outline: 0;
	}
	.manage form > div {
		display: flex;
		gap: 6px;
	}
	.manage button {
		display: flex;
		min-height: 34px;
		align-items: center;
		gap: 4px;
		padding: 0 10px;
		background: var(--color-primary);
		border: 0;
		border-radius: 8px;
		color: white;
		font-size: 0.66rem;
		font-weight: 700;
	}
	.manage button.delete {
		background: var(--color-danger);
	}
	.empty {
		padding: 40px;
		color: var(--color-muted);
		text-align: center;
	}
	@media (max-width: 850px) {
		.grid {
			grid-template-columns: repeat(2, 1fr);
		}
	}
	@media (max-width: 520px) {
		nav {
			padding-inline: 16px;
		}
		.grid {
			grid-template-columns: 1fr;
			padding-inline: 16px;
		}
	}
</style>
