<script lang="ts">
	let { text, class: className = '' }: { text: string; class?: string } = $props();
	const parts = $derived(text.split(/(@[A-Za-z0-9._]+)/g));
</script>

<span class={className}
	>{#each parts as part, index (index)}{#if /^@[A-Za-z0-9._]+$/.test(part)}<a
				href={`/u/${part.slice(1)}`}>{part}</a
			>{:else}{part}{/if}{/each}</span
>

<style>
	a {
		color: var(--color-primary-strong);
		font-weight: 720;
	}
</style>
