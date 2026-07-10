<script lang="ts">
	import { untrack } from 'svelte';
	import { clientRequest } from '$lib/api/client';
	import {
		notificationPreferencesResponseSchema,
		type NotificationPreferences
	} from '$lib/schemas/notification';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	let newPostReminders = $state<NotificationPreferences['new_post_reminders']>(
		untrack(() => data.preferences.new_post_reminders)
	);
	let likes = $state(untrack(() => data.preferences.likes));
	let comments = $state(untrack(() => data.preferences.comments));
	let mentions = $state(untrack(() => data.preferences.mentions));
	let follows = $state(untrack(() => data.preferences.follows));

	let saving = $state(false);
	let status = $state('');
	let statusOk = $state(true);

	const newPostOptions = [
		{ value: 'all', label: 'Semua', hint: 'Dari semua orang yang saya ikuti.' },
		{
			value: 'mutual',
			label: 'Saling mengikuti',
			hint: 'Hanya dari akun yang juga mengikuti saya.'
		},
		{ value: 'off', label: 'Nonaktif', hint: 'Jangan beri tahu saat mereka memposting.' }
	] as const;

	async function save() {
		if (saving) return;
		saving = true;
		status = '';
		try {
			const response = await clientRequest('notifications/preferences', {
				method: 'PUT',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					new_post_reminders: newPostReminders,
					likes,
					comments,
					mentions,
					follows
				}),
				schema: notificationPreferencesResponseSchema
			});
			const p = response.preferences;
			newPostReminders = p.new_post_reminders;
			likes = p.likes;
			comments = p.comments;
			mentions = p.mentions;
			follows = p.follows;
			statusOk = true;
			status = 'Preferensi notifikasi tersimpan ke akun Anda.';
		} catch {
			statusOk = false;
			status = 'Preferensi belum dapat disimpan. Coba lagi.';
		} finally {
			saving = false;
		}
	}
</script>

<svelte:head><title>Preferensi notifikasi — Portal SI</title></svelte:head>

<main class="preferences surface">
	<a class="back" href="/settings">← Pengaturan</a>
	<h1>Preferensi notifikasi</h1>
	<p class="lead">
		Atur notifikasi yang masuk ke tab notifikasi Anda. Tersimpan di akun dan berlaku di semua
		perangkat.
	</p>

	{#if !data.available}<p class="warn" aria-live="polite">
			Preferensi tersimpan mungkin belum termuat. Menyimpan akan tetap memperbaruinya.
		</p>{/if}

	<form
		onsubmit={(event) => {
			event.preventDefault();
			void save();
		}}
	>
		<fieldset>
			<legend>Pengingat postingan baru dari…</legend>
			<p class="field-hint">
				Notifikasi seperti “… membagikan postingan baru”. Kurangi bila terasa terlalu ramai.
			</p>
			<div class="segmented">
				{#each newPostOptions as option (option.value)}
					<label class="segment" class:selected={newPostReminders === option.value}>
						<input
							type="radio"
							name="new_post"
							value={option.value}
							bind:group={newPostReminders}
						/>
						<strong>{option.label}</strong><small>{option.hint}</small>
					</label>
				{/each}
			</div>
		</fieldset>

		<fieldset>
			<legend>Jenis notifikasi lain</legend>
			<label class="toggle"
				><input type="checkbox" bind:checked={likes} /><span
					><strong>Suka</strong><small>Saat seseorang menyukai postingan Anda.</small></span
				></label
			>
			<label class="toggle"
				><input type="checkbox" bind:checked={comments} /><span
					><strong>Komentar &amp; balasan</strong><small
						>Komentar pada postingan Anda dan balasan komentar.</small
					></span
				></label
			>
			<label class="toggle"
				><input type="checkbox" bind:checked={mentions} /><span
					><strong>Sebutan (mention)</strong><small
						>Saat Anda disebut di postingan, komentar, atau cerita.</small
					></span
				></label
			>
			<label class="toggle"
				><input type="checkbox" bind:checked={follows} /><span
					><strong>Pengikut baru</strong><small
						>Saat seseorang mulai mengikuti Anda. (Permintaan mengikuti selalu tampil.)</small
					></span
				></label
			>
		</fieldset>

		<button type="submit" disabled={saving}>{saving ? 'Menyimpan…' : 'Simpan preferensi'}</button>
		{#if status}<p class="status" class:error={!statusOk} aria-live="polite">{status}</p>{/if}
	</form>
</main>

<style>
	.preferences {
		width: min(100% - 32px, 620px);
		margin: 28px auto;
		padding: 24px;
	}
	.back {
		color: var(--color-primary-strong);
		font-size: 0.78rem;
		font-weight: 700;
	}
	h1 {
		margin: 18px 0 6px;
		font-size: 1.3rem;
	}
	.lead {
		margin: 0 0 6px;
		color: var(--color-muted);
		font-size: 0.82rem;
	}
	.warn {
		margin: 10px 0 0;
		padding: 10px 12px;
		background: var(--color-primary-soft);
		border-radius: 10px;
		color: var(--color-primary-strong);
		font-size: 0.76rem;
	}
	form {
		display: grid;
		gap: 20px;
		margin-top: 18px;
	}
	fieldset {
		margin: 0;
		padding: 0;
		border: 0;
	}
	legend {
		padding: 0;
		font-size: 0.92rem;
		font-weight: 750;
	}
	.field-hint {
		margin: 4px 0 12px;
		color: var(--color-muted);
		font-size: 0.76rem;
	}
	.segmented {
		display: grid;
		gap: 8px;
	}
	.segment {
		display: grid;
		gap: 2px;
		padding: 12px 14px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 12px;
		cursor: pointer;
	}
	.segment.selected {
		border-color: var(--color-primary);
		box-shadow: var(--focus-ring);
	}
	.segment input {
		position: absolute;
		opacity: 0;
		pointer-events: none;
	}
	.segment strong {
		font-size: 0.86rem;
	}
	.segment small,
	.toggle small {
		color: var(--color-muted);
		font-size: 0.74rem;
	}
	.toggle {
		display: flex;
		align-items: flex-start;
		gap: 12px;
		padding: 11px 4px;
		border-bottom: 1px solid var(--color-border);
	}
	.toggle:last-of-type {
		border-bottom: 0;
	}
	.toggle input {
		margin-top: 3px;
		width: 18px;
		height: 18px;
		accent-color: var(--color-primary);
	}
	.toggle span {
		display: grid;
		gap: 1px;
	}
	.toggle strong {
		font-size: 0.85rem;
	}
	button {
		min-height: 46px;
		padding: 0 18px;
		background: var(--color-primary);
		border: 0;
		border-radius: 12px;
		color: white;
		font-weight: 730;
	}
	button:disabled {
		opacity: 0.65;
	}
	.status {
		margin: 0;
		color: var(--color-secondary);
		font-size: 0.78rem;
	}
	.status.error {
		color: #b3392f;
	}
</style>
