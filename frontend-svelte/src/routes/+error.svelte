<script lang="ts">
	import { AlertTriangle, RefreshCw } from '@lucide/svelte';
	import { page } from '$app/state';
</script>

<svelte:head><title>{page.status} — Portal SI</title></svelte:head>

<main class="error-page">
	<img src="/assets/logo-mark.png" alt="" />
	<span><AlertTriangle size={26} /></span>
	<p class="eyebrow">Kode {page.status}</p>
	<h1>{page.status === 404 ? 'Halaman tidak ditemukan' : 'Ada yang belum beres'}</h1>
	<p>{page.error?.message ?? 'Permintaan tidak dapat diproses.'}</p>
	{#if page.error?.requestId}<small>Referensi: {page.error.requestId}</small>{/if}
	<div>
		<button onclick={() => location.reload()}><RefreshCw size={17} /> Muat ulang</button>
		<a href="/">Kembali ke awal</a>
	</div>
</main>

<style>
	.error-page {
		display: grid;
		min-height: 100vh;
		align-content: center;
		justify-items: center;
		padding: 24px;
		background: var(--color-canvas);
		text-align: center;
	}
	.error-page > img {
		width: 48px;
		height: 48px;
		margin-bottom: 28px;
		border-radius: 14px;
	}
	.error-page > span {
		display: grid;
		width: 58px;
		height: 58px;
		place-items: center;
		background: var(--color-danger-soft);
		border-radius: 18px;
		color: var(--color-danger);
	}
	h1 {
		margin: 0;
		font-size: clamp(1.8rem, 5vw, 2.7rem);
		letter-spacing: -0.045em;
	}
	.error-page > p:not(.eyebrow) {
		max-width: 32rem;
		margin: 10px 0;
		color: var(--color-muted);
	}
	small {
		color: var(--color-subtle);
	}
	.error-page > div {
		display: flex;
		gap: 9px;
		margin-top: 22px;
	}
	.error-page button,
	.error-page a {
		display: flex;
		height: 44px;
		align-items: center;
		gap: 7px;
		padding: 0 15px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 11px;
		font-weight: 680;
	}
	.error-page button {
		background: var(--color-primary);
		border-color: var(--color-primary);
		color: white;
		cursor: pointer;
	}
</style>
