<script lang="ts">
	import type { Snippet } from 'svelte';
	import { ArrowLeft, Quote } from '@lucide/svelte';
	let { children, mode = 'login' }: { children: Snippet; mode?: 'login' | 'register' | 'simple' } =
		$props();
</script>

<main class="auth-shell">
	<section class="auth-visual" aria-label="Tentang Portal SI">
		<a class="brand" href="/welcome"
			><img src="/assets/logo-mark.png" alt="" /><span>Portal <b>SI</b></span></a
		>
		<div class="visual-copy">
			<span class="quote"><Quote size={22} fill="currentColor" /></span>
			<p>
				{mode === 'register'
					? 'Satu ruang untuk karya, percakapan, dan perjalanan belajar yang layak diingat.'
					: 'Bertumbuh tidak pernah benar-benar sendirian. Ada komunitas yang ikut menjaga langkah.'}
			</p>
			<small>Ruang digital keluarga besar Portal SI</small>
		</div>
		<img
			class="visual-image"
			src={mode === 'register' ? '/assets/images/register.webp' : '/assets/images/login.webp'}
			alt=""
		/>
	</section>

	<section class="form-side">
		<a class="back" href="/welcome"><ArrowLeft size={17} /> Kembali</a>
		<div class="mobile-brand"><img src="/assets/logo-mark.png" alt="" /><b>Portal SI</b></div>
		<div class="form-wrap">{@render children()}</div>
	</section>
</main>

<style>
	.auth-shell {
		display: grid;
		min-height: 100vh;
		background: var(--color-surface);
	}

	.auth-visual {
		position: relative;
		display: none;
		overflow: hidden;
		padding: 36px;
		background: #1f1a15;
		color: white;
	}

	.auth-visual::after {
		position: absolute;
		inset: 0;
		background: linear-gradient(180deg, rgb(25 18 12 / 5%), rgb(25 18 12 / 40%));
		content: '';
	}

	.brand,
	.mobile-brand {
		position: relative;
		z-index: 2;
		display: flex;
		align-items: center;
		gap: 10px;
		font-size: 1.3rem;
		font-weight: 720;
		letter-spacing: -0.03em;
	}

	.brand img,
	.mobile-brand img {
		width: 40px;
		height: 40px;
		border-radius: 12px;
	}

	.brand b {
		color: #ffaf36;
	}

	.visual-copy {
		position: relative;
		z-index: 2;
		max-width: 33rem;
		align-self: end;
		margin-bottom: 30px;
	}

	.quote {
		display: grid;
		width: 44px;
		height: 44px;
		place-items: center;
		background: rgb(255 255 255 / 15%);
		border: 1px solid rgb(255 255 255 / 20%);
		border-radius: 14px;
		color: #ffc35e;
	}

	.visual-copy p {
		margin: 18px 0 14px;
		font-size: clamp(1.6rem, 3vw, 2.7rem);
		font-weight: 680;
		letter-spacing: -0.04em;
		line-height: 1.12;
	}

	.visual-copy small {
		color: rgb(255 255 255 / 70%);
	}

	.visual-image {
		position: absolute;
		inset: 0;
		width: 100%;
		height: 100%;
		object-fit: cover;
		opacity: 0.58;
	}

	.form-side {
		display: flex;
		min-width: 0;
		flex-direction: column;
		padding: 24px 20px;
		background:
			radial-gradient(circle at 100% 0%, rgb(8 127 114 / 8%), transparent 22rem),
			var(--color-surface-soft);
	}

	.back {
		display: flex;
		width: fit-content;
		min-height: 40px;
		align-items: center;
		gap: 6px;
		color: var(--color-muted);
		font-size: 0.83rem;
		font-weight: 650;
	}

	.mobile-brand {
		margin: 34px auto 24px;
		font-size: 1.1rem;
	}

	.form-wrap {
		width: 100%;
		max-width: 430px;
		margin: auto;
	}

	@media (min-width: 900px) {
		.auth-shell {
			grid-template-columns: minmax(430px, 1.08fr) minmax(460px, 0.92fr);
		}

		.auth-visual {
			display: grid;
		}

		.form-side {
			padding: 32px clamp(32px, 5vw, 72px);
		}

		.mobile-brand {
			display: none;
		}
	}
</style>
