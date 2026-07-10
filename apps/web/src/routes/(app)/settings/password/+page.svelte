<script lang="ts">
	import { CircleCheckBig, Eye, EyeOff, Home, ShieldCheck } from '@lucide/svelte';
	import type { PageProps } from './$types';
	type PasswordForm = {
		success?: boolean;
		message?: string;
		errors?: {
			current_password?: string[];
			new_password?: string[];
			confirmation?: string[];
		};
	};
	let { form: actionForm }: PageProps = $props();
	const form = $derived(actionForm as PasswordForm | null | undefined);

	let showCurrent = $state(false);
	let showNew = $state(false);
	let showConfirm = $state(false);
	let next = $state('');
	let confirm = $state('');
	const mismatch = $derived(confirm.length > 0 && next !== confirm);
</script>

<svelte:head><title>Ubah kata sandi — Portal SI</title></svelte:head>
<main class="settings-form surface">
	{#if form?.success}
		<div class="result ok">
			<div class="icon"><CircleCheckBig size={30} /></div>
			<h1>Kata sandi diperbarui</h1>
			<p>{form.message} Gunakan kata sandi baru Anda saat masuk berikutnya.</p>
			<a class="home-btn" href="/home"><Home size={18} /> Kembali ke Portal SI</a>
		</div>
	{:else}
		<a class="back" href="/settings">← Pengaturan</a>
		<h1><ShieldCheck size={22} /> Ubah kata sandi</h1>
		<p class="lead">Gunakan minimal 8 karakter dan berbeda dari kata sandi lama.</p>
		<form method="POST">
			<label
				><span>Kata sandi saat ini</span>
				<div class="pw">
					<input
						type={showCurrent ? 'text' : 'password'}
						name="current_password"
						required
						autocomplete="current-password"
					/><button
						type="button"
						onclick={() => (showCurrent = !showCurrent)}
						aria-label={showCurrent ? 'Sembunyikan' : 'Tampilkan'}
						>{#if showCurrent}<EyeOff size={18} />{:else}<Eye size={18} />{/if}</button
					>
				</div>
				{#if form?.errors?.current_password}<small class="err">{form.errors.current_password[0]}</small
					>{/if}</label
			>
			<label
				><span>Kata sandi baru</span>
				<div class="pw">
					<input
						type={showNew ? 'text' : 'password'}
						name="new_password"
						required
						minlength="8"
						autocomplete="new-password"
						bind:value={next}
					/><button
						type="button"
						onclick={() => (showNew = !showNew)}
						aria-label={showNew ? 'Sembunyikan' : 'Tampilkan'}
						>{#if showNew}<EyeOff size={18} />{:else}<Eye size={18} />{/if}</button
					>
				</div>
				{#if form?.errors?.new_password}<small class="err">{form.errors.new_password[0]}</small
					>{/if}</label
			>
			<label
				><span>Ulangi kata sandi baru</span>
				<div class="pw">
					<input
						type={showConfirm ? 'text' : 'password'}
						name="confirmation"
						required
						minlength="8"
						autocomplete="new-password"
						bind:value={confirm}
						aria-invalid={mismatch ? 'true' : undefined}
					/><button
						type="button"
						onclick={() => (showConfirm = !showConfirm)}
						aria-label={showConfirm ? 'Sembunyikan' : 'Tampilkan'}
						>{#if showConfirm}<EyeOff size={18} />{:else}<Eye size={18} />{/if}</button
					>
				</div>
				{#if mismatch}<small class="err">Kata sandi belum sama.</small>
				{:else if form?.errors?.confirmation}<small class="err">{form.errors.confirmation[0]}</small
					>{/if}</label
			>
			{#if form?.message && !form?.success}<p class="alert">{form.message}</p>{/if}
			<button class="submit" type="submit">Perbarui kata sandi</button>
		</form>
	{/if}
</main>

<style>
	.settings-form {
		width: min(100% - 32px, 560px);
		margin: 28px auto;
		padding: 24px;
	}
	.back {
		color: var(--color-primary-strong);
		font-size: 0.78rem;
		font-weight: 700;
	}
	h1 {
		display: flex;
		align-items: center;
		gap: 8px;
		margin: 18px 0 6px;
		font-size: 1.3rem;
	}
	.lead {
		margin: 0 0 18px;
		color: var(--color-muted);
		font-size: 0.82rem;
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
	.pw {
		position: relative;
		display: flex;
		align-items: center;
	}
	.pw input {
		width: 100%;
		padding: 11px 44px 11px 12px;
		background: var(--color-surface-soft);
		border: 1px solid var(--color-border);
		border-radius: 11px;
		outline: 0;
	}
	.pw input:focus {
		border-color: var(--color-primary);
		box-shadow: var(--focus-ring);
	}
	.pw button {
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
	.pw button:hover {
		color: var(--color-text);
	}
	.submit {
		min-height: 46px;
		background: var(--color-primary);
		border: 0;
		border-radius: 11px;
		color: white;
		font-weight: 720;
	}
	.err {
		color: var(--color-danger);
		font-size: 0.72rem;
		font-weight: 560;
	}
	.alert {
		margin: 0;
		padding: 11px 12px;
		background: var(--color-danger-soft, #fdecea);
		border: 1px solid #f1c5c1;
		border-radius: 11px;
		color: var(--color-danger);
		font-size: 0.76rem;
	}
	.result {
		display: grid;
		justify-items: center;
		gap: 8px;
		padding: 20px 10px 8px;
		text-align: center;
	}
	.result .icon {
		display: grid;
		width: 62px;
		height: 62px;
		place-items: center;
		background: var(--color-secondary-soft, #d9efe6);
		border-radius: 50%;
		color: var(--color-secondary, #178f72);
	}
	.result h1 {
		justify-content: center;
		margin: 8px 0 0;
	}
	.result p {
		max-width: 30rem;
		margin: 0;
		color: var(--color-muted);
		font-size: 0.86rem;
	}
	.home-btn {
		display: inline-flex;
		align-items: center;
		gap: 8px;
		margin-top: 16px;
		padding: 12px 18px;
		background: var(--color-primary);
		border-radius: 12px;
		color: white;
		font-weight: 720;
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
