<script lang="ts">
	let { text, class: className = '' }: { text: string; class?: string } = $props();

	type Segment =
		| { kind: 'text'; value: string }
		| { kind: 'mention'; value: string }
		| { kind: 'internal'; value: string; href: string }
		| { kind: 'external'; value: string; href: string };

	function internalHref(raw: string): string | null {
		try {
			const url = new URL(raw);
			if (/(^|\.)portalsi\.com$/i.test(url.hostname)) {
				return `${url.pathname}${url.search}${url.hash}` || '/';
			}
			return null;
		} catch {
			return null;
		}
	}

	const segments = $derived.by<Segment[]>(() => {
		const pieces = text.split(/(@[A-Za-z0-9._]+|https?:\/\/[^\s]+)/g);
		return pieces
			.filter((piece) => piece.length > 0)
			.map((piece): Segment => {
				if (/^@[A-Za-z0-9._]+$/.test(piece)) return { kind: 'mention', value: piece };
				if (/^https?:\/\//.test(piece)) {
					// Pisahkan tanda baca penutup yang ikut menempel pada URL.
					const trailing = piece.match(/[),.!?;:]+$/)?.[0] ?? '';
					const link = trailing ? piece.slice(0, -trailing.length) : piece;
					const internal = internalHref(link);
					if (internal) return { kind: 'internal', value: piece, href: internal };
					return { kind: 'external', value: piece, href: link };
				}
				return { kind: 'text', value: piece };
			});
	});
</script>

<span class={className}
	>{#each segments as segment, index (index)}{#if segment.kind === 'mention'}<a
				href={`/u/${segment.value.slice(1)}`}>{segment.value}</a
			>{:else if segment.kind === 'internal'}<a href={segment.href} data-sveltekit-preload-data
				>{segment.value}</a
			>{:else if segment.kind === 'external'}<a
				href={segment.href}
				target="_blank"
				rel="noopener noreferrer nofollow">{segment.value}</a
			>{:else}{segment.value}{/if}{/each}</span
>

<style>
	a {
		color: var(--color-primary-strong);
		font-weight: 720;
		overflow-wrap: anywhere;
	}
</style>
