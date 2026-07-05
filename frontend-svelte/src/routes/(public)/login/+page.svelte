<script lang="ts">
	import { page } from '$app/state';
	import { Eye, LockKeyhole, UserRound } from '@lucide/svelte';
	import AuthFields from '$lib/components/auth/AuthFields.svelte';
	import AuthShell from '$lib/components/auth/AuthShell.svelte';
	import type { PageProps } from './$types';
	let { form }: PageProps = $props();
	let revealPassword = $state(false);
	// Tujuan setelah login (mis. /login?next=/posts/12). Diteruskan lewat hidden input
	// agar tetap terbawa walau query pada aksi form tak konsisten.
	const nextTarget = $derived(page.url.searchParams.get('next') ?? '');
</script>

<svelte:head><title>Masuk — Portal SI</title></svelte:head>

<AuthShell>
	<div class="heading">
		<p class="eyebrow">Selamat datang kembali</p>
		<h1>Masuk ke Portal SI</h1>
		<p>Lanjutkan percakapan dan lihat kabar terbaru dari komunitas.</p>
	</div>
	{#if form?.message}<div class="form-alert" role="alert">
			{form.message}{#if 'retryAfterSeconds' in form && form.retryAfterSeconds}
				Coba lagi dalam {form.retryAfterSeconds} detik.{/if}
		</div>{/if}
	<form method="POST">
		{#if nextTarget}<input type="hidden" name="next" value={nextTarget} />{/if}
		<AuthFields>
			<label>
				<span>Username atau email</span>
				<div class="input-icon">
					<UserRound size={18} /><input
						name="login"
						autocomplete="username"
						placeholder="nama@contoh.id"
						value={form?.values?.login ?? ''}
						aria-invalid={form?.errors?.login ? 'true' : undefined}
					/>
				</div>
				{#if form?.errors?.login}<small class="field-error">{form.errors.login[0]}</small>{/if}
			</label>
			<label>
				<span>Kata sandi</span>
				<div class="input-icon">
					<LockKeyhole size={18} /><input
						name="password"
						type={revealPassword ? 'text' : 'password'}
						autocomplete="current-password"
						placeholder="Masukkan kata sandi"
						aria-invalid={form?.errors?.password ? 'true' : undefined}
					/><button
						type="button"
						onclick={() => (revealPassword = !revealPassword)}
						aria-label={revealPassword ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'}
						aria-pressed={revealPassword}><Eye size={18} /></button
					>
				</div>
				{#if form?.errors?.password}<small class="field-error">{form.errors.password[0]}</small
					>{/if}
			</label>
			<div class="form-meta">
				<label class="remember"
					><input type="checkbox" name="remember" /> <span>Ingat perangkat ini</span></label
				><a href="/forgot-password">Lupa kata sandi?</a>
			</div>
			<button class="auth-primary" type="submit">Masuk</button>
		</AuthFields>
	</form>
	<p class="switch">Belum punya akun? <a href="/register">Daftar sekarang</a></p>
</AuthShell>

<style>
	.heading h1 {
		margin: 0;
		font-size: clamp(1.9rem, 5vw, 2.55rem);
		letter-spacing: -0.045em;
		line-height: 1.08;
	}

	.heading > p:last-child {
		max-width: 25rem;
		margin: 10px 0 28px;
		color: var(--color-muted);
		font-size: 0.94rem;
	}

	.input-icon {
		display: flex;
		align-items: center;
		background: white;
		border: 1px solid var(--color-border-strong);
		border-radius: 12px;
		color: var(--color-subtle);
		padding-left: 13px;
	}

	.input-icon:focus-within {
		border-color: var(--color-primary);
		box-shadow: var(--focus-ring);
	}

	.input-icon :global(input) {
		border: 0;
		box-shadow: none;
	}

	.input-icon :global(input:focus) {
		box-shadow: none;
	}

	.input-icon button {
		display: grid;
		width: 45px;
		height: 45px;
		place-items: center;
		padding: 0;
		background: transparent;
		border: 0;
		border-radius: 10px;
		cursor: pointer;
	}

	.form-meta {
		display: flex;
		align-items: center;
		justify-content: space-between;
		font-size: 0.78rem;
	}

	.form-meta :global(.remember) {
		display: flex;
		grid-template: none;
		align-items: center;
		gap: 7px;
		font-weight: 580;
	}

	.form-meta :global(.remember input) {
		width: 16px;
		height: 16px;
	}

	.form-meta a,
	.switch a {
		color: var(--color-primary-strong);
		font-weight: 720;
	}

	.switch {
		margin: 24px 0 0;
		color: var(--color-muted);
		font-size: 0.85rem;
		text-align: center;
	}

	.form-alert {
		margin-bottom: 16px;
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
</style>
