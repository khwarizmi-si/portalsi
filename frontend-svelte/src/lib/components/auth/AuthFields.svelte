<script lang="ts">
	import type { Snippet } from 'svelte';
	let { children }: { children: Snippet } = $props();
</script>

<div class="auth-fields">{@render children()}</div>

<style>
	.auth-fields {
		display: grid;
		gap: 15px;
	}

	:global(.auth-fields label) {
		display: grid;
		gap: 7px;
		color: var(--color-text);
		font-size: 0.83rem;
		font-weight: 680;
	}

	:global(.auth-fields input),
	:global(.auth-fields select) {
		width: 100%;
		height: 49px;
		padding: 0 14px;
		background: var(--color-surface);
		border: 1px solid var(--color-border-strong);
		border-radius: 12px;
		outline: none;
	}

	:global(.auth-fields input:focus),
	:global(.auth-fields select:focus) {
		border-color: var(--color-primary);
		box-shadow: var(--focus-ring);
	}

	:global(.auth-primary) {
		display: flex;
		height: 50px;
		align-items: center;
		justify-content: center;
		margin-top: 4px;
		background: var(--color-primary);
		border: 0;
		border-radius: 12px;
		box-shadow: 0 10px 24px rgb(232 117 11 / 20%);
		color: white;
		font-weight: 740;
		cursor: pointer;
	}

	:global(.auth-primary:hover) {
		background: var(--color-primary-strong);
		transform: translateY(-1px);
	}
</style>
