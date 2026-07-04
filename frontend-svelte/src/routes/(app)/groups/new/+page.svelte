<script lang="ts">
	import { ImagePlus, Users } from '@lucide/svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import type { PageProps } from './$types';
	let { form }: PageProps = $props();
</script>

<svelte:head
	><title>Buat grup — Portal SI</title><meta name="robots" content="noindex" /></svelte:head
>

<SectionPage
	eyebrow="Percakapan bersama"
	title="Buat grup"
	description="Mulai ruang diskusi dan undang anggota dengan username atau email."
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
		<label
			>Undang anggota <textarea
				name="members"
				rows="4"
				placeholder="siti, ahmad@example.com&#10;Satu username/email per baris atau pisahkan dengan koma"
			></textarea></label
		>
		<p class="hint">
			Identifier yang tidak ditemukan akan dilewati oleh server. Anda dapat menambah anggota lagi
			dari info grup.
		</p>
		{#if form?.message}<p class="error" role="alert">{form.message}</p>{/if}
		<div class="actions"><a href="/messages">Batal</a><button type="submit">Buat grup</button></div>
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
