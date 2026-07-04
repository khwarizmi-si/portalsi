<script lang="ts">
	import type { PageProps } from './$types';
	let { form }: PageProps = $props();
</script>

<svelte:head><title>Tambah portfolio — Portal SI</title></svelte:head>
<main class="form surface">
	<a href="/portfolio">← Portfolio</a>
	<h1>Tambah karya</h1>
	<form method="POST" enctype="multipart/form-data">
		<label
			><span>Aspek</span><select name="aspect" required
				><option value="quran">Al-Qur’an</option><option value="it">Teknologi</option><option
					value="bahasa">Bahasa</option
				><option value="karakter">Karakter</option></select
			></label
		><label><span>Judul</span><input name="title" required maxlength="255" /></label><label
			><span>Deskripsi</span><textarea name="description" rows="5"></textarea></label
		><label
			><span>Tahun</span><input
				name="year"
				type="number"
				min="2000"
				max={new Date().getFullYear()}
			/></label
		><label
			><span>Media gambar atau PDF</span><input
				name="media"
				type="file"
				accept="image/jpeg,image/png,application/pdf"
			/></label
		>{#if form?.message}<p>{form.message}</p>{/if}<button>Publikasikan karya</button>
	</form>
</main>

<style>
	.form {
		width: min(100% - 32px, 620px);
		margin: 28px auto;
		padding: 24px;
	}
	.form > a {
		color: var(--color-primary-strong);
		font-size: 0.78rem;
		font-weight: 700;
	}
	h1 {
		margin: 18px 0;
		font-size: 1.3rem;
	}
	form,
	label {
		display: grid;
	}
	form {
		gap: 14px;
	}
	label {
		gap: 6px;
	}
	label span {
		font-size: 0.77rem;
		font-weight: 700;
	}
	input,
	textarea,
	select {
		padding: 11px;
		background: var(--color-surface-soft);
		border: 1px solid var(--color-border);
		border-radius: 10px;
	}
	button {
		min-height: 44px;
		background: var(--color-primary);
		border: 0;
		border-radius: 11px;
		color: white;
		font-weight: 720;
	}
	form > p {
		color: var(--color-danger);
		font-size: 0.74rem;
	}
</style>
