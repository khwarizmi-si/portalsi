<script lang="ts">
	import { ExternalLink, ShieldCheck, ShoppingBag } from '@lucide/svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
</script>

<svelte:head><title>Store — Portal SI</title><meta name="robots" content="noindex" /></svelte:head>
<SectionPage
	eyebrow="Portal SI Store"
	title="Kebutuhan komunitas, satu tempat"
	description="Store berada di origin terpisah. Tautan hanya menuju alamat resmi yang sudah diizinkan."
>
	<section class="store-hero surface">
		<div>
			<span><ShoppingBag size={28} /></span>
			<h2>Kunjungi Portal SI Store</h2>
			<p>Temukan buku, perlengkapan belajar, dan produk komunitas melalui situs store resmi.</p>
			<a href="https://store.portalsi.com/" target="_blank" rel="noopener noreferrer"
				>Buka store resmi <ExternalLink size={17} /></a
			><small><ShieldCheck size={14} /> Anda akan membuka store.portalsi.com</small>
		</div>
		<div class="store-art"><span>PORTAL</span><strong>SI</strong><i>STORE</i></div>
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
	.store-art {
		position: relative;
		display: grid;
		aspect-ratio: 1;
		place-content: center;
		background:
			radial-gradient(circle at 30% 20%, #ffd990, transparent 40%),
			linear-gradient(145deg, #322217, #0d6f67);
		border-radius: 32px;
		box-shadow: var(--shadow-md);
		color: white;
		text-align: center;
		transform: rotate(3deg);
	}
	.store-art span {
		font-size: 1.4rem;
		letter-spacing: 0.22em;
	}
	.store-art strong {
		color: #ffad2f;
		font-size: 5rem;
		line-height: 1;
	}
	.store-art i {
		font-size: 1rem;
		letter-spacing: 0.5em;
	}
	@media (max-width: 767px) {
		.store-hero {
			grid-template-columns: 1fr;
			margin: 0 16px;
			padding: 28px;
		}
		.store-art {
			grid-row: 1;
			max-width: 280px;
			margin: auto;
		}
	}
</style>
