<script lang="ts">
	import {
		AlertTriangle,
		Ban,
		Clock,
		Home,
		LockKeyhole,
		RefreshCw,
		SearchX,
		ServerCrash,
		Wifi
	} from '@lucide/svelte';
	import { page } from '$app/state';

	type Info = {
		title: string;
		hint: string;
		icon: typeof AlertTriangle;
		tone: 'danger' | 'warn' | 'muted';
	};

	const map: Record<number, Info> = {
		400: {
			title: 'Permintaan tidak valid',
			hint: 'Ada data yang tidak sesuai. Coba ulangi.',
			icon: AlertTriangle,
			tone: 'warn'
		},
		401: {
			title: 'Perlu masuk dulu',
			hint: 'Sesi Anda berakhir atau belum masuk.',
			icon: LockKeyhole,
			tone: 'warn'
		},
		403: {
			title: 'Akses ditolak',
			hint: 'Anda tidak memiliki izin untuk halaman ini.',
			icon: Ban,
			tone: 'danger'
		},
		404: {
			title: 'Tidak ditemukan',
			hint: 'Halaman, pengguna, atau konten ini tidak ada / sudah dihapus.',
			icon: SearchX,
			tone: 'muted'
		},
		408: {
			title: 'Permintaan kehabisan waktu',
			hint: 'Koneksi terlalu lama merespons.',
			icon: Clock,
			tone: 'warn'
		},
		429: {
			title: 'Terlalu banyak permintaan',
			hint: 'Anda terlalu cepat. Tunggu sebentar lalu coba lagi.',
			icon: Clock,
			tone: 'warn'
		},
		500: {
			title: 'Terjadi kesalahan server',
			hint: 'Ada masalah di sisi kami. Tim akan menanganinya.',
			icon: ServerCrash,
			tone: 'danger'
		},
		502: {
			title: 'Gateway bermasalah',
			hint: 'Layanan hulu sedang tidak merespons.',
			icon: ServerCrash,
			tone: 'danger'
		},
		503: {
			title: 'Layanan sedang tidak tersedia',
			hint: 'Server sibuk atau sedang perawatan. Coba lagi sebentar.',
			icon: Wifi,
			tone: 'warn'
		},
		504: {
			title: 'Gateway kehabisan waktu',
			hint: 'Server terlalu lama merespons.',
			icon: Clock,
			tone: 'warn'
		}
	};

	const info = $derived(
		map[page.status] ?? {
			title: 'Ada yang belum beres',
			hint: 'Permintaan tidak dapat diproses saat ini.',
			icon: AlertTriangle,
			tone: 'danger' as const
		}
	);
	const detail = $derived(page.error?.message?.trim() || info.hint);
	const requestId = $derived(
		(page.error as { requestId?: string } | null)?.requestId ?? undefined
	);
	const nextPath = $derived(page.url.pathname + page.url.search);
</script>

<svelte:head><title>{page.status} · {info.title} — Portal SI</title></svelte:head>

<main class="error-page">
	<img src="/assets/logo-mark.png" alt="" />
	<span class={`badge ${info.tone}`}><info.icon size={28} /></span>
	<p class="eyebrow">Kode {page.status}</p>
	<h1>{info.title}</h1>
	<p class="detail">{detail}</p>
	{#if requestId}<small class="ref">Referensi: {requestId}</small>{/if}
	<div class="actions">
		{#if page.status === 401 || page.status === 403}
			<a class="primary" href={`/login?next=${encodeURIComponent(nextPath)}`}>Masuk</a>
		{:else}
			<button class="primary" onclick={() => location.reload()}
				><RefreshCw size={17} /> Muat ulang</button
			>
		{/if}
		<a href="/home"><Home size={16} /> Beranda</a>
	</div>
</main>

<style>
	.error-page {
		display: grid;
		min-height: 100dvh;
		align-content: center;
		justify-items: center;
		padding: 24px;
		background:
			radial-gradient(circle at 50% 30%, rgb(180 71 0 / 6%), transparent 22rem),
			var(--color-canvas);
		text-align: center;
	}
	.error-page > img {
		width: 44px;
		height: 44px;
		margin-bottom: 26px;
		border-radius: 13px;
	}
	.badge {
		display: grid;
		width: 60px;
		height: 60px;
		place-items: center;
		border-radius: 18px;
	}
	.badge.danger {
		background: var(--color-danger-soft);
		color: var(--color-danger);
	}
	.badge.warn {
		background: var(--color-primary-soft);
		color: var(--color-primary-strong);
	}
	.badge.muted {
		background: var(--color-surface-soft);
		color: var(--color-muted);
	}
	.eyebrow {
		margin: 16px 0 2px;
		color: var(--color-muted);
		font-size: 0.72rem;
		font-weight: 720;
		letter-spacing: 0.14em;
		text-transform: uppercase;
	}
	h1 {
		margin: 0;
		font-size: clamp(1.7rem, 5vw, 2.5rem);
		letter-spacing: -0.045em;
	}
	.detail {
		max-width: 34rem;
		margin: 10px 0 0;
		color: var(--color-muted);
		font-size: 0.92rem;
		line-height: 1.5;
		overflow-wrap: anywhere;
		white-space: pre-wrap;
	}
	.ref {
		margin-top: 8px;
		color: var(--color-subtle);
		font-size: 0.72rem;
		font-family: ui-monospace, monospace;
	}
	.actions {
		display: flex;
		flex-wrap: wrap;
		gap: 9px;
		justify-content: center;
		margin-top: 24px;
	}
	.actions button,
	.actions a {
		display: flex;
		height: 44px;
		align-items: center;
		gap: 7px;
		padding: 0 16px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 11px;
		color: var(--color-text);
		font-weight: 690;
		cursor: pointer;
	}
	.actions .primary {
		background: var(--color-primary);
		border-color: var(--color-primary);
		color: white;
	}
</style>
