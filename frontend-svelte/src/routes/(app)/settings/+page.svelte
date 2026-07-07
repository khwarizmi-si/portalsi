<script lang="ts">
	import {
		Archive,
		Bell,
		Bookmark,
		ChevronRight,
		KeyRound,
		LogOut,
		ShieldCheck,
		Smartphone,
		Trash2,
		UserRound
	} from '@lucide/svelte';
	import SectionPage from '$lib/components/layout/SectionPage.svelte';
	import { confirmAction } from '$lib/ui/confirm';
	const sections = [
		{
			title: 'Akun Anda',
			items: [
				{
					label: 'Edit profil',
					desc: 'Nama, bio, foto dan banner',
					href: '/profile/edit',
					icon: UserRound
				},
				{
					label: 'Privasi akun',
					desc: 'Atur siapa yang dapat mengikuti Anda',
					href: '/settings/privacy',
					icon: ShieldCheck
				},
				{
					label: 'Ubah kata sandi',
					desc: 'Perbarui keamanan akun',
					href: '/settings/password',
					icon: KeyRound
				},
				{
					label: 'Riwayat login',
					desc: 'Lihat perangkat dan sesi',
					href: '/settings/sessions',
					icon: Smartphone
				}
			]
		},
		{
			title: 'Aktivitas',
			items: [
				{
					label: 'Postingan tersimpan',
					desc: 'Konten yang ingin dilihat lagi',
					href: '/settings/saved',
					icon: Bookmark
				},
				{
					label: 'Arsip cerita',
					desc: 'Cerita Anda yang telah berakhir',
					href: '/settings/story-archive',
					icon: Archive
				},
				{
					label: 'Preferensi notifikasi',
					desc: 'Pilih kabar yang ingin diterima',
					href: '/settings/preferences',
					icon: Bell
				}
			]
		}
	];
	async function confirmLogout(event: SubmitEvent) {
		event.preventDefault();
		const form = event.currentTarget as HTMLFormElement;
		const confirmed = await confirmAction({
			title: 'Keluar dari Portal SI?',
			description: 'Sesi di perangkat ini akan diakhiri. Draft lokal Anda tetap tersimpan.',
			confirmLabel: 'Ya, keluar',
			tone: 'danger'
		});
		if (confirmed) form.submit();
	}
</script>

<svelte:head
	><title>Pengaturan — Portal SI</title><meta name="robots" content="noindex" /></svelte:head
>
<SectionPage
	eyebrow="Kendali akun"
	title="Pengaturan"
	description="Kelola profil, keamanan, dan pengalaman Portal SI."
>
	<div class="settings-layout">
		<div class="settings-sections">
			{#each sections as section (section.title)}<section class="surface">
					<h2>{section.title}</h2>
					{#each section.items as item (item.href)}<a href={item.href}
							><span><item.icon size={19} /></span>
							<p><strong>{item.label}</strong><small>{item.desc}</small></p>
							<ChevronRight size={18} /></a
						>{/each}
				</section>{/each}
			<section class="surface danger-zone">
				<h2>Login dan akun</h2>
				<form method="POST" action="/logout" onsubmit={confirmLogout}>
					<button type="submit"
						><span><LogOut size={19} /></span>
						<p><strong>Keluar</strong><small>Akhiri sesi di perangkat ini</small></p>
						<ChevronRight size={18} /></button
					>
				</form>
				<a href="/settings/delete-account"
					><span><Trash2 size={19} /></span>
					<p>
						<strong>Hapus akun</strong><small>Tindakan permanen dan tidak dapat dibatalkan</small>
					</p>
					<ChevronRight size={18} /></a
				>
			</section>
		</div>
		<aside class="surface">
			<img src="/assets/logo-mark.png" alt="" />
			<h2>Portal SI Web</h2>
			<p>Terkoneksi dengan iman, menginspirasi dalam kebaikan.</p>
			<small>Build 2.2 · Stable</small>
		</aside>
	</div>
</SectionPage>

<style>
	.settings-layout {
		display: grid;
		grid-template-columns: minmax(0, 1fr) 280px;
		gap: 18px;
		align-items: start;
	}
	.settings-sections {
		display: grid;
		gap: 15px;
	}
	.settings-sections section {
		overflow: hidden;
	}
	.settings-sections h2 {
		margin: 0;
		padding: 15px 17px;
		border-bottom: 1px solid var(--color-border);
		font-size: 0.88rem;
	}
	.settings-sections section > a,
	.settings-sections section > form button {
		display: grid;
		width: 100%;
		grid-template-columns: auto 1fr auto;
		align-items: center;
		gap: 12px;
		min-height: 71px;
		padding: 10px 16px;
		border-bottom: 1px solid var(--color-border);
		background: transparent;
		border-top: 0;
		border-right: 0;
		border-left: 0;
		color: inherit;
		text-align: left;
		cursor: pointer;
	}
	.settings-sections section > a:last-child {
		border-bottom: 0;
	}
	.settings-sections section > a:hover,
	.settings-sections section > form button:hover {
		background: var(--color-surface-soft);
	}
	.settings-sections section > a > span,
	.settings-sections section > form button > span {
		display: grid;
		width: 39px;
		height: 39px;
		place-items: center;
		background: var(--color-primary-soft);
		border-radius: 11px;
		color: var(--color-primary-strong);
	}
	.settings-sections p {
		display: grid;
		margin: 0;
	}
	.settings-sections strong {
		font-size: 0.84rem;
	}
	.settings-sections small {
		color: var(--color-muted);
		font-size: 0.72rem;
	}
	.danger-zone a:last-child {
		color: var(--color-danger);
	}
	.danger-zone a:last-child > span {
		background: var(--color-danger-soft);
		color: var(--color-danger);
	}
	aside {
		padding: 20px;
	}
	aside img {
		width: 44px;
		height: 44px;
		border-radius: 13px;
	}
	aside h2 {
		margin: 14px 0 5px;
		font-size: 0.98rem;
	}
	aside p {
		margin: 0 0 14px;
		color: var(--color-muted);
		font-size: 0.78rem;
	}
	aside small {
		color: var(--color-subtle);
		font-size: 0.68rem;
	}
	@media (max-width: 820px) {
		.settings-layout {
			grid-template-columns: 1fr;
		}
		.settings-layout > aside {
			display: none;
		}
	}
	@media (max-width: 767px) {
		.settings-sections section {
			border-inline: 0;
			border-radius: 0;
		}
		.settings-sections {
			gap: 12px;
		}
	}
</style>
