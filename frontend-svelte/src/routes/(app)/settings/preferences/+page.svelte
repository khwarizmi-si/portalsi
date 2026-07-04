<script lang="ts">
	import { onMount } from 'svelte';
	let interactions = $state(true);
	let messages = $state(true);
	let announcements = $state(true);
	let saved = $state(false);
	let status = $state('');
	onMount(() => {
		try {
			const value = JSON.parse(
				localStorage.getItem('portal-si-notification-preferences') || '{}'
			) as Record<string, boolean>;
			interactions = value.interactions ?? true;
			messages = value.messages ?? true;
			announcements = value.announcements ?? true;
		} catch {
			/**/
		}
	});
	function save() {
		localStorage.setItem(
			'portal-si-notification-preferences',
			JSON.stringify({ interactions, messages, announcements })
		);
		saved = true;
		status = 'Preferensi lokal disimpan di perangkat ini.';
	}
</script>

<svelte:head><title>Preferensi notifikasi — Portal SI</title></svelte:head>
<main class="preferences surface">
	<a href="/settings">← Pengaturan</a>
	<h1>Preferensi notifikasi</h1>
	<p>
		Saat ini preferensi notifikasi hanya disimpan di perangkat ini. Sinkronisasi ke akun akan tersedia setelah didukung oleh server di update mendatang.
	</p>
	<form
		onsubmit={(e) => {
			e.preventDefault();
			save();
		}}
	>
		<label
			><input type="checkbox" bind:checked={interactions} /><span
				><strong>Interaksi</strong><small>Like, komentar, mention, dan pengikut.</small></span
			></label
		><label
			><input type="checkbox" bind:checked={messages} /><span
				><strong>Pesan</strong><small>Direct message dan aktivitas grup.</small></span
			></label
		><label
			><input type="checkbox" bind:checked={announcements} /><span
				><strong>Pengumuman</strong><small>Kabar terbaru dari Portal SI.</small></span
			></label
		><button>Simpan di perangkat</button>{#if saved}<p aria-live="polite">{status}</p>{/if}
	</form>
</main>

<style>
	.preferences {
		width: min(100% - 32px, 600px);
		margin: 28px auto;
		padding: 24px;
	}
	.preferences > a {
		color: var(--color-primary-strong);
		font-size: 0.78rem;
		font-weight: 700;
	}
	h1 {
		margin: 18px 0 6px;
		font-size: 1.3rem;
	}
	.preferences > p {
		color: var(--color-muted);
		font-size: 0.78rem;
	}
	form {
		display: grid;
		gap: 10px;
		margin-top: 20px;
	}
	label {
		display: flex;
		gap: 10px;
		padding: 14px;
		background: var(--color-surface-soft);
		border: 1px solid var(--color-border);
		border-radius: 11px;
	}
	label input {
		margin-top: 3px;
	}
	label span {
		display: grid;
	}
	label strong {
		font-size: 0.82rem;
	}
	label small {
		color: var(--color-muted);
		font-size: 0.7rem;
	}
	button {
		min-height: 44px;
		margin-top: 8px;
		background: var(--color-primary);
		border: 0;
		border-radius: 11px;
		color: white;
		font-weight: 720;
	}
	form > p {
		margin: 0;
		color: var(--color-secondary);
		font-size: 0.75rem;
		text-align: center;
	}
	@media (max-width: 767px) {
		.preferences {
			width: 100%;
			margin: 0;
			border: 0;
			border-radius: 0;
		}
	}
</style>
