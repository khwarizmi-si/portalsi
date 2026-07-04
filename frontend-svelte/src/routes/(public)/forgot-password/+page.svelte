<script lang="ts">
	import { Mail } from '@lucide/svelte';
	import AuthFields from '$lib/components/auth/AuthFields.svelte';
	import AuthShell from '$lib/components/auth/AuthShell.svelte';
	import type { PageProps } from './$types';
	let { form }: PageProps = $props();
</script>

<svelte:head><title>Lupa kata sandi — Portal SI</title></svelte:head>

<AuthShell mode="simple">
	<div class="mail-icon"><Mail size={26} /></div>
	<div class="heading">
		<p class="eyebrow">Pemulihan akun</p>
		<h1>Lupa kata sandi?</h1>
		<p>
			Masukkan email yang terikat ke akun. Kami akan mengirim tautan untuk membuat kata sandi baru.
		</p>
	</div>
	{#if form?.message}<div
			class:success={form.success}
			class="form-alert"
			role={form.success ? 'status' : 'alert'}
		>
			{form.message}
		</div>{/if}
	<form method="POST">
		<AuthFields>
			<label
				><span>Email akun</span><input
					name="email"
					type="email"
					autocomplete="email"
					placeholder="nama@contoh.id"
					value={form?.values?.email ?? ''}
				/>{#if form?.errors?.email}<small class="field-error">{form.errors.email[0]}</small
					>{/if}</label
			>
			<button class="auth-primary" type="submit">Kirim tautan pemulihan</button>
		</AuthFields>
	</form>
	<p class="switch">Sudah ingat? <a href="/login">Kembali ke halaman masuk</a></p>
</AuthShell>

<style>
	.mail-icon {
		display: grid;
		width: 54px;
		height: 54px;
		margin-bottom: 20px;
		place-items: center;
		background: var(--color-primary-soft);
		border-radius: 17px;
		color: var(--color-primary-strong);
	}

	.heading h1 {
		margin: 0;
		font-size: clamp(1.9rem, 5vw, 2.5rem);
		letter-spacing: -0.045em;
	}

	.heading > p:last-child {
		max-width: 27rem;
		margin: 10px 0 26px;
		color: var(--color-muted);
		font-size: 0.92rem;
	}

	.switch {
		margin: 22px 0 0;
		color: var(--color-muted);
		font-size: 0.82rem;
		text-align: center;
	}

	.switch a {
		color: var(--color-primary-strong);
		font-weight: 720;
	}

	.form-alert {
		margin-bottom: 14px;
		padding: 11px 12px;
		background: var(--color-danger-soft);
		border: 1px solid #f1c5c1;
		border-radius: 11px;
		color: var(--color-danger);
		font-size: 0.78rem;
	}
	.form-alert.success {
		background: var(--color-secondary-soft);
		border-color: #b9ded8;
		color: var(--color-secondary);
	}
	.field-error {
		color: var(--color-danger);
		font-size: 0.7rem;
		font-weight: 560;
	}
</style>
