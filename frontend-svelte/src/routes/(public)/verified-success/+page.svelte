<script lang="ts">
	import { BadgeCheck } from '@lucide/svelte';
</script>

<svelte:head><title>Email terverifikasi — Portal SI</title></svelte:head>
<main>
	<BadgeCheck size={48} />
	<h1>Email berhasil diverifikasi</h1>
	<p>Masuk kembali atau lanjutkan ke Portal SI untuk memperbarui status sesi.</p>
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
