<script lang="ts">
	import { LoaderCircle, Search, X } from '@lucide/svelte';
	import { z } from 'zod';
	import { portal } from '$lib/actions/portal';

	let { onSelect, onClose }: { onSelect: (url: string) => void; onClose: () => void } = $props();

	const gifSchema = z.object({
		results: z
			.array(
				z.object({
					id: z.string(),
					url: z.string(),
					preview: z.string(),
					width: z.number().catch(1),
					height: z.number().catch(1),
					alt: z.string().catch('GIF')
				})
			)
			.catch([])
	});
	type Gif = z.infer<typeof gifSchema>['results'][number];

	let query = $state('');
	let type = $state<'gif' | 'sticker'>('gif');
	let results = $state<Gif[]>([]);
	let loading = $state(true);
	let message = $state('');

	$effect(() => {
		const q = query.trim();
		const currentType = type;
		loading = true;
		message = '';
		const controller = new AbortController();
		const timer = window.setTimeout(async () => {
			try {
				const params = new URLSearchParams({ type: currentType });
				if (q.length >= 2) params.set('q', q);
				const response = await fetch(`/api/external/gif?${params}`, {
					signal: controller.signal,
					headers: { Accept: 'application/json' }
				});
				const payload = gifSchema.safeParse(await response.json());
				if (controller.signal.aborted) return;
				results = payload.success ? payload.data.results : [];
				if (results.length === 0) message = 'Tidak ada hasil. Coba kata kunci lain.';
			} catch (error) {
				if (!(error instanceof DOMException && error.name === 'AbortError')) {
					results = [];
					message = 'GIF sedang tidak tersedia.';
				}
			} finally {
				if (!controller.signal.aborted) loading = false;
			}
		}, 300);
		return () => {
			window.clearTimeout(timer);
			controller.abort();
		};
	});
</script>

<div use:portal>
<div class="gif-overlay" role="presentation" onclick={onClose}></div>
<section class="gif-picker" aria-label="Pilih GIF">
	<header>
		<div class="tabs">
			<button class:active={type === 'gif'} onclick={() => (type = 'gif')}>GIF</button>
			<button class:active={type === 'sticker'} onclick={() => (type = 'sticker')}>Stiker</button>
		</div>
		<button class="close" onclick={onClose} aria-label="Tutup"><X size={18} /></button>
	</header>
	<div class="search">
		<Search size={16} />
		<input placeholder={`Cari ${type === 'gif' ? 'GIF' : 'stiker'}…`} bind:value={query} />
		{#if loading}<LoaderCircle class="gif-spin" size={15} />{/if}
	</div>
	<div class="grid">
		{#each results as gif (gif.id)}
			<button
				class="tile"
				style:aspect-ratio={`${gif.width} / ${gif.height}`}
				onclick={() => onSelect(gif.url)}
			>
				<img src={gif.preview} alt={gif.alt} loading="lazy" />
			</button>
		{/each}
	</div>
	{#if !loading && results.length === 0}<p class="msg">{message || 'Tidak ada hasil.'}</p>{/if}
	<p class="attribution">Powered by GIPHY</p>
</section>
</div>

<style>
	.gif-overlay {
		position: fixed;
		inset: 0;
		z-index: 1500;
		background: rgb(20 15 10 / 30%);
	}
	.gif-picker {
		position: fixed;
		z-index: 1501;
		right: 0;
		bottom: 0;
		left: 0;
		display: flex;
		max-height: 70vh;
		flex-direction: column;
		margin: 0 auto;
		padding: 10px 12px calc(12px + var(--safe-bottom));
		background: var(--color-surface);
		border-radius: 18px 18px 0 0;
		box-shadow: 0 -16px 40px rgb(0 0 0 / 20%);
	}
	header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding-bottom: 8px;
	}
	.tabs {
		display: flex;
		gap: 4px;
		padding: 3px;
		background: var(--color-canvas-deep, #f1ece3);
		border-radius: 10px;
	}
	.tabs button {
		padding: 6px 16px;
		background: transparent;
		border: 0;
		border-radius: 8px;
		font-size: 0.78rem;
		font-weight: 700;
		color: var(--color-muted);
	}
	.tabs button.active {
		background: var(--color-surface);
		color: var(--color-primary-strong);
		box-shadow: var(--shadow-sm);
	}
	.close {
		display: grid;
		width: 32px;
		height: 32px;
		place-items: center;
		border: 0;
		border-radius: 50%;
		background: var(--color-canvas-deep, #f1ece3);
		color: var(--color-muted);
	}
	.search {
		display: flex;
		height: 40px;
		align-items: center;
		gap: 8px;
		padding: 0 12px;
		background: var(--color-canvas-deep, #f4efe6);
		border: 1px solid var(--color-border);
		border-radius: 11px;
		color: var(--color-muted);
	}
	.search input {
		flex: 1;
		min-width: 0;
		background: transparent;
		border: 0;
		outline: 0;
		font-size: 0.85rem;
	}
	:global(.gif-picker .gif-spin) {
		color: var(--color-primary);
		animation: gif-spin 0.8s linear infinite;
	}
	@keyframes gif-spin {
		to {
			transform: rotate(360deg);
		}
	}
	.grid {
		flex: 1;
		overflow-y: auto;
		columns: 3;
		column-gap: 6px;
		margin-top: 10px;
	}
	.tile {
		display: block;
		width: 100%;
		margin-bottom: 6px;
		padding: 0;
		overflow: hidden;
		background: var(--color-canvas-deep, #efe9df);
		border: 0;
		border-radius: 10px;
		break-inside: avoid;
		cursor: pointer;
	}
	.tile img {
		width: 100%;
		display: block;
	}
	.msg {
		padding: 24px;
		color: var(--color-muted);
		font-size: 0.8rem;
		text-align: center;
	}
	.attribution {
		margin: 6px 0 0;
		color: var(--color-subtle, #a99);
		font-size: 0.62rem;
		text-align: center;
	}
	@media (min-width: 620px) {
		.gif-picker {
			right: auto;
			left: 50%;
			bottom: auto;
			top: 50%;
			width: 420px;
			max-height: 76vh;
			transform: translate(-50%, -50%);
			border-radius: 16px;
		}
	}
</style>
