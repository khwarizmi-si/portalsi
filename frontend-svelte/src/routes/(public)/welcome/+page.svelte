<script lang="ts">
	import { ArrowRight, ShieldCheck, Sparkles, Users } from '@lucide/svelte';
</script>

<svelte:head><title>Portal SI — Tumbuh bersama</title></svelte:head>
<main class="welcome">
	<header>
		<a href="/welcome"><img src="/assets/logo-mark.png" alt="" /><strong>Portal SI</strong></a>
		<nav><a href="/login">Masuk</a><a class="primary" href="/register">Buat akun</a></nav>
	</header>
	<section class="hero">
		<div>
			<p class="eyebrow">Ruang digital komunitas sekolah</p>
			<h1>Berbagi kabar.<br /><em>Menjaga kedekatan.</em></h1>
			<p>
				Portal SI mempertemukan siswa, guru, dan orang tua dalam satu ruang yang hangat untuk
				belajar dan bertumbuh.
			</p>
			<div class="hero-actions">
				<a href="/register">Mulai sekarang <ArrowRight size={18} /></a><a href="/login"
					>Saya sudah punya akun</a
				>
			</div>
			<div class="trust">
				<span><ShieldCheck size={16} /> Sesi aman</span><span
					><Users size={16} /> Komunitas terverifikasi</span
				>
			</div>
		</div>
		<div class="visual">
			<div class="card-one">
				<img src="/assets/images/register.webp" alt="Ilustrasi komunitas Portal SI" />
			</div>
			<div class="floating">
				<Sparkles size={18} /><span
					><strong>Ruang untuk karya</strong><small>Belajar dan berbagi bersama</small></span
				>
			</div>
		</div>
	</section>
</main>

<style>
	.welcome {
		min-height: 100vh;
		padding: 20px clamp(20px, 5vw, 72px);
		background:
			radial-gradient(circle at 85% 5%, rgb(8 127 114 / 14%), transparent 30rem),
			var(--color-canvas);
	}
	header {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}
	header > a {
		display: flex;
		align-items: center;
		gap: 9px;
		font-size: 1.1rem;
	}
	header img {
		width: 38px;
		height: 38px;
		border-radius: 11px;
	}
	nav {
		display: flex;
		gap: 8px;
	}
	nav a {
		display: flex;
		height: 42px;
		align-items: center;
		padding: 0 15px;
		border-radius: 11px;
		font-size: 0.8rem;
		font-weight: 700;
	}
	nav .primary {
		background: var(--color-primary);
		color: white;
	}
	.hero {
		display: grid;
		min-height: calc(100vh - 100px);
		grid-template-columns: 1fr minmax(360px, 0.85fr);
		align-items: center;
		gap: clamp(30px, 7vw, 100px);
		padding: 40px 0;
	}
	.hero h1 {
		margin: 0;
		font-size: clamp(3rem, 7vw, 6rem);
		letter-spacing: -0.065em;
		line-height: 0.95;
	}
	.hero h1 em {
		color: var(--color-primary);
		font-style: normal;
	}
	.hero > div:first-child > p:not(.eyebrow) {
		max-width: 39rem;
		margin: 24px 0;
		color: var(--color-muted);
		font-size: clamp(0.95rem, 1.5vw, 1.15rem);
	}
	.hero-actions {
		display: flex;
		gap: 10px;
	}
	.hero-actions a {
		display: flex;
		height: 48px;
		align-items: center;
		gap: 8px;
		padding: 0 17px;
		border: 1px solid var(--color-border-strong);
		border-radius: 12px;
		font-size: 0.82rem;
		font-weight: 720;
	}
	.hero-actions a:first-child {
		background: var(--color-primary);
		border-color: var(--color-primary);
		color: white;
	}
	.trust {
		display: flex;
		gap: 18px;
		margin-top: 24px;
		color: var(--color-muted);
		font-size: 0.72rem;
	}
	.trust span {
		display: flex;
		align-items: center;
		gap: 5px;
	}
	.visual {
		position: relative;
	}
	.card-one {
		overflow: hidden;
		border: 10px solid white;
		border-radius: 34px;
		box-shadow: var(--shadow-md);
		transform: rotate(2.5deg);
	}
	.card-one img {
		width: 100%;
		aspect-ratio: 4/5;
		object-fit: cover;
	}
	.floating {
		position: absolute;
		right: -20px;
		bottom: 40px;
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 13px 15px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 15px;
		box-shadow: var(--shadow-md);
		color: var(--color-secondary);
	}
	.floating span {
		display: grid;
	}
	.floating strong {
		color: var(--color-text);
		font-size: 0.78rem;
	}
	.floating small {
		color: var(--color-muted);
		font-size: 0.68rem;
	}
	@media (max-width: 800px) {
		.welcome {
			padding: 16px 20px;
		}
		.hero {
			grid-template-columns: 1fr;
			padding: 80px 0 30px;
		}
		.hero h1 {
			font-size: clamp(3rem, 14vw, 5rem);
		}
		.visual {
			display: none;
		}
	}
	@media (max-width: 480px) {
		header nav a:first-child {
			display: none;
		}
		.hero-actions {
			display: grid;
		}
		.trust {
			display: grid;
			gap: 7px;
		}
	}
</style>
