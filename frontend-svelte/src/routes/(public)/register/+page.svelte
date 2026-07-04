<script lang="ts">
	import AuthFields from '$lib/components/auth/AuthFields.svelte';
	import AuthShell from '$lib/components/auth/AuthShell.svelte';
	import type { PageProps } from './$types';
	let { form }: PageProps = $props();
</script>

<svelte:head><title>Daftar — Portal SI</title></svelte:head>

<AuthShell mode="register">
	<div class="heading">
		<p class="eyebrow">Mulai perjalanan Anda</p>
		<h1>Buat akun Portal SI</h1>
		<p>Karena seribu langkah dimulai dari satu langkah.</p>
	</div>
	{#if form?.message}<div class="form-alert" role="alert">{form.message}</div>{/if}
	<form method="POST">
		<AuthFields>
			<div class="two-fields">
				<label
					><span>Nama lengkap</span><input
						name="full_name"
						autocomplete="name"
						placeholder="Fulan Abdullah"
						value={form?.values?.full_name ?? ''}
					/>{#if form?.errors?.full_name}<small class="field-error"
							>{form.errors.full_name[0]}</small
						>{/if}</label
				>
				<label
					><span>Username</span><input
						name="username"
						autocomplete="username"
						placeholder="fulan123"
						value={form?.values?.username ?? ''}
					/>{#if form?.errors?.username}<small class="field-error">{form.errors.username[0]}</small
						>{/if}</label
				>
			</div>
			<label
				><span>Email</span><input
					name="email"
					type="email"
					autocomplete="email"
					placeholder="nama@contoh.id"
					value={form?.values?.email ?? ''}
				/>{#if form?.errors?.email}<small class="field-error">{form.errors.email[0]}</small
					>{/if}</label
			>
			<label
				><span>Kata sandi</span><input
					name="password"
					type="password"
					autocomplete="new-password"
					placeholder="Minimal 6 karakter"
				/>{#if form?.errors?.password}<small class="field-error">{form.errors.password[0]}</small
					>{/if}</label
			>
			<label class="terms"
				><input type="checkbox" name="terms" /><span
					>Saya menyetujui aturan komunitas dan kebijakan privasi Portal SI.</span
				></label
			>
			{#if form?.errors?.terms}<small class="field-error">{form.errors.terms[0]}</small>{/if}
			<button class="auth-primary" type="submit">Buat akun</button>
		</AuthFields>
	</form>
	<p class="switch">Sudah punya akun? <a href="/login">Masuk</a></p>
</AuthShell>

<style>
	.heading h1 {
		margin: 0;
		font-size: clamp(1.85rem, 5vw, 2.45rem);
		letter-spacing: -0.045em;
		line-height: 1.08;
	}

	.heading > p:last-child {
		margin: 10px 0 24px;
		color: var(--color-muted);
		font-size: 0.9rem;
	}

	.two-fields {
		display: grid;
		gap: 15px;
	}

	:global(.auth-fields .terms) {
		display: grid;
		grid-template-columns: auto 1fr;
		align-items: start;
		gap: 9px;
		color: var(--color-muted);
		font-size: 0.75rem;
		font-weight: 560;
		line-height: 1.4;
	}

	:global(.auth-fields .terms input) {
		width: 17px;
		height: 17px;
		margin-top: 1px;
	}

	.switch {
		margin: 20px 0 0;
		color: var(--color-muted);
		font-size: 0.84rem;
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
	.field-error {
		color: var(--color-danger);
		font-size: 0.7rem;
		font-weight: 560;
	}

	@media (min-width: 520px) {
		.two-fields {
			grid-template-columns: 1fr 1fr;
		}
	}
</style>
