<script lang="ts">
	import { BadgeCheck, MailCheck, TriangleAlert } from '@lucide/svelte';
	import { page } from '$app/state';

	const state = $derived(page.url.searchParams.get('email'));
	const view = $derived.by(() => {
		switch (state) {
			case 'changed':
				return {
					ok: true,
					title: 'Email berhasil diubah',
					body: 'Alamat email akun Anda telah diperbarui dan terverifikasi. Silakan masuk kembali dengan email baru Anda.'
				};
			case 'taken':
				return {
					ok: false,
					title: 'Email sudah dipakai',
					body: 'Alamat email tersebut kini sudah digunakan akun lain, sehingga perubahan tidak dapat diselesaikan.'
				};
			case 'invalid':
				return {
					ok: false,
					title: 'Tautan tidak valid',
					body: 'Tautan konfirmasi tidak valid atau sudah kedaluwarsa. Silakan minta perubahan email lagi.'
				};
			default:
				return {
					ok: true,
					title: 'Email berhasil diverifikasi',
					body: 'Masuk kembali atau lanjutkan ke Portal SI untuk memperbarui status sesi.'
				};
		}
	});
</script>

<svelte:head><title>{view.title} — Portal SI</title></svelte:head>
<main class:error={!view.ok}>
	{#if !view.ok}<TriangleAlert size={48} />{:else if state === 'changed'}<MailCheck
			size={48}
		/>{:else}<BadgeCheck size={48} />{/if}
	<h1>{view.title}</h1>
	<p>{view.body}</p>
	<a href="/login">Masuk ke Portal SI</a>
</main>

<style>
	main {
		display: grid;
		min-height: 100vh;
		place-content: center;
		justify-items: center;
		padding: 24px;
		background: var(--color-canvas);
		text-align: center;
		color: var(--color-secondary);
	}
	main.error {
		color: var(--color-danger);
	}
	h1 {
		margin: 16px 0 6px;
		color: var(--color-text);
		font-size: 1.5rem;
	}
	p {
		max-width: 28rem;
		margin: 0;
		color: var(--color-muted);
	}
	a {
		margin-top: 18px;
		padding: 12px 17px;
		background: var(--color-primary);
		border-radius: 11px;
		color: white;
		font-weight: 720;
	}
</style>
