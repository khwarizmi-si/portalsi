export type CropRegion = {
	/** Left edge of the crop rectangle in natural source pixels. */
	sx: number;
	/** Top edge of the crop rectangle in natural source pixels. */
	sy: number;
	/** Width of the crop rectangle in natural source pixels. */
	sw: number;
	/** Height of the crop rectangle in natural source pixels. */
	sh: number;
};

/**
 * Render the exact region selected in the cropper to a JPEG file. The region is
 * expressed in natural source pixels, so the output matches the preview 1:1.
 */
export async function cropImageToRegion(
	source: File,
	region: CropRegion,
	maxWidth: number,
	filter = 'none'
): Promise<File> {
	const bitmap = await createImageBitmap(source);
	const sw = Math.max(1, Math.min(region.sw, bitmap.width));
	const sh = Math.max(1, Math.min(region.sh, bitmap.height));
	const sx = Math.min(Math.max(0, region.sx), bitmap.width - sw);
	const sy = Math.min(Math.max(0, region.sy), bitmap.height - sh);
	const scale = Math.min(1, maxWidth / sw);
	const canvas = document.createElement('canvas');
	canvas.width = Math.max(1, Math.round(sw * scale));
	canvas.height = Math.max(1, Math.round(sh * scale));
	const context = canvas.getContext('2d');
	if (context) {
		context.filter = filter;
		context.drawImage(bitmap, sx, sy, sw, sh, 0, 0, canvas.width, canvas.height);
	}
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
