<script lang="ts">
	import { Eye, EyeOff } from '@lucide/svelte';
	import AuthFields from '$lib/components/auth/AuthFields.svelte';
	import AuthShell from '$lib/components/auth/AuthShell.svelte';
	import type { PageProps } from './$types';
	let { form }: PageProps = $props();

	let showPassword = $state(false);
	let showConfirm = $state(false);
	let password = $state('');
	let confirm = $state('');
	const mismatch = $derived(confirm.length > 0 && password !== confirm);
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
				><span>Kata sandi</span>
				<div class="pw-field">
					<input
						name="password"
						type={showPassword ? 'text' : 'password'}
						autocomplete="new-password"
						placeholder="Minimal 6 karakter"
						bind:value={password}
					/><button
						type="button"
						onclick={() => (showPassword = !showPassword)}
						aria-label={showPassword ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'}
						aria-pressed={showPassword}
						>{#if showPassword}<EyeOff size={18} />{:else}<Eye size={18} />{/if}</button
					>
				</div>
				{#if form?.errors?.password}<small class="field-error">{form.errors.password[0]}</small
					>{/if}</label
			>
			<label
				><span>Ulangi kata sandi</span>
				<div class="pw-field">
					<input
						name="password_confirmation"
						type={showConfirm ? 'text' : 'password'}
						autocomplete="new-password"
						placeholder="Ketik ulang kata sandi"
						bind:value={confirm}
						aria-invalid={mismatch ? 'true' : undefined}
					/><button
						type="button"
						onclick={() => (showConfirm = !showConfirm)}
						aria-label={showConfirm ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'}
						aria-pressed={showConfirm}
						>{#if showConfirm}<EyeOff size={18} />{:else}<Eye size={18} />{/if}</button
					>
				</div>
				{#if mismatch}<small class="field-error">Kata sandi belum sama.</small>
				{:else if form?.errors?.password_confirmation}<small class="field-error"
						>{form.errors.password_confirmation[0]}</small
					>{/if}</label
			>
			<div class="terms">
				<input type="checkbox" name="terms" id="terms" />
				<label for="terms"
					>Saya menyetujui <a href="/legal/kebijakan" target="_blank" rel="noopener"
						>aturan komunitas</a
					>
					dan
					<a href="/legal/privasi" target="_blank" rel="noopener">kebijakan privasi</a> Portal SI.</label
				>
			</div>
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

	.pw-field {
		position: relative;
		display: flex;
		align-items: center;
	}
	.pw-field input {
		flex: 1;
		width: 100%;
		padding-right: 44px;
	}
	.pw-field button {
		position: absolute;
		right: 6px;
		display: grid;
		width: 34px;
		height: 34px;
		place-items: center;
		padding: 0;
		background: transparent;
		border: 0;
		color: var(--color-muted);
		cursor: pointer;
	}
	.pw-field button:hover {
		color: var(--color-text);
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
	:global(.auth-fields .terms label) {
		color: var(--color-muted);
	}
	:global(.auth-fields .terms a) {
		color: var(--color-primary-strong);
		font-weight: 700;
		text-decoration: underline;
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
