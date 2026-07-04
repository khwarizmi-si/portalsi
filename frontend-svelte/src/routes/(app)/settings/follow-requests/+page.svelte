<script lang="ts">
	import { Check, X } from '@lucide/svelte';
	import { untrack } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import Avatar from '$lib/components/ui/Avatar.svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import type { PageProps } from './$types';
	let { data }: PageProps = $props();
	let requests = $state(untrack(() => [...data.requests]));
	let message = $state('');
	async function decide(id: number, accept: boolean) {
		message = '';
		try {
			await clientRequest(`followers/${id}/${accept ? 'accept' : 'reject'}`, { method: 'POST' });
			requests = requests.filter((item) => item.id !== id);
			message = accept ? 'Permintaan diterima.' : 'Permintaan ditolak.';
		} catch (error) {
			message = error instanceof Error ? error.message : 'Permintaan belum dapat diproses.';
		}
	}
</script>

<svelte:head><title>Permintaan pengikut — Portal SI</title></svelte:head><SectionPage
	eyebrow="Akun privat"
	title="Permintaan pengikut"
	description="Terima atau tolak orang yang ingin mengikuti akun Anda."
	><section class="requests surface">
		{#if !data.isPrivate}<p>
				Akun Anda tidak privat, sehingga tidak ada antrean persetujuan.
			</p>{:else}{#each requests as user (user.id)}<article>
					<Avatar name={user.fullName} size="md" /><a href={`/u/${user.username}`}
						><strong>{user.fullName}</strong><small>@{user.username}</small></a
					><button onclick={() => decide(user.id, true)} aria-label={`Terima ${user.fullName}`}
						><Check size={17} /></button
					><button
						class="reject"
						onclick={() => decide(user.id, false)}
						aria-label={`Tolak ${user.fullName}`}><X size={17} /></button
					>
				</article>{/each}{#if requests.length === 0}<p>
					Tidak ada permintaan menunggu.
				</p>{/if}{/if}{#if message}<p aria-live="polite">{message}</p>{/if}
	</section></SectionPage
>

<style>
	.requests {
		overflow: hidden;
	}
	.requests article {
		display: grid;
		grid-template-columns: auto 1fr auto auto;
		align-items: center;
		gap: 9px;
		padding: 12px 15px;
		border-bottom: 1px solid var(--color-border);
	}
	article > a {
		display: grid;
	}
	article strong {
		font-size: 0.82rem;
	}
	article small {
		color: var(--color-muted);
		font-size: 0.7rem;
	}
	article button {
		display: grid;
		width: 38px;
		height: 38px;
		place-items: center;
		background: var(--color-secondary);
		border: 0;
		border-radius: 10px;
		color: white;
	}
	.reject {
		background: var(--color-danger-soft);
		color: var(--color-danger);
	}
	.requests > p {
		padding: 28px;
		color: var(--color-muted);
		font-size: 0.76rem;
		text-align: center;
	}
</style>
