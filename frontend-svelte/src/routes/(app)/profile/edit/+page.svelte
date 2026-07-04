<script lang="ts">
	import { ArrowLeft, Save } from '@lucide/svelte';
	import type { PageProps } from './$types';
	let { data, form }: PageProps = $props();
</script>

<svelte:head
	><title>Edit profil — Portal SI</title><meta name="robots" content="noindex" /></svelte:head
>
<main class="form-page surface">
	<header>
		<a href="/profile" aria-label="Kembali"><ArrowLeft size={19} /></a>
		<div>
			<p class="eyebrow">Profil Anda</p>
			<h1>Edit profil</h1>
		</div>
	</header>
	<form method="POST" enctype="multipart/form-data">
		<label
			><span>Username</span><input
				name="username"
				required
				minlength="3"
				maxlength="50"
				value={data.user?.username}
			/></label
		>
		<label
			><span>Nama lengkap</span><input
				name="full_name"
				required
				maxlength="255"
				value={data.user?.fullName}
			/></label
		>
		<label
			><span>Bio</span><textarea name="bio" maxlength="1000" rows="5">{data.user?.bio}</textarea
			></label
		>
		<label
			><span>Foto profil <small>maks. 10 MB</small></span><input
				name="profile_picture"
				type="file"
				accept="image/*"
			/></label
		>
		<label
			><span>Banner <small>maks. 20 MB</small></span><input
				name="banner"
				type="file"
				accept="image/*"
			/></label
		>
		{#if form?.message}<p class="message" role="alert">{form.message}</p>{/if}
		<button><Save size={17} /> Simpan perubahan</button>
	</form>
</main>

<style>
	.form-page {
		width: min(100% - 32px, 640px);
		margin: 28px auto;
		overflow: hidden;
	}
	header {
		display: flex;
		align-items: center;
		gap: 12px;
		padding: 16px 18px;
		border-bottom: 1px solid var(--color-border);
	}
	header a {
		display: grid;
		width: 40px;
		height: 40px;
		place-items: center;
		border-radius: 50%;
	}
	header p {
		margin: 0;
	}
	h1 {
		margin: 0;
		font-size: 1.15rem;
	}
	form {
		display: grid;
		gap: 16px;
		padding: 22px;
	}
	label {
		display: grid;
		gap: 7px;
	}
	label span {
		font-size: 0.78rem;
		font-weight: 700;
	}
	label small {
		color: var(--color-muted);
		font-weight: 500;
	}
	input,
	textarea {
		width: 100%;
		padding: 11px 12px;
		background: var(--color-surface-soft);
		border: 1px solid var(--color-border);
		border-radius: 11px;
	}
	textarea {
		resize: vertical;
	}
	form > button {
		display: flex;
		min-height: 44px;
		align-items: center;
		justify-content: center;
		gap: 7px;
		background: var(--color-primary);
		border: 0;
		border-radius: 11px;
		color: white;
		font-weight: 720;
	}
	.message {
		margin: 0;
		color: var(--color-danger);
		font-size: 0.76rem;
	}
	@media (max-width: 767px) {
		.form-page {
			width: 100%;
			margin: 0;
			border: 0;
			border-radius: 0;
		}
	}
</style>
