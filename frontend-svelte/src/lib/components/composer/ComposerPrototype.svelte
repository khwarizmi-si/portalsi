<script lang="ts">
	import { goto } from '$app/navigation';
	import {
		ImagePlus,
		LoaderCircle,
		MapPin,
		Music2,
		Pause,
		Play,
		Save,
		Scissors,
		Sparkles,
		Upload,
		Video,
		X
	} from '@lucide/svelte';
	import { onMount, untrack } from 'svelte';
	import { createdPostResponseSchema } from '$lib/schemas/post';
	import { createdStoryResponseSchema } from '$lib/schemas/story';
	import ImageCropper from '$lib/components/media/ImageCropper.svelte';
	import { cropImageToRegion, type CropRegion } from '$lib/utils/image-crop';
	import { confirmAction } from '$lib/ui/confirm';
	import { finishProgress, startProgress } from '$lib/ui/progress';
	import MentionTextarea from '$lib/components/ui/MentionTextarea.svelte';

	type Kind = 'post' | 'story' | 'clips';
	let { kind }: { kind: Kind } = $props();
	const copy = $derived(
		{
			post: {
				eyebrow: 'Bagikan momen',
				title: 'Buat postingan',
				description: 'Foto atau video tunggal dengan caption dan lokasi.'
			},
			story: {
				eyebrow: 'Cerita 24 jam',
				title: 'Buat cerita',
				description: 'Bagikan foto, video, atau audio yang ringan dan spontan.'
			},
			clips: {
				eyebrow: 'Video vertikal',
				title: 'Upload Clips',
				description: 'Pilih satu video vertikal untuk dibagikan sebagai postingan.'
			}
		}[kind]
	);
	let file = $state<File | null>(null);
	let caption = $state('');
	let location = $state('');
	let previewUrl = $state('');
	let submitting = $state(false);
	let dragging = $state(false);
	let message = $state('');
	let uploadProgress = $state(0);
	let activeUpload = $state<XMLHttpRequest | null>(null);
	let cropMode = $state<'original' | 'square' | 'portrait' | 'story'>(
		untrack(() => (kind === 'story' ? 'story' : 'original'))
	);
	let sourceAspect = $state(1);
	let cropRegion = $state<CropRegion | null>(null);
	let filter = $state<'normal' | 'bright' | 'warm' | 'mono' | 'contrast'>('normal');
	let locationResults = $state<Array<{ id: number; label: string }>>([]);
	let locationSearching = $state(false);
	// true setelah user memilih satu lokasi: hentikan pencarian & sembunyikan saran
	// sampai user mengetik lagi (atau menekan X).
	let locationChosen = $state(false);
	let musicSearching = $state(false);
	let musicQuery = $state('');
	let musicResults = $state<
		Array<{
			id: string | number;
			title: string;
			artist: string;
			durationSeconds: number;
			previewUrl: string | null;
			artworkUrl: string | null;
		}>
	>([]);
	let selectedMusic = $state<(typeof musicResults)[number] | null>(null);
	let musicStartSeconds = $state(0);
	let musicEndSeconds = $state(15);
	let musicTotalSeconds = $state(30);
	let musicPreviewSeconds = $state(30);
	let musicPreviewPlaying = $state(false);
	let musicAudio = $state<HTMLAudioElement>();
	const musicDurationSeconds = $derived(Math.max(0, musicEndSeconds - musicStartSeconds));
	const filterOptions = [
		{ id: 'normal' as const, label: 'Normal', css: 'none' },
		{ id: 'bright' as const, label: 'Cerah', css: 'brightness(1.12) saturate(1.08)' },
		{ id: 'warm' as const, label: 'Hangat', css: 'sepia(.18) saturate(1.18) hue-rotate(-8deg)' },
		{ id: 'mono' as const, label: 'Mono', css: 'grayscale(1) contrast(1.08)' },
		{ id: 'contrast' as const, label: 'Kontras', css: 'contrast(1.18) saturate(1.12)' }
	];
	const activeFilter = $derived(filterOptions.find((item) => item.id === filter)?.css ?? 'none');
	const cropAspect = $derived(
		cropMode === 'square'
			? 1
			: cropMode === 'portrait'
				? 4 / 5
				: cropMode === 'story'
					? 9 / 16
					: sourceAspect
	);

	const acceptedTypes = $derived(
		kind === 'clips' ? 'video/*' : kind === 'story' ? 'image/*,video/*,audio/*' : 'image/*,video/*'
	);
	type MediaKind = 'image' | 'video' | 'audio' | 'unknown';
	const selectedFileKind = $derived(file ? mediaKind(file) : null);

	function mediaKind(candidate: File): MediaKind {
		if (candidate.type.startsWith('image/')) return 'image';
		if (candidate.type.startsWith('video/')) return 'video';
		if (candidate.type.startsWith('audio/')) return 'audio';
		const extension = candidate.name.split('.').pop()?.toLowerCase() ?? '';
		if (['jpg', 'jpeg', 'png', 'webp', 'gif'].includes(extension)) return 'image';
		if (['mp4', 'mov', 'webm', 'avi', '3gp', 'mkv', 'm4v'].includes(extension)) return 'video';
		if (['mp3', 'wav', 'm4a', 'aac', 'ogg'].includes(extension)) return 'audio';
		return 'unknown';
	}

	$effect(() => {
		if (!file) {
			previewUrl = '';
			return;
		}
		const url = URL.createObjectURL(file);
		previewUrl = url;
		return () => URL.revokeObjectURL(url);
	});

	$effect(() => {
		const query = location.trim();
		if (kind === 'story' || locationChosen || query.length < 3) {
			locationResults = [];
			locationSearching = false;
			return;
		}
		locationSearching = true;
		const controller = new AbortController();
		const timer = window.setTimeout(async () => {
			try {
				const response = await fetch(`/api/external/locations?q=${encodeURIComponent(query)}`, {
					signal: controller.signal
				});
				if (!response.ok) throw new Error();
				const payload = (await response.json()) as {
					locations?: Array<{ id: number; label: string }>;
				};
				locationResults = payload.locations ?? [];
			} catch (error) {
				if (!(error instanceof DOMException && error.name === 'AbortError')) locationResults = [];
			} finally {
				if (!controller.signal.aborted) locationSearching = false;
			}
		}, 280);
		return () => {
			window.clearTimeout(timer);
			controller.abort();
		};
	});

	$effect(() => {
		const query = musicQuery.trim();
		if (query.length < 2 || selectedMusic?.title === query) {
			musicResults = [];
			musicSearching = false;
			return;
		}
		musicSearching = true;
		const controller = new AbortController();
		const timer = window.setTimeout(async () => {
			try {
				const response = await fetch(`/api/external/music?q=${encodeURIComponent(query)}`, {
					signal: controller.signal
				});
				if (!response.ok) throw new Error();
				const payload = (await response.json()) as { tracks?: typeof musicResults };
				musicResults = payload.tracks ?? [];
			} catch (error) {
				if (!(error instanceof DOMException && error.name === 'AbortError')) musicResults = [];
			} finally {
				if (!controller.signal.aborted) musicSearching = false;
			}
		}, 280);
		return () => {
			window.clearTimeout(timer);
			controller.abort();
		};
	});

	onMount(() => {
		void readDraft()
			.then(async (draft) => {
				if (!draft) return;
				const restore = await confirmAction({
					title: 'Lanjutkan draft terakhir?',
					description:
						'Kami menemukan konten yang belum sempat Anda bagikan. Foto atau video beserta detailnya masih tersimpan di perangkat ini.',
					confirmLabel: 'Lanjutkan mengedit',
					cancelLabel: 'Mulai dari awal'
				});
				if (!restore) {
					await deleteDraft();
					return;
				}
				caption = draft.caption ?? '';
				location = draft.location ?? '';
				locationChosen = Boolean(location.trim());
				file = draft.file instanceof File ? draft.file : null;
				selectedMusic = draft.music ?? null;
				musicQuery = selectedMusic?.title ?? '';
				cropMode = draft.cropMode ?? 'original';
				cropRegion = draft.cropRegion ?? null;
				filter = draft.filter ?? 'normal';
				musicStartSeconds = draft.musicStartSeconds ?? 0;
				musicEndSeconds = musicStartSeconds + (draft.musicDurationSeconds ?? 15);
				musicTotalSeconds = selectedMusic?.durationSeconds ?? Math.max(30, musicEndSeconds);
			})
			.catch(() => undefined);
	});

	function selectFile(candidate?: File) {
		if (!candidate) return;
		message = '';
		const detectedKind = mediaKind(candidate);
		const allowed =
			kind === 'clips'
				? detectedKind === 'video'
				: kind === 'story'
					? detectedKind !== 'unknown'
					: detectedKind === 'image' || detectedKind === 'video';
		if (!allowed) {
			message = 'Jenis file tidak didukung untuk konten ini.';
			return;
		}
		if (candidate.size > 500 * 1024 * 1024) {
			message = 'Ukuran file melebihi batas 500 MB.';
			return;
		}
		file = candidate;
		cropMode = kind === 'story' ? 'story' : 'original';
		sourceAspect = 1;
		cropRegion = null;
		filter = 'normal';
	}

	function onDrop(event: DragEvent) {
		event.preventDefault();
		dragging = false;
		selectFile(event.dataTransfer?.files[0]);
	}

	function setCropMode(mode: typeof cropMode) {
		cropMode = mode;
		cropRegion = null;
	}

	async function saveDraft() {
		try {
			// Bentuk objek biasa; writeDraft memisahkan File menjadi Blob + metadata
			// agar konsisten di browser yang tidak stabil menyimpan File secara langsung.
			const draft = {
				caption,
				location,
				file,
				music: selectedMusic,
				cropMode,
				cropRegion,
				filter,
				musicStartSeconds,
				musicDurationSeconds,
				savedAt: new Date().toISOString()
			} satisfies Draft;
			await writeDraft(draft);
			const verified = await readDraft();
			if (!verified || verified.savedAt !== draft.savedAt || verified.file?.size !== file?.size)
				throw new Error('Draft verification failed');
			message = 'Draft dan media disimpan di perangkat ini.';
		} catch {
			message = 'Draft belum dapat disimpan di perangkat ini.';
		}
	}

	async function publish() {
		if (!file || submitting) return;
		const confirmed = await confirmAction({
			title:
				kind === 'story'
					? 'Bagikan cerita sekarang?'
					: kind === 'clips'
						? 'Bagikan clips sekarang?'
						: 'Bagikan postingan sekarang?',
			description:
				'Periksa kembali media, caption, lokasi, dan musik. Konten akan langsung terlihat oleh audiens Anda.',
			confirmLabel: 'Ya, bagikan'
		});
		if (!confirmed) return;
		submitting = true;
		uploadProgress = 0;
		message = '';
		startProgress();
		try {
			const body = new FormData();
			const uploadFile =
				selectedFileKind === 'image' && cropRegion
					? await cropImageToRegion(file, cropRegion, 2048, activeFilter)
					: file;
			// Coba unggah media LANGSUNG ke R2 (tanpa melewati Laravel). Kalau gagal (mis. CORS
			// R2 belum diatur), otomatis fallback mengirim file ke server seperti biasa.
			const directKey = await tryDirectUpload(uploadFile, kind === 'story' ? 'story' : 'post');
			if (directKey) body.set('media_key', directKey);
			else body.set('media', uploadFile);
			body.set('caption', caption.trim());
			if (selectedMusic) {
				body.set('music_track_name', selectedMusic.title);
				body.set('music_artist_name', selectedMusic.artist);
				if (selectedMusic.previewUrl) body.set('music_preview_url', selectedMusic.previewUrl);
				if (selectedMusic.artworkUrl) body.set('music_album_art_url', selectedMusic.artworkUrl);
				body.set('music_start_position_ms', String(musicStartSeconds * 1000));
				body.set('music_clip_duration_ms', String(musicDurationSeconds * 1000));
			}
			if (kind === 'story') {
				body.set(
					'type',
					selectedFileKind === 'video' ? 'video' : selectedFileKind === 'audio' ? 'music' : 'image'
				);
				await upload('stories', body, (payload) => createdStoryResponseSchema.parse(payload));
				await deleteDraft();
				await goto('/home');
			} else {
				if (selectedFileKind === 'video') {
					const thumbnail = await generateVideoThumbnail(file);
					if (thumbnail) body.set('thumbnail', thumbnail);
				}
				if (location.trim()) body.set('location', location.trim());
				body.set('is_video', String(selectedFileKind === 'video' ? 1 : 0));
				body.set('is_archived', '0');
				const response = await upload('posts', body, (payload) =>
					createdPostResponseSchema.parse(payload)
				);
				await deleteDraft();
				await goto(`/posts/${response.post.post_id}`);
			}
		} catch (error) {
			message = error instanceof Error ? error.message : 'Konten belum dapat dibagikan.';
			finishProgress(false);
		} finally {
			submitting = false;
			activeUpload = null;
			finishProgress(true);
		}
	}

	function upload<T>(path: string, body: FormData, parse: (payload: unknown) => T) {
		return new Promise<T>((resolve, reject) => {
			const xhr = new XMLHttpRequest();
			activeUpload = xhr;
			xhr.open('POST', `/api/${path}`);
			xhr.setRequestHeader('Accept', 'application/json');
			xhr.upload.onprogress = (event) => {
				if (event.lengthComputable) uploadProgress = Math.round((event.loaded / event.total) * 100);
			};
			xhr.onload = () => {
				let payload: unknown;
				try {
					payload = JSON.parse(xhr.responseText);
				} catch {
					reject(new Error('Server mengembalikan respons yang tidak valid.'));
					return;
				}
				if (xhr.status < 200 || xhr.status >= 300) {
					const detail = payload as { message?: string };
					reject(new Error(detail.message || 'Unggahan ditolak server.'));
					return;
				}
				try {
					resolve(parse(payload));
				} catch {
					reject(new Error('Respons unggahan tidak sesuai kontrak.'));
				}
			};
			xhr.onerror = () => reject(new Error('Koneksi unggahan terputus.'));
			xhr.onabort = () => reject(new Error('Unggahan dibatalkan.'));
			xhr.send(body);
		});
	}

	// Coba unggah media langsung ke R2 via presigned URL. Return key kalau sukses, null bila
	// gagal (agar pemanggil fallback ke unggah lewat server).
	async function tryDirectUpload(
		fileToUpload: File,
		presignKind: 'post' | 'story'
	): Promise<string | null> {
		try {
			const contentType = fileToUpload.type;
			if (!contentType || !/^(image|video)\//.test(contentType)) return null;
			const extension =
				(fileToUpload.name.split('.').pop() || '').toLowerCase() ||
				(contentType.startsWith('video/') ? 'mp4' : 'jpg');
			const res = await fetch('/api/uploads/presign', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
				body: JSON.stringify({ extension, content_type: contentType, kind: presignKind })
			});
			if (!res.ok) return null;
			const presign = (await res.json()) as {
				upload_url?: string;
				key?: string;
				content_type?: string;
			};
			if (!presign.upload_url || !presign.key) return null;
			await putToStorage(presign.upload_url, fileToUpload, presign.content_type || contentType);
			return presign.key;
		} catch {
			return null;
		}
	}

	function putToStorage(url: string, fileToUpload: File, contentType: string) {
		return new Promise<void>((resolve, reject) => {
			const xhr = new XMLHttpRequest();
			activeUpload = xhr;
			xhr.open('PUT', url);
			xhr.setRequestHeader('Content-Type', contentType);
			xhr.upload.onprogress = (event) => {
				if (event.lengthComputable) uploadProgress = Math.round((event.loaded / event.total) * 100);
			};
			xhr.onload = () => {
				if (xhr.status >= 200 && xhr.status < 300) resolve();
				else reject(new Error('Upload langsung gagal.'));
			};
			xhr.onerror = () => reject(new Error('Upload langsung terputus.'));
			xhr.onabort = () => reject(new Error('Unggahan dibatalkan.'));
			xhr.send(fileToUpload);
		});
	}

	function cancelUpload() {
		activeUpload?.abort();
	}

	function updateMusicStart(event: Event) {
		const value = Number((event.currentTarget as HTMLInputElement).value);
		musicStartSeconds = Math.min(value, musicEndSeconds - 5);
		playPreviewRange();
	}

	function updateMusicEnd(event: Event) {
		const value = Number((event.currentTarget as HTMLInputElement).value);
		musicEndSeconds = Math.max(value, musicStartSeconds + 5);
		playPreviewRange();
	}
	function formatMusicTime(totalSeconds: number) {
		const safe = Number.isFinite(totalSeconds) ? Math.max(0, Math.round(totalSeconds)) : 0;
		return `${Math.floor(safe / 60)}:${String(safe % 60).padStart(2, '0')}`;
	}

	function selectMusic(track: (typeof musicResults)[number]) {
		selectedMusic = track;
		musicQuery = track.title;
		musicResults = [];
		musicStartSeconds = 0;
		musicTotalSeconds = Math.max(5, track.durationSeconds || 30);
		musicEndSeconds = musicTotalSeconds;
		musicPreviewPlaying = false;
	}

	// Putar pratinjau tepat pada rentang terpilih [start, end], lalu loop.
	function playPreviewRange() {
		if (!musicAudio || musicAudio.readyState < HTMLMediaElement.HAVE_METADATA) return;
		musicAudio.currentTime = musicStartSeconds;
		musicPreviewPlaying = true;
		void musicAudio.play().catch(() => undefined);
	}

	function toggleMusicPreview() {
		if (!musicAudio) return;
		if (musicAudio.paused) {
			if (musicAudio.currentTime < musicStartSeconds || musicAudio.currentTime >= musicEndSeconds)
				musicAudio.currentTime = musicStartSeconds;
			void musicAudio.play();
		} else musicAudio.pause();
	}

	function startMusicPreview(event: Event) {
		const audio = event.currentTarget as HTMLAudioElement;
		if (audio.currentTime < musicStartSeconds || audio.currentTime >= musicEndSeconds)
			audio.currentTime = musicStartSeconds;
	}

	function limitMusicPreview(event: Event) {
		const audio = event.currentTarget as HTMLAudioElement;
		if (audio.currentTime >= musicEndSeconds || audio.currentTime < musicStartSeconds - 0.25) {
			audio.currentTime = musicStartSeconds;
			void audio.play().catch(() => undefined);
		}
	}

	async function generateVideoThumbnail(source: File): Promise<File | null> {
		const url = URL.createObjectURL(source);
		try {
			const video = document.createElement('video');
			video.preload = 'metadata';
			video.muted = true;
			video.playsInline = true;
			video.src = url;
			await new Promise<void>((resolve, reject) => {
				video.onloadeddata = () => resolve();
				video.onerror = () => reject(new Error('Frame video tidak dapat dibaca.'));
			});
			video.currentTime = Math.min(0.1, Math.max(0, video.duration / 20));
			await new Promise<void>((resolve) => {
				video.onseeked = () => resolve();
				setTimeout(resolve, 500);
			});
			const scale = Math.min(1, 1280 / Math.max(video.videoWidth, video.videoHeight));
			const canvas = document.createElement('canvas');
			canvas.width = Math.max(1, Math.round(video.videoWidth * scale));
			canvas.height = Math.max(1, Math.round(video.videoHeight * scale));
			canvas.getContext('2d')?.drawImage(video, 0, 0, canvas.width, canvas.height);
			const blob = await new Promise<Blob | null>((resolve) =>
				canvas.toBlob(resolve, 'image/jpeg', 0.84)
			);
			return blob
				? new File([blob], `${source.name.replace(/\.[^.]+$/, '')}-thumb.jpg`, {
						type: 'image/jpeg'
					})
				: null;
		} catch {
			return null;
		} finally {
			URL.revokeObjectURL(url);
		}
	}

	type Draft = {
		caption?: string;
		location?: string;
		file?: File | null;
		music?: (typeof musicResults)[number] | null;
		cropMode?: typeof cropMode;
		cropRegion?: CropRegion | null;
		filter?: typeof filter;
		musicStartSeconds?: number;
		musicDurationSeconds?: number;
		savedAt?: string;
	};
	type StoredDraft = Omit<Draft, 'file'> & {
		file?: { blob: Blob; name: string; type: string; lastModified: number } | null;
	};
	function draftDatabase() {
		return new Promise<IDBDatabase>((resolve, reject) => {
			const request = indexedDB.open('portal-si-composer', 2);
			request.onupgradeneeded = () => {
				if (!request.result.objectStoreNames.contains('drafts'))
					request.result.createObjectStore('drafts');
			};
			request.onsuccess = () => resolve(request.result);
			request.onerror = () => reject(request.error);
			request.onblocked = () => reject(new Error('Penyimpanan draft sedang dipakai tab lain.'));
		});
	}
	async function writeDraft(draft: Draft) {
		const db = await draftDatabase();
		const stored: StoredDraft = {
			...draft,
			file: draft.file
				? {
						blob: draft.file.slice(0, draft.file.size, draft.file.type),
						name: draft.file.name,
						type: draft.file.type,
						lastModified: draft.file.lastModified
					}
				: null
		};
		await new Promise<void>((resolve, reject) => {
			const tx = db.transaction('drafts', 'readwrite');
			tx.objectStore('drafts').put(stored, kind);
			tx.oncomplete = () => resolve();
			tx.onerror = () => reject(tx.error);
			tx.onabort = () => reject(tx.error ?? new Error('Transaksi draft dibatalkan.'));
		});
		db.close();
	}
	async function readDraft() {
		const db = await draftDatabase();
		const value = await new Promise<StoredDraft | Draft | undefined>((resolve, reject) => {
			const request = db.transaction('drafts').objectStore('drafts').get(kind);
			request.onsuccess = () => resolve(request.result as StoredDraft | Draft | undefined);
			request.onerror = () => reject(request.error);
		});
		db.close();
		if (!value) return undefined;
		const storedFile = value.file;
		if (storedFile instanceof File || storedFile == null) return value as Draft;
		return {
			...value,
			file: new File([storedFile.blob], storedFile.name, {
				type: storedFile.type,
				lastModified: storedFile.lastModified
			})
		};
	}
	async function deleteDraft() {
		const db = await draftDatabase();
		await new Promise<void>((resolve, reject) => {
			const tx = db.transaction('drafts', 'readwrite');
			tx.objectStore('drafts').delete(kind);
			tx.oncomplete = () => resolve();
			tx.onerror = () => reject(tx.error);
			tx.onabort = () => reject(tx.error ?? new Error('Transaksi draft dibatalkan.'));
		});
		db.close();
	}
</script>

<svelte:head
	><title>{copy.title} — Portal SI</title><meta name="robots" content="noindex" /></svelte:head
>

<div class="composer-page">
	<header>
		<a href="/home" aria-label="Tutup composer"><X size={21} /></a>
		<div>
			<p class="eyebrow">{copy.eyebrow}</p>
			<h1>{copy.title}</h1>
		</div>
		<button onclick={publish} disabled={!file || submitting}
			>{submitting
				? uploadProgress >= 100
					? 'Memproses di server…'
					: `Mengunggah ${uploadProgress}%`
				: 'Bagikan'}</button
		>
	</header>
	<div class="composer-grid">
		<section
			aria-label="Unggah media"
			class:dragging
			class="upload surface"
			ondragover={(event) => {
				event.preventDefault();
				dragging = true;
			}}
			ondragleave={() => (dragging = false)}
			ondrop={onDrop}
		>
			{#if previewUrl}
				{#if selectedFileKind === 'image'}
					<div class="crop-editor">
						{#key `${previewUrl}:${cropMode}`}
							<ImageCropper
								src={previewUrl}
								aspect={cropAspect}
								label="Atur potongan gambar"
								filterCss={activeFilter}
								onready={(aspect) => (sourceAspect = aspect)}
								onregion={(region) => (cropRegion = region)}
							/>
						{/key}
						<button class="crop-remove" onclick={() => (file = null)} aria-label="Hapus media"
							><X size={18} /></button
						>
					</div>
				{:else}<div class="preview">
						{#if selectedFileKind === 'video'}<video src={previewUrl} controls muted></video>
						{:else}<audio src={previewUrl} controls></audio>{/if}
						<button onclick={() => (file = null)} aria-label="Hapus media"><X size={18} /></button>
					</div>{/if}
				{#if selectedFileKind === 'image'}<div class="crop-controls" aria-label="Framing gambar">
						<span>Framing</span><button
							class:active={cropMode === 'original'}
							onclick={() => setCropMode('original')}>Asli</button
						><button class:active={cropMode === 'square'} onclick={() => setCropMode('square')}
							>1:1</button
						><button class:active={cropMode === 'portrait'} onclick={() => setCropMode('portrait')}
							>4:5</button
						>
						{#if kind === 'story'}<button
								class:active={cropMode === 'story'}
								onclick={() => setCropMode('story')}>9:16</button
							>{/if}
					</div>
					<div class="filter-controls" aria-label="Filter gambar">
						{#each filterOptions as item (item.id)}<button
								class:active={filter === item.id}
								onclick={() => (filter = item.id)}
								><span style:filter={item.css}><img src={previewUrl} alt="" /></span
								>{item.label}</button
							>{/each}
					</div>{/if}
			{:else}
				<div class="upload-art">
					{#if kind === 'clips'}<Video size={32} />{:else}<ImagePlus size={32} />{/if}<span
						><Sparkles size={14} /></span
					>
				</div>
				<h2>{kind === 'clips' ? 'Pilih video vertikal' : 'Tarik media ke sini'}</h2>
				<p>{copy.description}</p>
			{/if}
			<label
				><Upload size={17} />
				{file ? 'Ganti media' : 'Pilih dari perangkat'}<input
					type="file"
					accept={acceptedTypes}
					onchange={(event) => selectFile(event.currentTarget.files?.[0])}
				/></label
			>
			<small
				>{file
					? `${file.name} · ${(file.size / 1024 / 1024).toFixed(1)} MB`
					: 'Batas unggahan 500 MB'}</small
			>
		</section>
		<aside class="details surface">
			<h2>Detail {kind === 'story' ? 'cerita' : 'konten'}</h2>
			<label
				><span>Caption</span><MentionTextarea
					bind:value={caption}
					name="caption"
					maxlength={2200}
					rows={5}
					placeholder="Tulis sesuatu yang bermakna…"
				/><small>{caption.length.toLocaleString('id-ID')} karakter</small></label
			>
			{#if kind !== 'story'}<label class="field"
					><span><MapPin size={17} /> Lokasi</span><input
						bind:value={location}
						maxlength="255"
						placeholder="Contoh: Denpasar"
						oninput={() => (locationChosen = false)}
						onkeydown={(event) => {
							if (event.key === 'Enter') event.preventDefault();
						}}
					/>{#if locationSearching}<LoaderCircle
							class="field-spinner"
							size={16}
						/>{:else if location.trim()}<button
							type="button"
							class="field-clear"
							onclick={() => {
								location = '';
								locationChosen = false;
								locationResults = [];
							}}
							aria-label="Hapus lokasi">×</button
						>{/if}</label
				><small class="attribution"
					>Pencarian © <a
						href="https://www.openstreetmap.org/copyright"
						target="_blank"
						rel="noreferrer">OpenStreetMap contributors</a
					></small
				>{#if locationResults.length && !locationChosen}<div
						class="suggestions"
						aria-label="Saran lokasi"
					>
						{#each locationResults as place (place.id)}<button
								onclick={() => {
									location = place.label;
									locationResults = [];
									locationChosen = true;
								}}><MapPin size={13} /> {place.label}</button
							>{/each}
					</div>{/if}{/if}
			<label class="field"
				><span><Music2 size={17} /> Musik</span><input
					bind:value={musicQuery}
					maxlength="80"
					placeholder="Cari judul lagu atau artis"
					onkeydown={(event) => {
						if (event.key === 'Enter') event.preventDefault();
					}}
				/>{#if musicSearching}<LoaderCircle class="field-spinner" size={16} />{/if}</label
			>
			<small class="music-help"
				>Pilih lagu penuh dari Audius, lalu atur bagian yang ingin diputar.</small
			>
			{#if musicResults.length}<div class="suggestions music" aria-label="Hasil musik">
					{#each musicResults as track (track.id)}<button onclick={() => selectMusic(track)}
							>{#if track.artworkUrl}<img src={track.artworkUrl} alt="" />{:else}<Music2
									size={28}
								/>{/if}<span
								><strong>{track.title}</strong><small
									>{track.artist} · {formatMusicTime(track.durationSeconds)}</small
								></span
							></button
						>{/each}
				</div>{/if}
			{#if selectedMusic}<div class="selected-music">
					{#if selectedMusic.artworkUrl}<img src={selectedMusic.artworkUrl} alt="" />{:else}<Music2
							size={21}
						/>{/if}<span
						><strong>{selectedMusic.title}</strong><small
							>{selectedMusic.artist} · {formatMusicTime(selectedMusic.durationSeconds)}</small
						></span
					>{#if selectedMusic.previewUrl}<audio
							bind:this={musicAudio}
							src={selectedMusic.previewUrl}
							preload="metadata"
							onloadedmetadata={(event) => {
								musicPreviewSeconds = Math.max(1, Math.floor(event.currentTarget.duration || 30));
								// Stream Audius berisi track penuh; pakai metadata audio sebagai sumber kebenaran.
								musicTotalSeconds = musicPreviewSeconds;
								musicEndSeconds = Math.min(musicEndSeconds, musicPreviewSeconds);
								if (musicStartSeconds >= musicEndSeconds - 1) musicStartSeconds = 0;
							}}
							onplay={(event) => {
								startMusicPreview(event);
								musicPreviewPlaying = true;
							}}
							onpause={() => (musicPreviewPlaying = false)}
							ontimeupdate={limitMusicPreview}
						></audio><button
							class="music-play"
							onclick={toggleMusicPreview}
							aria-label={musicPreviewPlaying ? 'Jeda pratinjau' : 'Putar pratinjau'}
							>{#if musicPreviewPlaying}<Pause size={16} fill="currentColor" />{:else}<Play
									size={16}
									fill="currentColor"
								/>{/if}</button
						>{/if}<button
						onclick={() => {
							musicAudio?.pause();
							musicPreviewPlaying = false;
							selectedMusic = null;
							musicQuery = '';
						}}
						aria-label="Hapus musik"><X size={14} /></button
					>
				</div>
				<div class="music-trim">
					<header>
						<span><Scissors size={14} /> Potong musik</span><strong
							>{formatMusicTime(musicDurationSeconds)}</strong
						>
					</header>
					<div class="trim-times">
						<span>{formatMusicTime(musicStartSeconds)}</span><span
							>{formatMusicTime(musicEndSeconds)}</span
						>
					</div>
					<div
						class="dual-range"
						style={`--start:${(musicStartSeconds / musicTotalSeconds) * 100}%;--end:${(musicEndSeconds / musicTotalSeconds) * 100}%`}
					>
						<div></div>
						<input
							aria-label="Awal potongan musik"
							type="range"
							min="0"
							max={musicTotalSeconds}
							step="1"
							value={musicStartSeconds}
							oninput={updateMusicStart}
						/>
						<input
							aria-label="Akhir potongan musik"
							type="range"
							min="0"
							max={musicTotalSeconds}
							step="1"
							value={musicEndSeconds}
							oninput={updateMusicEnd}
						/>
					</div>
					<small
						>Menggeser batas langsung memutar dari awal pilihan dan mengulang di titik akhir.</small
					>
				</div>{/if}
			<button class="draft" onclick={saveDraft}
				><Save size={18} /><span>Simpan draft<small>Teks, media, lokasi, dan musik</small></span
				></button
			>
			{#if submitting}<div class="upload-progress">
					<div><span style:width={`${uploadProgress}%`}></span></div>
					<small
						>{uploadProgress >= 100
							? 'Berkas selesai dikirim, server sedang menyimpan media.'
							: `${uploadProgress}% terkirim ke server`}</small
					>
					<button onclick={cancelUpload}>Batalkan unggahan</button>
				</div>{/if}
			{#if message}<p class="message" aria-live="polite">{message}</p>{/if}
		</aside>
	</div>
</div>

<style>
	.composer-page {
		width: min(100% - 32px, 1040px);
		margin: 0 auto;
		padding: 20px 0 50px;
	}
	.composer-page > header {
		display: grid;
		grid-template-columns: 44px 1fr auto;
		align-items: center;
		gap: 12px;
		padding: 0 0 22px;
	}
	.composer-page > header > a {
		display: grid;
		width: 42px;
		height: 42px;
		place-items: center;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 12px;
	}
	.composer-page > header p {
		margin-bottom: 2px;
	}
	.composer-page > header h1 {
		margin: 0;
		font-size: 1.4rem;
		letter-spacing: -0.03em;
	}
	.composer-page > header > button {
		height: 42px;
		padding: 0 18px;
		background: var(--color-primary);
		border: 0;
		border-radius: 11px;
		color: white;
		font-weight: 720;
	}
	.composer-page > header > button:disabled {
		opacity: 0.45;
	}
	.composer-grid {
		display: grid;
		grid-template-columns: minmax(0, 1.35fr) minmax(300px, 0.65fr);
		gap: 18px;
	}
	.upload {
		display: grid;
		min-height: 610px;
		align-content: center;
		justify-items: center;
		padding: 30px;
		background: linear-gradient(145deg, #fff, #fff8ea);
		text-align: center;
		transition:
			border-color 0.2s,
			background 0.2s;
	}
	.upload.dragging {
		background: var(--color-primary-soft);
		border-color: var(--color-primary);
	}
	.upload-art {
		position: relative;
		display: grid;
		width: 78px;
		height: 78px;
		place-items: center;
		background: var(--color-primary-soft);
		border-radius: 24px;
		color: var(--color-primary-strong);
	}
	.upload-art span {
		position: absolute;
		right: -6px;
		top: -6px;
		display: grid;
		width: 29px;
		height: 29px;
		place-items: center;
		background: var(--color-secondary);
		border: 3px solid white;
		border-radius: 50%;
		color: white;
	}
	.upload h2 {
		margin: 20px 0 5px;
		font-size: 1.15rem;
	}
	.upload p {
		max-width: 26rem;
		margin: 0;
		color: var(--color-muted);
		font-size: 0.83rem;
	}
	.upload > label {
		display: flex;
		height: 45px;
		align-items: center;
		gap: 8px;
		margin-top: 20px;
		padding: 0 16px;
		background: var(--color-primary);
		border-radius: 12px;
		color: white;
		font-size: 0.8rem;
		font-weight: 720;
		cursor: pointer;
	}
	.upload input[type='file'] {
		position: absolute;
		width: 1px;
		height: 1px;
		overflow: hidden;
		opacity: 0;
	}
	.upload > small {
		margin-top: 10px;
		color: var(--color-subtle);
		font-size: 0.68rem;
	}
	.preview {
		position: relative;
		display: grid;
		width: min(100%, 540px);
		max-height: 470px;
		place-items: center;
		overflow: hidden;
		border-radius: 16px;
		background: #1d1915;
	}
	.preview video {
		width: 100%;
		max-height: 470px;
		object-fit: contain;
	}
	.preview audio {
		margin: 80px 30px;
	}
	.preview button {
		position: absolute;
		top: 10px;
		right: 10px;
		display: grid;
		width: 38px;
		height: 38px;
		place-items: center;
		background: rgb(0 0 0 / 55%);
		border: 0;
		border-radius: 50%;
		color: white;
	}
	.crop-editor {
		position: relative;
		width: min(100%, 540px);
	}
	.crop-remove {
		position: absolute;
		z-index: 4;
		top: 10px;
		right: 10px;
		display: grid;
		width: 38px;
		height: 38px;
		place-items: center;
		padding: 0;
		background: rgb(0 0 0 / 62%);
		border: 1px solid rgb(255 255 255 / 20%);
		border-radius: 50%;
		color: white;
		backdrop-filter: blur(8px);
	}
	.crop-controls {
		display: flex;
		align-items: center;
		gap: 5px;
		margin-top: 12px;
	}
	.crop-controls span {
		margin-right: 4px;
		color: var(--color-muted);
		font-size: 0.68rem;
	}
	.crop-controls button {
		min-height: 32px;
		padding: 0 10px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 8px;
		color: var(--color-muted);
		font-size: 0.68rem;
	}
	.crop-controls button.active {
		background: var(--color-text);
		color: white;
	}
	.filter-controls {
		display: flex;
		width: min(100%, 540px);
		gap: 8px;
		margin-top: 10px;
		overflow-x: auto;
		padding-bottom: 4px;
	}
	.filter-controls button {
		display: grid;
		min-width: 58px;
		justify-items: center;
		gap: 4px;
		padding: 0;
		background: transparent;
		border: 0;
		color: var(--color-muted);
		font-size: 0.62rem;
	}
	.filter-controls button span {
		display: block;
		width: 48px;
		height: 48px;
		overflow: hidden;
		border: 2px solid transparent;
		border-radius: 10px;
	}
	.filter-controls button.active span {
		border-color: var(--color-primary);
	}
	.filter-controls img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.details {
		align-self: start;
		padding: 19px;
	}
	.details > h2 {
		margin: 0 0 16px;
		font-size: 0.96rem;
	}
	.details label {
		position: relative;
		display: grid;
		gap: 7px;
	}
	:global(.field-spinner) {
		position: absolute;
		right: 12px;
		bottom: 15px;
		color: var(--color-primary);
		animation: spin 0.75s linear infinite;
	}
	.field-clear {
		position: absolute;
		right: 8px;
		bottom: 9px;
		display: grid;
		width: 26px;
		height: 26px;
		place-items: center;
		padding: 0;
		background: var(--color-surface-soft);
		border: 0;
		border-radius: 50%;
		color: var(--color-muted);
		font-size: 1.1rem;
		line-height: 1;
		cursor: pointer;
	}
	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}
	.details label > span {
		display: flex;
		align-items: center;
		gap: 5px;
		font-size: 0.78rem;
		font-weight: 680;
	}
	.details input {
		padding: 12px;
		background: var(--color-surface-soft);
		border: 1px solid var(--color-border);
		border-radius: 12px;
		outline: 0;
	}
	.details :global(.mention-field textarea) {
		padding: 12px;
		background: var(--color-surface-soft);
		border: 1px solid var(--color-border);
		border-radius: 12px;
		outline: 0;
		resize: vertical;
	}
	.details input:focus {
		border-color: var(--color-primary);
		box-shadow: var(--focus-ring);
	}
	.details label small {
		color: var(--color-subtle);
		font-size: 0.66rem;
		text-align: right;
	}
	.field {
		margin-top: 14px;
	}
	.attribution {
		display: block;
		margin-top: 4px;
		color: var(--color-subtle);
		font-size: 0.6rem;
	}
	.attribution a {
		text-decoration: underline;
	}
	.music-help {
		display: block;
		margin-top: 4px;
		color: var(--color-subtle);
		font-size: 0.62rem;
	}
	.suggestions {
		display: grid;
		max-height: 220px;
		overflow-y: auto;
		margin-top: 5px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 11px;
		box-shadow: var(--shadow-sm);
	}
	.suggestions button {
		display: flex;
		align-items: flex-start;
		gap: 7px;
		padding: 9px 10px;
		background: transparent;
		border: 0;
		border-bottom: 1px solid var(--color-border);
		color: var(--color-muted);
		font-size: 0.68rem;
		text-align: left;
	}
	.suggestions.music button {
		align-items: center;
	}
	.suggestions.music img {
		width: 36px;
		height: 36px;
		border-radius: 6px;
	}
	.suggestions.music span,
	.selected-music span {
		display: grid;
		min-width: 0;
		flex: 1;
	}
	.suggestions.music strong,
	.selected-music strong {
		overflow: hidden;
		font-size: 0.72rem;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.suggestions.music small,
	.selected-music small {
		color: var(--color-muted);
		font-size: 0.64rem;
	}
	.selected-music {
		display: flex;
		align-items: center;
		gap: 8px;
		margin-top: 8px;
		padding: 10px;
		background: var(--color-secondary-soft);
		border-radius: 10px;
		color: var(--color-secondary);
	}
	.selected-music > img {
		width: 42px;
		height: 42px;
		border-radius: 9px;
		object-fit: cover;
	}
	.selected-music > button {
		display: grid;
		place-items: center;
		padding: 3px;
		background: transparent;
		border: 0;
	}
	.selected-music > button.music-play {
		width: 36px;
		height: 36px;
		margin-left: auto;
		background: white;
		border-radius: 50%;
		color: var(--color-primary-strong);
	}
	.music-trim {
		display: grid;
		gap: 10px;
		margin-top: 8px;
		padding: 14px;
		background: linear-gradient(145deg, #fff9ed, #f5fbf8);
		border: 1px solid var(--color-border);
		border-radius: 14px;
	}
	.music-trim header,
	.music-trim header span,
	.trim-times {
		display: flex;
		align-items: center;
	}
	.music-trim header {
		justify-content: space-between;
	}
	.music-trim header span {
		gap: 6px;
		font-size: 0.7rem;
		font-weight: 720;
	}
	.music-trim header strong {
		padding: 4px 8px;
		background: var(--color-primary-soft);
		border-radius: 99px;
		color: var(--color-primary-strong);
		font-size: 0.62rem;
	}
	.trim-times {
		justify-content: space-between;
		color: var(--color-muted);
		font-size: 0.6rem;
		font-variant-numeric: tabular-nums;
	}
	.dual-range {
		position: relative;
		height: 30px;
	}
	.dual-range > div {
		position: absolute;
		top: 13px;
		right: 0;
		left: 0;
		height: 5px;
		background: linear-gradient(
			to right,
			#ddd4c5 0 var(--start),
			var(--color-primary) var(--start) var(--end),
			#ddd4c5 var(--end)
		);
		border-radius: 99px;
	}
	.dual-range input {
		position: absolute;
		inset: 0;
		width: 100%;
		height: 30px;
		padding: 0;
		background: transparent;
		pointer-events: none;
		appearance: none;
	}
	.dual-range input::-webkit-slider-runnable-track {
		height: 5px;
		background: transparent;
	}
	.dual-range input::-webkit-slider-thumb {
		width: 20px;
		height: 20px;
		margin-top: -8px;
		background: white;
		border: 3px solid var(--color-primary);
		border-radius: 50%;
		box-shadow: 0 2px 7px rgb(82 46 15 / 20%);
		pointer-events: auto;
		appearance: none;
	}
	.dual-range input::-moz-range-track {
		height: 5px;
		background: transparent;
	}
	.dual-range input::-moz-range-thumb {
		width: 16px;
		height: 16px;
		background: white;
		border: 3px solid var(--color-primary);
		border-radius: 50%;
		pointer-events: auto;
	}
	.music-trim > small {
		color: var(--color-muted);
		font-size: 0.6rem;
		line-height: 1.4;
	}
	.draft {
		display: grid;
		width: 100%;
		grid-template-columns: auto 1fr;
		align-items: center;
		gap: 11px;
		margin-top: 14px;
		padding: 12px 0;
		background: transparent;
		border: 0;
		border-block: 1px solid var(--color-border);
		text-align: left;
	}
	.draft > span {
		display: grid;
		font-size: 0.78rem;
		font-weight: 670;
	}
	.draft small {
		color: var(--color-muted);
		font-size: 0.67rem;
		font-weight: 500;
	}
	.message {
		margin: 16px 0 0;
		padding: 11px;
		background: var(--color-secondary-soft);
		border-radius: 10px;
		color: #33635e;
		font-size: 0.72rem;
	}
	.upload-progress {
		display: grid;
		gap: 6px;
		margin-top: 12px;
	}
	.upload-progress > div {
		height: 7px;
		overflow: hidden;
		background: var(--color-border);
		border-radius: 99px;
	}
	.upload-progress span {
		display: block;
		height: 100%;
		background: var(--color-primary);
		transition: width 0.2s;
	}
	.upload-progress button {
		justify-self: end;
		padding: 0;
		background: transparent;
		border: 0;
		color: var(--color-danger);
		font-size: 0.68rem;
		font-weight: 700;
	}
	.upload-progress small {
		color: var(--color-muted);
		font-size: 0.66rem;
	}
	@media (max-width: 820px) {
		.composer-grid {
			grid-template-columns: 1fr;
		}
		.upload {
			min-height: 430px;
		}
		.details {
			width: 100%;
		}
	}
	@media (max-width: 767px) {
		.composer-page {
			width: 100%;
			padding-top: 0;
		}
		.composer-page > header {
			position: sticky;
			z-index: 10;
			top: 0;
			padding: 10px 12px;
			background: rgb(255 253 248 / 94%);
			border-bottom: 1px solid var(--color-border);
			backdrop-filter: blur(16px);
		}
		.composer-page > header p {
			display: none;
		}
		.composer-page > header h1 {
			font-size: 1rem;
		}
		.composer-grid {
			gap: 10px;
		}
		.upload,
		.details {
			border-inline: 0;
			border-radius: 0;
		}
		.upload {
			min-height: 390px;
		}
	}
</style>
