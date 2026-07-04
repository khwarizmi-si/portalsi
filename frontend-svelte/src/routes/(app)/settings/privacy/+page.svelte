<script lang="ts">
	import { enhance } from '$app/forms';
	import { untrack } from 'svelte';
	import type { PageProps } from './$types';
	let { data, form }: PageProps = $props();
	let isPrivate = $state(untrack(() => data.isPrivate));
</script>

<svelte:head><title>Privasi akun — Portal SI</title></svelte:head>
<main class="settings-form surface">
	<a href="/settings">← Pengaturan</a>
	<h1>Privasi akun</h1>
	<p>Akun privat memerlukan persetujuan Anda sebelum orang lain dapat melihat postingan.</p>
	<form
		method="POST"
		use:enhance={() =>
			async ({ update }) =>
				update({ reset: false, invalidateAll: false })}
	>
		<label
			><input type="checkbox" name="is_private" bind:checked={isPrivate} /><span
				><strong>Jadikan akun privat</strong><small>Pengikut baru harus Anda setujui.</small></span
			></label
		>{#if form?.message}<p class:success={form.success}>{form.message}</p>{/if}<button
			>Simpan privasi</button
		>
	</form>
</main>

<style>
	.settings-form {
		width: min(100% - 32px, 600px);
		margin: 28px auto;
		padding: 24px;
	}
	.settings-form > a {
		color: var(--color-primary-strong);
		font-size: 0.78rem;
		font-weight: 700;
	}
	h1 {
		margin: 18px 0 5px;
		font-size: 1.3rem;
	}
	.settings-form > p {
		color: var(--color-muted);
		font-size: 0.82rem;
	}
	form {
		display: grid;
		gap: 16px;
		margin-top: 22px;
	}
	label {
		display: flex;
		align-items: flex-start;
		gap: 11px;
		padding: 15px;
		background: var(--color-surface-soft);
		border: 1px solid var(--color-border);
		border-radius: 12px;
	}
	label input {
		margin-top: 3px;
	}
	label span {
		display: grid;
	}
	label small {
		color: var(--color-muted);
	}
	button {
		min-height: 44px;
		background: var(--color-primary);
		border: 0;
		border-radius: 11px;
		color: white;
		font-weight: 720;
	}
	form > p {
		margin: 0;
		color: var(--color-danger);
		font-size: 0.76rem;
	}
	form > p.success {
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
