export type CropSettings = { aspect: number; zoom: number; x: number; y: number; maxWidth: number };

export async function cropImageFile(source: File, settings: CropSettings): Promise<File> {
	const bitmap = await createImageBitmap(source);
	let width = bitmap.width;
	let height = bitmap.height;
	if (width / height > settings.aspect) width = height * settings.aspect;
	else height = width / settings.aspect;
	width /= settings.zoom;
	height /= settings.zoom;
	const sourceX = ((bitmap.width - width) * (settings.x + 50)) / 100;
	const sourceY = ((bitmap.height - height) * (settings.y + 50)) / 100;
	const scale = Math.min(1, settings.maxWidth / width);
	const canvas = document.createElement('canvas');
	canvas.width = Math.max(1, Math.round(width * scale));
	canvas.height = Math.max(1, Math.round(height * scale));
	canvas
		.getContext('2d')
		?.drawImage(bitmap, sourceX, sourceY, width, height, 0, 0, canvas.width, canvas.height);
	bitmap.close();
	const blob = await new Promise<Blob>((resolve, reject) =>
		canvas.toBlob(
			(value) => (value ? resolve(value) : reject(new Error('Gambar gagal dipotong.'))),
			'image/jpeg',
			0.9
		)
	);
	return new File([blob], `${source.name.replace(/\.[^.]+$/, '')}-cropped.jpg`, {
		type: 'image/jpeg',
		lastModified: Date.now()
	});
}
