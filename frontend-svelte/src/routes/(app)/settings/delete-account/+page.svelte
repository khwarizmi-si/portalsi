<script lang="ts">
	import { confirmFormSubmit } from '$lib/ui/confirm';
	import type { PageProps } from './$types';
	let { form }: PageProps = $props();
</script>

<svelte:head><title>Hapus akun — Portal SI</title></svelte:head>
<main class="delete surface">
	<a href="/settings">← Pengaturan</a>
	<h1>Hapus akun secara permanen</h1>
	<p>
		Semua profil, konten, relasi, dan media Anda akan dihapus oleh backend. Tindakan ini tidak dapat
		dibatalkan.
	</p>
	<form
		method="POST"
		onsubmit={(event) =>
			confirmFormSubmit(event, {
				title: 'Hapus akun secara permanen?',
				description:
					'Semua profil, postingan, pesan, dan relasi akun akan dihapus dan tidak dapat dipulihkan.',
				confirmLabel: 'Ya, hapus akun',
				tone: 'danger'
			})}
	>
		<label
			><span>Masukkan password untuk mengonfirmasi</span><input
				name="password"
				type="password"
				required
				autocomplete="current-password"
				placeholder="Password akun Anda"
			/></label
		>{#if form?.message}<p role="alert">{form.message}</p>{/if}<button>Hapus akun saya</button>
	</form>
</main>

<style>
	.delete {
		width: min(100% - 32px, 560px);
		margin: 28px auto;
		padding: 24px;
		border-color: #e9b9b1;
	}
	.delete > a {
		color: var(--color-primary-strong);
		font-size: 0.78rem;
		font-weight: 700;
	}
	h1 {
		margin: 20px 0 8px;
		color: var(--color-danger);
		font-size: 1.3rem;
	}
	.delete > p {
		color: var(--color-muted);
		font-size: 0.82rem;
	}
	form,
	label {
		display: grid;
	}
	form {
		gap: 14px;
		margin-top: 22px;
	}
	label {
		gap: 7px;
		font-size: 0.78rem;
	}
	input {
		padding: 11px;
		border: 1px solid var(--color-border);
		border-radius: 10px;
	}
	form > p {
		margin: 0;
		color: var(--color-danger);
		font-size: 0.75rem;
	}
	button {
		min-height: 44px;
		background: var(--color-danger);
		border: 0;
		border-radius: 11px;
		color: white;
		font-weight: 720;
	}
</style>
