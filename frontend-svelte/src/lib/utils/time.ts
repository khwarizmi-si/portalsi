export function relativeTimeId(value: string | Date, now = new Date()): string {
	const date = value instanceof Date ? value : new Date(value);
	if (Number.isNaN(date.getTime())) return 'Waktu tidak diketahui';
	const seconds = Math.round((date.getTime() - now.getTime()) / 1000);
	const absolute = Math.abs(seconds);
	const formatter = new Intl.RelativeTimeFormat('id', { numeric: 'auto' });

	if (absolute < 60) return formatter.format(seconds, 'second');
	if (absolute < 3_600) return formatter.format(Math.round(seconds / 60), 'minute');
	if (absolute < 86_400) return formatter.format(Math.round(seconds / 3_600), 'hour');
	if (absolute < 604_800) return formatter.format(Math.round(seconds / 86_400), 'day');
	return new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short' }).format(date);
}
