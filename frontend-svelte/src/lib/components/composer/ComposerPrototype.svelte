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
		TriangleAlert,
		Upload,
		Video,
		Volume2,
		VolumeX,
		X
	} from '@lucide/svelte';
	import { onDestroy, onMount, untrack } from 'svelte';
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
				description: 'Satu video, atau hingga 15 foto dalam satu galeri, dengan caption dan lokasi.'
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
	const MAX_IMAGES = 15;
	let file = $state<File | null>(null);
	// Galeri multi-foto (khusus post). Aktif saat berisi >1 foto. Tiap foto punya
	// pengaturan crop & filter sendiri, dan bisa diurutkan ulang lewat drag.
	type GalleryCrop = 'original' | 'square' | 'portrait';
	type GalleryItem = {
		id: string;
		file: File;
		url: string;
		crop: GalleryCrop;
		region: CropRegion | null;
		filter: 'normal' | 'bright' | 'warm' | 'mono' | 'contrast';
		aspect: number;
	};
	let galleryItems = $state<GalleryItem[]>([]);
	let editingId = $state<string | null>(null);
	// Reorder halus: array TIDAK diubah selama menyeret — kita geser tiap kartu lewat
	// transform (diukur dari posisi awal), lalu susun ulang array sekali saat dilepas.
	let gridEl = $state<HTMLDivElement>();
	let dragId = $state<string | null>(null);
	let dragMoved = $state(false);
	let committing = $state(false);
	let dragIndex = -1;
	let overIndex = $state(-1);
	let pointerDX = $state(0);
	let pointerDY = $state(0);
	let dragStartX = 0;
	let dragStartY = 0;
	let slotRects: { left: number; top: number; cx: number; cy: number }[] = [];
	let caption = $state('');
	let location = $state('');
	let previewUrl = $state('');
	let submitting = $state(false);
	let dragging = $state(false);
	let message = $state('');
	// Peringatan blokir (mis. video >1) ditampilkan sebagai modal agar jelas terlihat.
	let warning = $state<string | null>(null);
	let videoMuted = $state(false);
	let videoDuration = $state(0);
	let thumbnailSecond = $state(1);
	let thumbnailPreviewUrl = $state('');
	let thumbnailGenerating = $state(false);
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
	// Bisukan video: manual, atau otomatis saat memakai musik (musik yang menang).
	const videoWillMute = $derived(
		selectedFileKind === 'video' && (videoMuted || Boolean(selectedMusic))
	);
	const galleryMode = $derived(kind === 'post' && galleryItems.length > 1);
	const editingItem = $derived(galleryItems.find((item) => item.id === editingId) ?? null);
	const editCropAspect = $derived(
		editingItem
			? editingItem.crop === 'square'
				? 1
				: editingItem.crop === 'portrait'
					? 4 / 5
					: editingItem.aspect
			: 1
	);
	const editFilterCss = $derived(
		filterOptions.find((option) => option.id === editingItem?.filter)?.css ?? 'none'
	);

	$effect(() => {
		if (selectedFileKind !== 'video') resetThumbnailSelection();
	});

	// Peta transform tiap kartu saat menyeret (kartu yang diseret mengikuti jari,
	// kartu lain bergeser mulus untuk memberi ruang).
	const itemTransforms = $derived.by(() => {
		const map = new Map<string, { dx: number; dy: number; scale: number }>();
		if (dragId === null || dragIndex < 0 || slotRects.length !== galleryItems.length) return map;
		map.set(dragId, { dx: pointerDX, dy: pointerDY, scale: dragMoved ? 1.06 : 1 });
		const to = overIndex < 0 ? dragIndex : overIndex;
		const order = galleryItems.map((item) => item.id);
		const [moved] = order.splice(dragIndex, 1);
		order.splice(to, 0, moved);
		galleryItems.forEach((item, i) => {
			if (item.id === dragId) return;
			const targetSlot = order.indexOf(item.id);
			const from = slotRects[i];
			const dest = slotRects[targetSlot];
			if (from && dest)
				map.set(item.id, { dx: dest.left - from.left, dy: dest.top - from.top, scale: 1 });
		});
		return map;
	});
	function transformFor(id: string): string | undefined {
		const t = itemTransforms.get(id);
		if (!t) return undefined;
		return `translate(${t.dx}px, ${t.dy}px)${t.scale !== 1 ? ` scale(${t.scale})` : ''}`;
	}

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
		const stale = thumbnailPreviewUrl;
		return () => {
			if (stale) URL.revokeObjectURL(stale);
		};
	});

	// Bebaskan object URL galeri saat komponen dilepas.
	onDestroy(() => galleryItems.forEach((item) => URL.revokeObjectURL(item.url)));

	function makeGalleryItem(source: File): GalleryItem {
		return {
			id:
				typeof crypto !== 'undefined' && crypto.randomUUID
					? crypto.randomUUID()
					: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
			file: source,
			url: URL.createObjectURL(source),
			crop: 'original',
			region: null,
			filter: 'normal',
			aspect: 1
		};
	}

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

	function clearGallery() {
		galleryItems.forEach((item) => URL.revokeObjectURL(item.url));
		galleryItems = [];
		editingId = null;
	}

	function resetThumbnailSelection() {
		videoDuration = 0;
		thumbnailSecond = 1;
		thumbnailPreviewUrl = '';
		thumbnailGenerating = false;
	}

	function selectSingle(candidate?: File) {
		if (!candidate) return;
		const detectedKind = mediaKind(candidate);
		const allowed =
			kind === 'clips'
				? detectedKind === 'video'
				: kind === 'story'
					? detectedKind !== 'unknown'
					: detectedKind === 'image' || detectedKind === 'video';
		if (!allowed) {
			warning = 'Jenis file tidak didukung untuk konten ini.';
			return;
		}
		if (candidate.size > 500 * 1024 * 1024) {
			warning = 'Ukuran file melebihi batas 500 MB.';
			return;
		}
		file = candidate;
		clearGallery();
		resetThumbnailSelection();
		cropMode = kind === 'story' ? 'story' : 'original';
		sourceAspect = 1;
		cropRegion = null;
		filter = 'normal';
	}

	function selectFiles(list?: FileList | File[] | null) {
		if (!list) return;
		const incoming = Array.from(list);
		if (incoming.length === 0) return;
		message = '';

		// Story / clips selalu media tunggal.
		if (kind !== 'post') {
			selectSingle(incoming[0]);
			return;
		}

		const kinds = incoming.map(mediaKind);
		const hasVideo = kinds.some((value) => value === 'video');
		const allImages = kinds.every((value) => value === 'image');

		// Video: hanya boleh satu, dan tidak boleh dicampur foto.
		if (hasVideo) {
			if (incoming.length > 1) {
				warning = 'Video hanya boleh satu. Untuk banyak media, pilih foto saja.';
				return;
			}
			selectSingle(incoming[0]);
			return;
		}
		if (!allImages) {
			warning = 'Jenis file tidak didukung untuk konten ini.';
			return;
		}

		// Foto: gabungkan dengan yang sudah ada (maks 15), pertahankan urutan & pengaturan.
		const existingItems = galleryMode
			? galleryItems
			: file && selectedFileKind === 'image'
				? [makeGalleryItem(file)]
				: [];
		const room = MAX_IMAGES - existingItems.length;
		if (incoming.length > room)
			warning = `Maksimal ${MAX_IMAGES} foto per postingan. Sisanya tidak ditambahkan.`;
		const chosen = incoming.slice(0, Math.max(0, room));
		if ([...chosen, ...existingItems.map((item) => item.file)].some((f) => f.size > 500 * 1024 * 1024)) {
			warning = 'Ukuran file melebihi batas 500 MB.';
			return;
		}
		const combined = [...existingItems, ...chosen.map(makeGalleryItem)];
		if (combined.length <= 1) {
			if (combined.length === 1) selectSingle(combined[0].file);
			combined.forEach((item) => URL.revokeObjectURL(item.url));
		} else {
			file = null;
			galleryItems = combined;
			editingId = null;
		}
	}

	function removeGalleryImage(id: string) {
		const item = galleryItems.find((entry) => entry.id === id);
		if (!item) return;
		URL.revokeObjectURL(item.url);
		const next = galleryItems.filter((entry) => entry.id !== id);
		galleryItems = next;
		if (editingId === id) editingId = null;
		if (next.length === 1) selectSingle(next[0].file);
		else if (next.length === 0) file = null;
	}

	// Drag untuk mengurutkan ulang foto (mendukung sentuh).
	function measureSlots() {
		if (!gridEl) return;
		slotRects = [...gridEl.querySelectorAll<HTMLElement>('[data-gid]')].map((node) => {
			const rect = node.getBoundingClientRect();
			return {
				left: rect.left,
				top: rect.top,
				cx: rect.left + rect.width / 2,
				cy: rect.top + rect.height / 2
			};
		});
	}
	function resetDrag() {
		dragId = null;
		dragMoved = false;
		dragIndex = -1;
		overIndex = -1;
		pointerDX = 0;
		pointerDY = 0;
	}
	function thumbPointerDown(event: PointerEvent, id: string) {
		if (event.pointerType === 'mouse' && event.button !== 0) return;
		measureSlots();
		dragId = id;
		dragIndex = galleryItems.findIndex((item) => item.id === id);
		overIndex = dragIndex;
		dragMoved = false;
		dragStartX = event.clientX;
		dragStartY = event.clientY;
		pointerDX = 0;
		pointerDY = 0;
		(event.currentTarget as HTMLElement).setPointerCapture?.(event.pointerId);
	}
	function thumbPointerMove(event: PointerEvent) {
		if (dragId === null) return;
		pointerDX = event.clientX - dragStartX;
		pointerDY = event.clientY - dragStartY;
		if (!dragMoved) {
			if (Math.hypot(pointerDX, pointerDY) < 6) return;
			dragMoved = true;
		}
		// Slot tujuan = kartu yang pusatnya paling dekat dengan jari.
		let best = dragIndex;
		let bestDist = Infinity;
		for (let i = 0; i < slotRects.length; i += 1) {
			const s = slotRects[i];
			const d = (s.cx - event.clientX) ** 2 + (s.cy - event.clientY) ** 2;
			if (d < bestDist) {
				bestDist = d;
				best = i;
			}
		}
		overIndex = best;
	}
	function thumbPointerUp(id: string) {
		const wasDrag = dragMoved;
		if (dragId !== null && wasDrag && overIndex >= 0 && overIndex !== dragIndex) {
			const order = galleryItems.map((item) => item.id);
			const [moved] = order.splice(dragIndex, 1);
			order.splice(overIndex, 0, moved);
			// Susun ulang array sekali; matikan transisi satu frame agar tidak ada lompatan.
			committing = true;
			galleryItems = order.map((oid) => galleryItems.find((item) => item.id === oid)!);
			resetDrag();
			requestAnimationFrame(() =>
				requestAnimationFrame(() => {
					committing = false;
				})
			);
		} else {
			const tap = !wasDrag;
			resetDrag();
			if (tap) editingId = id; // ketukan tanpa geser = buka editor foto
		}
	}

	function setEditCrop(mode: GalleryCrop) {
		if (!editingItem) return;
		editingItem.crop = mode;
		editingItem.region = null;
	}
	function setEditFilter(id: GalleryItem['filter']) {
		if (editingItem) editingItem.filter = id;
	}

	function onDrop(event: DragEvent) {
		event.preventDefault();
		dragging = false;
		selectFiles(event.dataTransfer?.files);
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

	function appendMusic(body: FormData) {
		if (!selectedMusic) return;
		body.set('music_track_name', selectedMusic.title);
		body.set('music_artist_name', selectedMusic.artist);
		if (selectedMusic.previewUrl) body.set('music_preview_url', selectedMusic.previewUrl);
		if (selectedMusic.artworkUrl) body.set('music_album_art_url', selectedMusic.artworkUrl);
		body.set('music_start_position_ms', String(musicStartSeconds * 1000));
		body.set('music_clip_duration_ms', String(musicDurationSeconds * 1000));
	}

	async function publish() {
		if ((!file && galleryItems.length === 0) || submitting) return;
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
			// Jalur galeri multi-foto (post): terapkan crop/filter tiap foto, lalu unggah.
			if (kind === 'post' && galleryMode) {
				const body = new FormData();
				for (const item of galleryItems) {
					const css = filterOptions.find((option) => option.id === item.filter)?.css ?? 'none';
					let uploadFile = item.file;
					if (item.region) {
						uploadFile = await cropImageToRegion(item.file, item.region, 2048, css);
					} else if (item.filter !== 'normal') {
						// Filter tanpa crop: render ulang seluruh gambar dengan filter.
						uploadFile = await cropImageToRegion(
							item.file,
							{ sx: 0, sy: 0, sw: 1e9, sh: 1e9 },
							2048,
							css
						);
					}
					const key = await tryDirectUpload(uploadFile, 'post');
					if (key) body.append('media_keys[]', key);
					else body.append('media[]', uploadFile);
				}
				body.set('caption', caption.trim());
				appendMusic(body);
				if (location.trim()) body.set('location', location.trim());
				body.set('is_video', '0');
				body.set('is_archived', '0');
				const response = await upload('posts', body, (payload) =>
					createdPostResponseSchema.parse(payload)
				);
				await deleteDraft();
				await goto(`/posts/${response.post.post_id}`);
				return;
			}
			if (!file) return;
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
					const thumbnail = await generateVideoThumbnail(file, thumbnailSecond);
					if (thumbnail) body.set('thumbnail', thumbnail);
				}
				if (location.trim()) body.set('location', location.trim());
				body.set('is_video', String(selectedFileKind === 'video' ? 1 : 0));
				body.set('video_muted', videoWillMute ? '1' : '0');
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

	// Thumbnail video dibuat di sisi klien HANYA sebagai optimasi. Di HP/iOS event video
	// sering tidak terpicu sehingga bisa menggantung — maka seluruh proses dibatasi waktu,
	// dan jika gagal kita lewati saja (server tetap membuat thumbnail lewat queue).
	async function generateVideoThumbnail(source: File, atSeconds = 1): Promise<File | null> {
		const url = URL.createObjectURL(source);
		const video = document.createElement('video');
		try {
			video.preload = 'auto';
			video.muted = true;
			video.playsInline = true;
			video.crossOrigin = 'anonymous';
			video.setAttribute('playsinline', '');
			video.src = url;

			const metadataReady = await new Promise<boolean>((resolve) => {
				let settled = false;
				const finish = (ok: boolean) => {
					if (settled) return;
					settled = true;
					clearTimeout(timer);
					resolve(ok);
				};
				const timer = setTimeout(() => finish(false), 4000);
				video.onloadedmetadata = () => finish(true);
				video.onerror = () => finish(false);
			});
			if (!metadataReady) return null;

			const duration = Number.isFinite(video.duration) && video.duration > 0 ? video.duration : 1;
			const targetSecond = Math.min(Math.max(0.05, atSeconds), Math.max(0.05, duration - 0.05));
			try {
				video.currentTime = targetSecond;
				await new Promise<void>((resolve) => {
					let settled = false;
					const finish = () => {
						if (settled) return;
						settled = true;
						clearTimeout(timer);
						resolve();
					};
					const timer = setTimeout(finish, 1400);
					video.onseeked = finish;
					video.oncanplay = finish;
					video.onloadeddata = finish;
				});
			} catch {
				// abaikan; pakai frame apa pun yang tersedia
			}
			if (!video.videoWidth || !video.videoHeight) return null;

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
			video.removeAttribute('src');
			try {
				video.load();
			} catch {
				// abaikan
			}
			URL.revokeObjectURL(url);
		}
	}

	async function refreshThumbnailPreview() {
		if (!file || selectedFileKind !== 'video') return;
		thumbnailGenerating = true;
		try {
			const thumb = await generateVideoThumbnail(file, thumbnailSecond);
			if (!thumb) return;
			thumbnailPreviewUrl = URL.createObjectURL(thumb);
		} finally {
			thumbnailGenerating = false;
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
		<button onclick={publish} disabled={(!file && galleryItems.length === 0) || submitting}
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
			{#if galleryMode}
				<div class="gallery-edit">
					<div class="gallery-grid" class:committing bind:this={gridEl}>
						{#each galleryItems as item, index (item.id)}
							<div
								class="g-item"
								class:dragging={dragId === item.id && dragMoved}
								data-gid={item.id}
								role="button"
								tabindex="0"
								aria-label={`Foto ${index + 1}. Ketuk untuk mengedit, tahan lalu geser untuk mengurutkan.`}
								style:transform={transformFor(item.id)}
								onpointerdown={(event) => thumbPointerDown(event, item.id)}
								onpointermove={thumbPointerMove}
								onpointerup={() => thumbPointerUp(item.id)}
								onpointercancel={resetDrag}
								onkeydown={(event) => {
									if (event.key === 'Enter' || event.key === ' ') {
										event.preventDefault();
										editingId = item.id;
									}
								}}
							>
								<img src={item.url} alt={`Foto ${index + 1}`} draggable="false" />
								{#if item.filter !== 'normal' || item.crop !== 'original'}<span class="g-edited"
										><Sparkles size={11} /></span
									>{/if}
								<button
									class="g-remove"
									onpointerdown={(event) => event.stopPropagation()}
									onclick={() => removeGalleryImage(item.id)}
									aria-label={`Hapus foto ${index + 1}`}><X size={14} /></button
								>
								<span class="g-index">{index + 1}</span>
							</div>
						{/each}
						{#if galleryItems.length < MAX_IMAGES}
							<label class="g-add">
								<ImagePlus size={22} /><span>Tambah</span>
								<input
									type="file"
									accept="image/*"
									multiple
									onchange={(event) => selectFiles(event.currentTarget.files)}
								/>
							</label>
						{/if}
					</div>
					<p class="gallery-note">
						{galleryItems.length}/{MAX_IMAGES} foto · ketuk untuk atur filter & rasio, tahan lalu geser
						untuk mengurutkan
					</p>
				</div>
			{:else if previewUrl}
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
						{#if selectedFileKind === 'video'}<video
								src={previewUrl}
								controls
								muted={videoWillMute}
								onloadedmetadata={(event) => {
									const duration = event.currentTarget.duration;
									videoDuration = Number.isFinite(duration) ? Math.max(1, Math.floor(duration)) : 0;
									thumbnailSecond = Math.min(Math.max(1, thumbnailSecond), Math.max(1, videoDuration));
									void refreshThumbnailPreview();
								}}
							></video>
							<button
								type="button"
								class="mute-toggle"
								class:on={videoWillMute}
								disabled={Boolean(selectedMusic)}
								onclick={() => (videoMuted = !videoMuted)}
								aria-pressed={videoWillMute}
								aria-label={videoWillMute ? 'Bunyikan video' : 'Bisukan video'}
								>{#if videoWillMute}<VolumeX size={16} />{:else}<Volume2 size={16} />{/if}
								{videoWillMute ? 'Video dibisukan' : 'Suara video aktif'}</button
							>
							<div class="thumbnail-picker">
								<div>
									<strong>Thumbnail video</strong>
									<small>Default detik pertama. Geser untuk memilih frame lain.</small>
								</div>
								<label
									><span>{formatMusicTime(thumbnailSecond)}</span><input
										type="range"
										min="0"
										max={videoDuration || 1}
										step="0.1"
										value={thumbnailSecond}
										oninput={(event) => {
											thumbnailSecond = Number(event.currentTarget.value);
										}}
										onchange={() => void refreshThumbnailPreview()}
									/></label
								>
								<div class="thumbnail-preview">
									{#if thumbnailPreviewUrl}<img src={thumbnailPreviewUrl} alt="Preview thumbnail video" />
									{:else}<span>{thumbnailGenerating ? 'Membuat preview…' : 'Preview thumbnail belum tersedia'}</span>{/if}
									<button type="button" onclick={() => void refreshThumbnailPreview()} disabled={thumbnailGenerating}>
										{thumbnailGenerating ? 'Memproses…' : 'Jadikan thumbnail'}
									</button>
								</div>
							</div>
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
				{galleryMode ? 'Tambah foto' : file ? 'Ganti media' : 'Pilih dari perangkat'}<input
					type="file"
					accept={acceptedTypes}
					multiple={kind === 'post'}
					onchange={(event) => selectFiles(event.currentTarget.files)}
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
						placeholder="Contoh: Bogor"
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

{#if editingItem}
	<div class="editor-overlay" role="presentation" onclick={() => (editingId = null)}></div>
	<div class="editor-modal" role="dialog" aria-modal="true" aria-label="Edit foto">
		<header>
			<strong>Edit foto</strong>
			<button onclick={() => (editingId = null)} aria-label="Selesai"><X size={18} /></button>
		</header>
		<div class="editor-crop">
			{#key `${editingItem.id}:${editingItem.crop}`}
				<ImageCropper
					src={editingItem.url}
					aspect={editCropAspect}
					label="Atur potongan gambar"
					filterCss={editFilterCss}
					onready={(aspect) => {
						if (editingItem) editingItem.aspect = aspect;
					}}
					onregion={(region) => {
						if (editingItem) editingItem.region = region;
					}}
				/>
			{/key}
		</div>
		<div class="crop-controls" aria-label="Rasio gambar">
			<span>Rasio</span><button
				class:active={editingItem.crop === 'original'}
				onclick={() => setEditCrop('original')}>Asli</button
			><button class:active={editingItem.crop === 'square'} onclick={() => setEditCrop('square')}
				>1:1</button
			><button
				class:active={editingItem.crop === 'portrait'}
				onclick={() => setEditCrop('portrait')}>4:5</button
			>
		</div>
		<div class="filter-controls" aria-label="Filter gambar">
			{#each filterOptions as option (option.id)}<button
					class:active={editingItem.filter === option.id}
					onclick={() => setEditFilter(option.id)}
					><span style:filter={option.css}><img src={editingItem.url} alt="" /></span
					>{option.label}</button
				>{/each}
		</div>
		<button class="editor-done" onclick={() => (editingId = null)}>Selesai</button>
	</div>
{/if}

{#if warning}
	<div class="warn-overlay" role="presentation" onclick={() => (warning = null)}></div>
	<div class="warn-modal" role="alertdialog" aria-modal="true" aria-label="Peringatan">
		<div class="warn-icon"><TriangleAlert size={26} /></div>
		<h3>Media tidak bisa ditambahkan</h3>
		<p>{warning}</p>
		<button onclick={() => (warning = null)}>Mengerti</button>
	</div>
{/if}

<style>
	/* Elemen yang diminta dihilangkan: atribusi lokasi, teks bantuan musik, tombol draft. */
	.attribution,
	.music-help,
	.draft {
		display: none !important;
	}
	.warn-overlay {
		position: fixed;
		inset: 0;
		z-index: 1300;
		background: rgb(20 15 10 / 45%);
		backdrop-filter: blur(2px);
	}
	.warn-modal {
		position: fixed;
		z-index: 1301;
		top: 50%;
		left: 50%;
		display: grid;
		width: min(360px, calc(100% - 40px));
		justify-items: center;
		gap: 8px;
		padding: 26px 24px 22px;
		background: var(--color-surface);
		border-radius: 18px;
		box-shadow: 0 24px 60px rgb(0 0 0 / 28%);
		text-align: center;
		transform: translate(-50%, -50%);
	}
	.warn-icon {
		display: grid;
		width: 56px;
		height: 56px;
		place-items: center;
		background: #fdecdc;
		border-radius: 50%;
		color: #c2570f;
	}
	.warn-modal h3 {
		margin: 6px 0 0;
		font-size: 1.05rem;
	}
	.warn-modal p {
		margin: 0;
		color: var(--color-muted);
		font-size: 0.86rem;
		line-height: 1.5;
	}
	.warn-modal button {
		width: 100%;
		min-height: 44px;
		margin-top: 12px;
		background: var(--color-primary);
		border: 0;
		border-radius: 12px;
		color: white;
		font-weight: 720;
	}
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
		gap: 10px;
		place-items: center;
		overflow: visible;
		border-radius: 16px;
	}
	.preview video {
		width: 100%;
		max-height: 470px;
		object-fit: contain;
		background: #1d1915;
		border-radius: 16px;
	}
	.preview audio {
		margin: 80px 30px;
	}
	.preview > button {
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
	.preview .mute-toggle {
		position: static;
		justify-self: start;
		margin: -48px 0 4px 10px;
		display: flex;
		width: auto;
		height: 34px;
		align-items: center;
		gap: 6px;
		padding: 0 13px;
		border-radius: 999px;
		background: rgb(0 0 0 / 62%);
		font-size: 0.7rem;
		font-weight: 650;
		backdrop-filter: blur(6px);
		z-index: 2;
	}
	.preview .mute-toggle:disabled {
		opacity: 0.9;
	}
	.thumbnail-picker {
		display: grid;
		width: 100%;
		gap: 8px;
		padding: 12px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 14px;
		box-shadow: var(--shadow-xs);
	}
	.thumbnail-picker > div:first-child {
		display: grid;
		gap: 2px;
	}
	.thumbnail-picker strong {
		font-size: 0.8rem;
	}
	.thumbnail-picker small,
	.thumbnail-picker label span {
		color: var(--color-muted);
		font-size: 0.68rem;
	}
	.thumbnail-picker label {
		display: grid;
		grid-template-columns: 42px minmax(0, 1fr);
		align-items: center;
		gap: 9px;
	}
	.thumbnail-picker input {
		width: 100%;
		accent-color: var(--color-primary);
	}
	.thumbnail-preview {
		display: grid;
		grid-template-columns: 86px 1fr;
		align-items: center;
		gap: 10px;
	}
	.thumbnail-preview img,
	.thumbnail-preview span {
		display: grid;
		width: 86px;
		aspect-ratio: 16 / 9;
		place-items: center;
		overflow: hidden;
		background: var(--color-canvas-deep);
		border-radius: 10px;
		color: var(--color-muted);
		font-size: 0.6rem;
		text-align: center;
		object-fit: cover;
	}
	.thumbnail-preview button {
		min-height: 38px;
		padding: 0 12px;
		background: var(--color-primary-soft);
		border: 0;
		border-radius: 11px;
		color: var(--color-primary-strong);
		font-size: 0.74rem;
		font-weight: 720;
	}
	.thumbnail-preview button:disabled {
		opacity: 0.65;
	}
	.crop-editor {
		position: relative;
		width: min(100%, 540px);
	}
	.gallery-edit {
		display: grid;
		width: min(100%, 540px);
		gap: 10px;
	}
	.gallery-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 8px;
	}
	.g-item {
		position: relative;
		aspect-ratio: 1/1;
		overflow: hidden;
		border-radius: 12px;
		background: var(--color-canvas-deep);
		cursor: grab;
		touch-action: none;
		will-change: transform;
		transition:
			transform 240ms cubic-bezier(0.2, 0.9, 0.3, 1),
			box-shadow 180ms ease;
	}
	/* Kartu lain bergeser mulus; kartu yang diseret mengikuti jari tanpa transisi. */
	.g-item.dragging {
		z-index: 6;
		cursor: grabbing;
		box-shadow: 0 14px 30px rgb(0 0 0 / 30%);
		transition: box-shadow 180ms ease;
	}
	/* Saat commit (array disusun ulang), matikan transisi agar tak ada lompatan. */
	.gallery-grid.committing .g-item {
		transition: none;
	}
	.g-item img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		pointer-events: none;
		user-select: none;
	}
	.g-edited {
		position: absolute;
		top: 6px;
		left: 6px;
		display: grid;
		width: 22px;
		height: 22px;
		place-items: center;
		background: var(--color-primary);
		border-radius: 50%;
		color: white;
	}
	.g-remove {
		position: absolute;
		top: 6px;
		right: 6px;
		display: grid;
		width: 26px;
		height: 26px;
		place-items: center;
		padding: 0;
		background: rgb(0 0 0 / 58%);
		border: 0;
		border-radius: 50%;
		color: white;
	}
	.g-index {
		position: absolute;
		bottom: 6px;
		left: 6px;
		min-width: 20px;
		padding: 1px 6px;
		background: rgb(0 0 0 / 55%);
		border-radius: 999px;
		color: white;
		font-size: 0.62rem;
		font-weight: 700;
		text-align: center;
	}
	.g-add {
		display: grid;
		aspect-ratio: 1/1;
		place-content: center;
		justify-items: center;
		gap: 5px;
		background: var(--color-surface-soft);
		border: 2px dashed var(--color-border);
		border-radius: 12px;
		color: var(--color-muted);
		font-size: 0.68rem;
		font-weight: 650;
		cursor: pointer;
	}
	.g-add input {
		position: absolute;
		width: 1px;
		height: 1px;
		overflow: hidden;
		opacity: 0;
	}
	.gallery-note {
		margin: 0;
		color: var(--color-muted);
		font-size: 0.7rem;
		text-align: center;
	}
	.editor-overlay {
		position: fixed;
		inset: 0;
		z-index: 1300;
		background: rgb(20 15 10 / 55%);
		backdrop-filter: blur(2px);
	}
	.editor-modal {
		position: fixed;
		z-index: 1301;
		top: 50%;
		left: 50%;
		display: grid;
		width: min(440px, calc(100% - 28px));
		max-height: 92vh;
		gap: 12px;
		overflow-y: auto;
		padding: 16px;
		background: var(--color-surface);
		border-radius: 18px;
		box-shadow: 0 24px 60px rgb(0 0 0 / 30%);
		transform: translate(-50%, -50%);
	}
	.editor-modal > header {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}
	.editor-modal > header strong {
		font-size: 1rem;
	}
	.editor-modal > header button {
		display: grid;
		width: 34px;
		height: 34px;
		place-items: center;
		border: 0;
		border-radius: 50%;
		background: var(--color-canvas-deep, #f1ece3);
		color: var(--color-muted);
	}
	.editor-crop {
		width: 100%;
	}
	.editor-modal .crop-controls,
	.editor-modal .filter-controls {
		margin-top: 0;
		width: 100%;
	}
	.editor-done {
		min-height: 46px;
		background: var(--color-primary);
		border: 0;
		border-radius: 12px;
		color: white;
		font-weight: 720;
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
