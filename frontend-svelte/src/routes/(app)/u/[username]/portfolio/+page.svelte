<script lang="ts">
	import { FileText } from '@lucide/svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import type { PageProps } from './$types';
	let { data }: PageProps = $props();
	const labels = { quran: 'Al-Qur’an', it: 'Teknologi', bahasa: 'Bahasa', karakter: 'Karakter' };
</script>

<svelte:head><title>Portfolio {data.user.fullName} — Portal SI</title></svelte:head><SectionPage
	eyebrow={`@${data.user.username}`}
	title={`Portfolio ${data.user.fullName}`}
	description="Karya dan pencapaian yang dibagikan di Portal SI."
	><section class="grid">
		{#each data.items as item (item.id)}<article class="surface">
				{#if item.mediaUrl}{#if item.mediaUrl.toLowerCase().includes('.pdf')}<a
							href={item.mediaUrl}
							target="_blank"
							rel="noreferrer"><FileText size={28} />PDF</a
						>{:else}<img src={item.mediaUrl} alt={item.title} />{/if}{/if}
				<div>
					<small>{labels[item.aspect]} · {item.year || '—'}</small>
					<h2>{item.title}</h2>
					<p>{item.description || 'Tanpa deskripsi.'}</p>
				</div>
			</article>{/each}
	</section>
	{#if data.items.length === 0}<p class="empty surface">Belum ada portfolio.</p>{/if}</SectionPage
>

<style>
	.grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 14px;
	}
	.grid article {
		overflow: hidden;
	}
	.grid img,
	.grid article > a {
		width: 100%;
		aspect-ratio: 4/3;
		object-fit: cover;
	}
	.grid article > a {
		display: grid;
		place-content: center;
		justify-items: center;
		gap: 5px;
		background: var(--color-secondary-soft);
		color: var(--color-secondary);
	}
	.grid article > div {
		padding: 14px;
	}
	.grid small {
		color: var(--color-primary-strong);
		font-size: 0.68rem;
	}
	.grid h2 {
		margin: 5px 0;
		font-size: 0.94rem;
	}
	.grid p {
		margin: 0;
		color: var(--color-muted);
		font-size: 0.75rem;
	}
	.empty {
		padding: 40px;
		color: var(--color-muted);
		text-align: center;
	}
	@media (max-width: 750px) {
		.grid {
			grid-template-columns: repeat(2, 1fr);
			padding-inline: 12px;
		}
	}
</style>
