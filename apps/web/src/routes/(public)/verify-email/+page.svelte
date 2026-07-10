<script lang="ts">
	import { MailCheck, RefreshCw } from '@lucide/svelte';
	import type { PageProps } from './$types';
	let { data, form }: PageProps = $props();
</script>

<svelte:head><title>Verifikasi email — Portal SI</title></svelte:head>

<main class="verify-page">
	<a class="brand" href="/welcome"><img src="/assets/logo-mark.png" alt="" /><b>Portal SI</b></a>
	<section class="surface">
		<span class="icon"><MailCheck size={30} /></span>
		<p class="eyebrow">Satu langkah lagi</p>
		<h1>Verifikasi email Anda</h1>
		{#if data.user.email}
			<p>
				Kami mengirim tautan verifikasi ke <strong>{data.user.email}</strong>. Buka tautan tersebut
				sebelum membuat konten atau berinteraksi.
			</p>
			<form method="POST" action="?/resend">
				<button><RefreshCw size={17} /> Kirim ulang email</button>
			</form>
		{:else}
			<p>Akun ini belum memiliki email. Tambahkan email yang dapat Anda akses untuk melanjutkan.</p>
			<form class="bind" method="POST" action="?/bind">
				<label
					><span class="sr-only">Email</span><input
						name="email"
						type="email"
						placeholder="nama@contoh.id"
						required
					/></label
				><button>Tambahkan email</button>
			</form>
		{/if}
		{#if form?.message}<div
				class:success={form.success}
				class="status"
				role={form.success ? 'status' : 'alert'}
			>
				{form.message}
			</div>{/if}
		<small>Sudah memverifikasi? <a href="/verify-email">Cek ulang status verifikasi</a></small>
	</section>
	<form method="POST" action="/logout"><button class="logout">Keluar dari akun</button></form>
</main>

<style>
	.verify-page {
		display: grid;
		min-height: 100vh;
		align-content: center;
		justify-items: center;
		padding: 24px;
		background:
			radial-gradient(circle at 80% 10%, rgb(8 127 114 / 10%), transparent 28rem),
			var(--color-canvas);
	}
	.brand {
		display: flex;
		align-items: center;
		gap: 9px;
		margin-bottom: 22px;
	}
	.brand img {
		width: 40px;
		height: 40px;
		border-radius: 12px;
	}
	.verify-page > section {
		display: grid;
		width: min(100%, 480px);
		justify-items: center;
		padding: 32px;
		text-align: center;
	}
	.icon {
		display: grid;
		width: 64px;
		height: 64px;
		margin-bottom: 18px;
		place-items: center;
		background: var(--color-secondary-soft);
		border-radius: 20px;
		color: var(--color-secondary);
	}
	h1 {
		margin: 0;
		font-size: clamp(1.7rem, 6vw, 2.25rem);
		letter-spacing: -0.04em;
	}
	.verify-page section > p:not(.eyebrow) {
		margin: 11px 0 22px;
		color: var(--color-muted);
		font-size: 0.88rem;
	}
	.verify-page section form button,
	.bind button {
		display: flex;
		height: 44px;
		align-items: center;
		gap: 7px;
		padding: 0 15px;
		background: var(--color-primary);
		border: 0;
		border-radius: 11px;
		color: white;
		font-weight: 700;
		cursor: pointer;
	}
	.bind {
		display: flex;
		width: 100%;
		gap: 8px;
	}
	.bind label {
		flex: 1;
	}
	.bind input {
		width: 100%;
		height: 44px;
		padding: 0 12px;
		border: 1px solid var(--color-border);
		border-radius: 11px;
	}
	.status {
		margin-top: 16px;
		padding: 9px 11px;
		background: var(--color-danger-soft);
		border-radius: 9px;
		color: var(--color-danger);
		font-size: 0.75rem;
	}
	.status.success {
		background: var(--color-secondary-soft);
		color: var(--color-secondary);
	}
	section small {
		margin-top: 20px;
		color: var(--color-muted);
	}
	section small a {
		color: var(--color-primary-strong);
		font-weight: 700;
	}
	.logout {
		margin-top: 14px;
		background: transparent;
		border: 0;
		color: var(--color-muted);
		cursor: pointer;
	}
</style>
