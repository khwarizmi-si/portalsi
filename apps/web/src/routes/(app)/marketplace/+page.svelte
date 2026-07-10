<script lang="ts">
	import { ExternalLink, ShieldCheck, ShoppingBag } from '@lucide/svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
</script>

<svelte:head><title>Marketplace — Portal SI</title><meta name="robots" content="noindex" /></svelte:head>
<SectionPage
	eyebrow="Portal SI Marketplace"
	title="Kebutuhan komunitas, satu tempat"
	description="Marketplace berada di origin terpisah. Tautan hanya menuju alamat resmi yang sudah diizinkan."
>
	<section class="store-hero surface">
		<div>
			<span><ShoppingBag size={28} /></span>
			<h2>Kunjungi Portal SI Marketplace</h2>
			<p>Temukan buku, perlengkapan belajar, dan produk komunitas melalui situs marketplace resmi.</p>
			<a href="https://marketplace.portalsi.com/" target="_blank" rel="noopener noreferrer"
				>Buka marketplace resmi <ExternalLink size={17} /></a
			><small><ShieldCheck size={14} /> Anda akan membuka marketplace.portalsi.com</small>
		</div>
		<div class="phone-shot" aria-label="Pratinjau mobile Portal SI Marketplace">
			<div class="phone-bar"><i></i><span>9:41</span><b>● ●</b></div>
			<div class="shot-head">
				<img src="/assets/logo-mark.png" alt="" /><span
					><strong>Portal SI</strong><small>MARKETPLACE</small></span
				><ShoppingBag size={18} />
			</div>
			<div class="shot-hero">
				<small>KOLEKSI PILIHAN</small><strong>Belajar nyaman,<br />tampil bermakna.</strong><button
					>Belanja sekarang</button
				>
			</div>
			<div class="shot-categories"><span>Semua</span><span>Buku</span><span>Aksesori</span></div>
			<div class="shot-grid">
				<article><i></i><b>Notebook Portal</b><small>Rp49.000</small></article>
				<article><i></i><b>Tote Bag SI</b><small>Rp79.000</small></article>
			</div>
		</div>
	</section>
</SectionPage>

<style>
	.store-hero {
		display: grid;
		min-height: 500px;
		grid-template-columns: 1fr 1fr;
		align-items: center;
		gap: 40px;
		padding: clamp(28px, 6vw, 70px);
		overflow: hidden;
	}
	.store-hero > div:first-child > span {
		display: grid;
		width: 54px;
		height: 54px;
		place-items: center;
		background: var(--color-primary-soft);
		border-radius: 17px;
		color: var(--color-primary-strong);
	}
	h2 {
		margin: 18px 0 8px;
		font-size: clamp(1.6rem, 4vw, 2.4rem);
		letter-spacing: -0.04em;
	}
	p {
		max-width: 30rem;
		color: var(--color-muted);
	}
	a {
		display: flex;
		width: fit-content;
		height: 46px;
		align-items: center;
		gap: 8px;
		margin-top: 20px;
		padding: 0 17px;
		background: var(--color-primary);
		border-radius: 12px;
		color: white;
		font-weight: 720;
	}
	.store-hero small {
		display: flex;
		align-items: center;
		gap: 5px;
		margin-top: 12px;
		color: var(--color-muted);
	}
	.phone-shot {
		position: relative;
		width: min(100%, 310px);
		aspect-ratio: 9 / 18;
		margin: auto;
		padding: 12px;
		overflow: hidden;
		background: #fffdf8;
		border: 9px solid #191714;
		border-radius: 42px;
		box-shadow: 0 30px 70px rgb(39 27 14 / 26%);
		transform: rotate(2.5deg);
	}
	.phone-shot::before {
		position: absolute;
		z-index: 3;
		top: 8px;
		left: 50%;
		width: 84px;
		height: 20px;
		background: #191714;
		border-radius: 99px;
		content: '';
		transform: translateX(-50%);
	}
	.phone-bar,
	.shot-head,
	.shot-categories {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}
	.phone-bar {
		height: 28px;
		padding: 0 7px;
		font-size: 0.52rem;
	}
	.phone-bar b {
		font-size: 0.38rem;
		letter-spacing: 0.12em;
	}
	.shot-head {
		padding: 10px 5px;
	}
	.shot-head img {
		width: 31px;
		height: 31px;
		border-radius: 10px;
	}
	.shot-head > span {
		display: grid;
		margin-right: auto;
		margin-left: 7px;
		line-height: 1;
	}
	.shot-head strong {
		font-size: 0.68rem;
	}
	.shot-head small {
		margin-top: 3px;
		color: var(--color-primary);
		font-size: 0.42rem;
		letter-spacing: 0.16em;
	}
	.shot-hero {
		display: grid;
		min-height: 185px;
		align-content: end;
		justify-items: start;
		padding: 18px;
		background:
			radial-gradient(circle at 82% 20%, #ffe0a1, transparent 38%),
			linear-gradient(145deg, #eaf7ef, #f9e8c8);
		border-radius: 23px;
	}
	.shot-hero small {
		color: #547260;
		font-size: 0.43rem;
		font-weight: 800;
		letter-spacing: 0.12em;
	}
	.shot-hero strong {
		margin-top: 5px;
		font-size: 1.3rem;
		line-height: 1.05;
		letter-spacing: -0.04em;
	}
	.shot-hero button {
		margin-top: 12px;
		padding: 8px 10px;
		background: #191714;
		border: 0;
		border-radius: 9px;
		color: white;
		font-size: 0.52rem;
		font-weight: 750;
	}
	.shot-categories {
		justify-content: flex-start;
		gap: 6px;
		padding: 14px 1px 10px;
	}
	.shot-categories span {
		padding: 5px 9px;
		background: #f3eee5;
		border-radius: 99px;
		color: #675d51;
		font-size: 0.48rem;
	}
	.shot-categories span:first-child {
		background: #191714;
		color: white;
	}
	.shot-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 8px;
	}
	.shot-grid article {
		display: grid;
		gap: 2px;
	}
	.shot-grid article i {
		height: 92px;
		background: linear-gradient(145deg, #eee1cb, #c5d8cb);
		border-radius: 15px;
	}
	.shot-grid article:nth-child(2) i {
		background: linear-gradient(145deg, #f7dba8, #dfb46f);
	}
	.shot-grid b {
		margin-top: 4px;
		font-size: 0.52rem;
	}
	.shot-grid small {
		color: var(--color-primary-strong);
		font-size: 0.48rem;
		font-weight: 750;
	}
	@media (max-width: 767px) {
		.store-hero {
			grid-template-columns: 1fr;
			margin: 0 16px;
			padding: 28px;
		}
		.phone-shot {
			grid-row: 1;
			max-width: 250px;
			margin: auto;
		}
	}
</style>
