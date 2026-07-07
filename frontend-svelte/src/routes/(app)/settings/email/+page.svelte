<script lang="ts">
	import { MailCheck, ShieldAlert } from '@lucide/svelte';
	import type { PageProps } from './$types';
	let { data, form }: PageProps = $props();
</script>

<svelte:head><title>Ubah email — Portal SI</title></svelte:head>
<main class="settings-form surface">
	<a href="/settings">← Pengaturan</a>
	<h1>Ubah email</h1>

	<div class="current">
		<span>Email saat ini</span>
		<strong>{data.email || 'Belum ada email'}</strong>
		{#if data.email}<em class:verified={data.emailVerified}
				>{data.emailVerified ? 'Terverifikasi' : 'Belum diverifikasi'}</em
			>{/if}
	</div>

	{#if form?.success}
		<div class="notice ok">
			<MailCheck size={20} />
			<p>{form.message}</p>
		</div>
		<p class="hint">
			Buka tautan di email <strong>{form.pendingEmail}</strong>. Email akun Anda baru berubah setelah
			Anda mengonfirmasinya. Tautan berlaku 60 menit.
		</p>
	{:else}
		<form method="POST">
			<label
				><span>Email baru</span><input
					type="email"
					name="email"
					required
					placeholder="nama@contoh.com"
					value={form?.values?.email ?? ''}
					autocomplete="email"
				/></label
			>
			<div class="info">
				<ShieldAlert size={16} />
				<p>
					Demi keamanan, kami akan mengirim tautan konfirmasi ke alamat email baru. Email hanya dapat
					diganti <strong>sekali dalam 24 jam</strong>.
				</p>
			</div>
			{#if form?.errors?.email?.length}<p class="err">{form.errors.email[0]}</p>
			{:else if form?.message && !form?.success}<p class="err">{form.message}</p>{/if}
			<button>Kirim tautan konfirmasi</button>
		</form>
	{/if}
</main>

<style>
	.settings-form {
		width: min(100% - 32px, 560px);
		margin: 28px auto;
		padding: 24px;
	}
	.settings-form > a {
		color: var(--color-primary-strong);
		font-size: 0.78rem;
		font-weight: 700;
	}
	h1 {
		margin: 18px 0;
		font-size: 1.3rem;
	}
	.current {
		display: flex;
		align-items: center;
		flex-wrap: wrap;
		gap: 8px;
		margin-bottom: 20px;
		padding: 14px 16px;
		background: var(--color-surface-soft);
		border: 1px solid var(--color-border);
		border-radius: 12px;
	}
	.current span {
		color: var(--color-muted);
		font-size: 0.74rem;
	}
	.current strong {
		margin-right: auto;
		font-size: 0.9rem;
		overflow-wrap: anywhere;
	}
	.current em {
		padding: 3px 9px;
		background: #fbe8d8;
		border-radius: 999px;
		color: #9a5518;
		font-size: 0.62rem;
		font-style: normal;
		font-weight: 700;
	}
	.current em.verified {
		background: var(--color-secondary-soft, #d9efe6);
		color: var(--color-secondary, #178f72);
	}
	form,
	label {
		display: grid;
	}
	form {
		gap: 15px;
	}
	label {
		gap: 7px;
	}
	label span {
		font-size: 0.78rem;
		font-weight: 700;
	}
	input {
		padding: 11px 12px;
		background: var(--color-surface-soft);
		border: 1px solid var(--color-border);
		border-radius: 11px;
	}
	.info,
	.notice {
		display: flex;
		gap: 9px;
		align-items: flex-start;
	}
	.info {
		padding: 11px 13px;
		background: var(--color-primary-soft);
		border-radius: 11px;
		color: var(--color-primary-strong);
	}
	.info p,
	.notice p {
		margin: 0;
		font-size: 0.76rem;
		line-height: 1.45;
	}
	.notice.ok {
		align-items: center;
		padding: 14px 16px;
		background: var(--color-secondary-soft, #d9efe6);
		border-radius: 12px;
		color: var(--color-secondary, #178f72);
	}
	.hint {
		margin: 12px 2px 0;
		color: var(--color-muted);
		font-size: 0.78rem;
		line-height: 1.5;
	}
	button {
		min-height: 44px;
		background: var(--color-primary);
		border: 0;
		border-radius: 11px;
		color: white;
		font-weight: 720;
	}
	.err {
		margin: 0;
		color: var(--color-danger);
		font-size: 0.76rem;
	}
	@media (max-width: 767px) {
		.settings-form {
			width: 100%;
			margin: 0;
			border: 0;
			border-radius: 0;
		}
	}
</style>
