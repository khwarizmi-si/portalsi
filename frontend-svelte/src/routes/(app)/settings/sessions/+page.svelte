<script lang="ts">
	import { MonitorSmartphone, Trash2 } from '@lucide/svelte';
	import { untrack } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import type { PageProps } from './$types';
	let { data }: PageProps = $props();
	let sessions = $state(untrack(() => [...data.sessions]));
	let message = $state('');
	async function remove(id: number) {
		message = '';
		try {
			await clientRequest(`login-histories/${id}`, { method: 'DELETE' });
			sessions = sessions.filter((item) => item.id !== id);
		} catch (error) {
			message = error instanceof Error ? error.message : 'Riwayat belum dapat dihapus.';
		}
	}
</script>

<svelte:head><title>Riwayat login — Portal SI</title></svelte:head>
<SectionPage
	eyebrow="Keamanan"
	title="Riwayat login"
	description="Sesi lebih baru dari tujuh hari tidak dapat dicabut oleh backend."
	><div class="sessions surface">
		{#each sessions as item (item.id)}<article>
				<span><MonitorSmartphone size={20} /></span>
				<div>
					<strong>{item.device || 'Perangkat tidak dikenal'} · {item.browser || 'Browser'}</strong
					><small
						>{item.platform || 'Platform tidak diketahui'} · {item.ip_address ||
							'IP tidak tersedia'}</small
					><time>{new Date(item.login_at).toLocaleString('id-ID')}</time>
				</div>
				<button onclick={() => remove(item.id)} aria-label="Hapus riwayat"
					><Trash2 size={17} /></button
				>
			</article>{/each}{#if sessions.length === 0}<p>
				Belum ada riwayat login.
			</p>{/if}{#if message}<p aria-live="polite">{message}</p>{/if}
	</div></SectionPage
>

<style>
	.sessions {
		overflow: hidden;
	}
	.sessions article {
		display: grid;
		grid-template-columns: auto 1fr auto;
		align-items: center;
		gap: 12px;
		padding: 14px 16px;
		border-bottom: 1px solid var(--color-border);
	}
	article > span {
		display: grid;
		width: 42px;
		height: 42px;
		place-items: center;
		background: var(--color-primary-soft);
		border-radius: 12px;
		color: var(--color-primary-strong);
	}
	article div {
		display: grid;
	}
	article strong {
		font-size: 0.82rem;
	}
	article small,
	article time,
	.sessions > p {
		color: var(--color-muted);
		font-size: 0.7rem;
	}
	article button {
		display: grid;
		width: 38px;
		height: 38px;
		place-items: center;
		background: transparent;
		border: 0;
		color: var(--color-danger);
	}
	.sessions > p {
		padding: 24px;
		text-align: center;
	}
</style>
