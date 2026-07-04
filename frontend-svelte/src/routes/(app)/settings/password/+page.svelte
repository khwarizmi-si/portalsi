<script lang="ts">
	import type { PageProps } from './$types';
	let { form }: PageProps = $props();
</script>

<svelte:head><title>Ubah kata sandi — Portal SI</title></svelte:head>
<main class="settings-form surface">
	<a href="/settings">← Pengaturan</a>
	<h1>Ubah kata sandi</h1>
	<form method="POST">
		<label
			><span>Kata sandi saat ini</span><input
				type="password"
				name="current_password"
				required
				autocomplete="current-password"
			/></label
		><label
			><span>Kata sandi baru</span><input
				type="password"
				name="new_password"
				required
				minlength="6"
				autocomplete="new-password"
			/></label
		><label
			><span>Ulangi kata sandi baru</span><input
				type="password"
				name="confirmation"
				required
				minlength="6"
				autocomplete="new-password"
			/></label
		>{#if form?.message}<p class:success={form.success}>{form.message}</p>{/if}<button
			>Perbarui kata sandi</button
		>
	</form>
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
	button {
		min-height: 44px;
		background: var(--color-primary);
		border: 0;
		border-radius: 11px;
		color: white;
		font-weight: 720;
	}
	p {
		margin: 0;
		color: var(--color-danger);
		font-size: 0.76rem;
	}
	p.success {
		color: var(--color-secondary);
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
