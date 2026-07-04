<script lang="ts">
	import { enhance } from '$app/forms';
	import { ArrowLeft, Save } from '@lucide/svelte';
	import { untrack } from 'svelte';
	import ImageCropper from '$lib/components/media/ImageCropper.svelte';
	import { cropImageToRegion, type CropRegion } from '$lib/utils/image-crop';
	import type { PageProps } from './$types';
	let { data, form }: PageProps = $props();
	let profilePreview = $state(untrack(() => data.user?.avatarUrl ?? ''));
	let bannerPreview = $state(untrack(() => data.user?.bannerUrl ?? ''));
	let profileFile = $state<File | null>(null);
	let bannerFile = $state<File | null>(null);
	let profileRegion = $state<CropRegion | null>(null);
	let bannerRegion = $state<CropRegion | null>(null);
	function previewFile(event: Event, target: 'profile' | 'banner') {
		const file = (event.currentTarget as HTMLInputElement).files?.[0];
		if (!file) return;
		const url = URL.createObjectURL(file);
		if (target === 'profile') {
			profileFile = file;
			profilePreview = url;
			profileRegion = null;
		} else {
			bannerFile = file;
			bannerPreview = url;
			bannerRegion = null;
		}
	}
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
	<form
		method="POST"
		enctype="multipart/form-data"
		use:enhance={async ({ formData }) => {
			if (profileFile && profileRegion)
				formData.set('profile_picture', await cropImageToRegion(profileFile, profileRegion, 1024));
			if (bannerFile && bannerRegion)
				formData.set('banner', await cropImageToRegion(bannerFile, bannerRegion, 2000));
			return async ({ update }) => update({ reset: false });
		}}
	>
		<div class="profile-preview">
			<div
				class="banner"
				style:background-image={bannerPreview ? `url(${bannerPreview})` : undefined}
			></div>
			<div class="avatar">
				{#if profilePreview}<img src={profilePreview} alt="Pratinjau foto profil" />{:else}<span
						>{data.user?.fullName?.slice(0, 1) ?? '?'}</span
					>{/if}
			</div>
			<p><strong>{data.user?.fullName}</strong><small>@{data.user?.username}</small></p>
		</div>
		<label
			><span>Username</span><input
				name="username"
				required
				minlength="3"
				maxlength="50"
				value={data.user?.username}
			/></label
		>
		{#if profileFile}<ImageCropper
				src={profilePreview}
				aspect={1}
				label="Crop foto profil"
				round
				onregion={(region) => (profileRegion = region)}
			/>{/if}
		<label
			><span>Nama lengkap</span><input
				name="full_name"
				required
				maxlength="255"
				value={data.user?.fullName}
			/></label
		>
		{#if bannerFile}<ImageCropper
				src={bannerPreview}
				aspect={5}
				label="Crop banner profil"
				onregion={(region) => (bannerRegion = region)}
			/>{/if}
		<label
			><span>Bio</span><textarea name="bio" maxlength="1000" rows="5">{data.user?.bio}</textarea
			></label
		>
		<label
			><span>Foto profil <small>maks. 10 MB</small></span><input
				name="profile_picture"
				type="file"
				accept="image/*"
				onchange={(event) => previewFile(event, 'profile')}
			/></label
		>
		<label
			><span>Banner <small>maks. 20 MB</small></span><input
				name="banner"
				type="file"
				accept="image/*"
				onchange={(event) => previewFile(event, 'banner')}
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
	.profile-preview {
		position: relative;
		min-height: 180px;
		overflow: hidden;
		background: var(--color-surface-soft);
		border: 1px solid var(--color-border);
		border-radius: 16px;
	}
	.profile-preview .banner {
		aspect-ratio: 5 / 1;
		background: linear-gradient(135deg, #f7cf91, #b7d9c9);
		background-position: center;
		background-size: cover;
	}
	.profile-preview .avatar {
		position: absolute;
		top: 72px;
		left: 18px;
		display: grid;
		width: 76px;
		height: 76px;
		overflow: hidden;
		place-items: center;
		background: var(--color-primary);
		border: 4px solid white;
		border-radius: 50%;
		color: white;
		font-size: 1.35rem;
		font-weight: 800;
	}
	.profile-preview .avatar img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.profile-preview p {
		display: grid;
		margin: 11px 16px 12px 108px;
	}
	.profile-preview p small {
		color: var(--color-muted);
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
