<script lang="ts">
	import AuthShell from '$lib/components/auth/AuthShell.svelte';
	import type { PageProps } from './$types';
	let { data, form }: PageProps = $props();
</script>

<svelte:head><title>Reset kata sandi — Portal SI</title></svelte:head><AuthShell mode="simple">
	<div class="heading">
		<p class="eyebrow">Pemulihan akun</p>
		<h1>Buat kata sandi baru</h1>
		<p>Tautan reset hanya dapat digunakan sesuai masa berlaku backend.</p>
	</div>
	<form method="POST" class="reset">
		<input type="hidden" name="token" value={data.token} /><label
			><span>Email</span><input
				type="email"
				name="email"
				required
				value={data.email}
				autocomplete="email"
			/></label
		><label
			><span>Kata sandi baru</span><input
				type="password"
				name="password"
				required
				minlength="6"
				autocomplete="new-password"
			/></label
		><label
			><span>Ulangi kata sandi</span><input
				type="password"
				name="password_confirmation"
				required
				minlength="6"
				autocomplete="new-password"
			/></label
		>{#if form?.message}<p role="alert">{form.message}</p>{/if}<button>Reset kata sandi</button>
	</form></AuthShell
>

<style>
	.heading h1 {
		margin: 0;
		font-size: 2rem;
	}
	.heading > p:last-child {
		margin: 8px 0 22px;
		color: var(--color-muted);
	}
	.reset {
		display: grid;
		gap: 14px;
	}
	.reset label {
		display: grid;
		gap: 6px;
	}
	.reset label span {
		font-size: 0.76rem;
		font-weight: 700;
	}
	.reset input {
		padding: 11px 12px;
		background: var(--color-surface-soft);
		border: 1px solid var(--color-border);
		border-radius: 10px;
	}
	.reset button {
		min-height: 44px;
		background: var(--color-primary);
		border: 0;
		border-radius: 11px;
		color: white;
		font-weight: 720;
	}
	.reset p {
		margin: 0;
		color: var(--color-danger);
		font-size: 0.75rem;
	}
</style>
