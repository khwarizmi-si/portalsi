<script lang="ts">
	import { GraduationCap, HeartHandshake } from '@lucide/svelte';
	let { role }: { role: 'teacher' | 'parent' } = $props();
</script>

<span
	class:teacher={role === 'teacher'}
	class:parent={role === 'parent'}
	title={role === 'teacher' ? 'Teacher' : 'Parent'}
>
	{#if role === 'teacher'}<GraduationCap size={11} /> Teacher{:else}<HeartHandshake size={11} /> Parent{/if}
</span>

<style>
	span {
		display: inline-flex;
		height: 20px;
		align-items: center;
		gap: 3px;
		padding: 0 7px;
		border: 1px solid;
		border-radius: 999px;
		font-size: 0.57rem;
		font-weight: 800;
		letter-spacing: 0.02em;
		line-height: 1;
	}
	.teacher {
		background: linear-gradient(135deg, #eaf8f4, #dff3ec);
		border-color: #9bd4c4;
		color: #14745f;
	}
	.parent {
		background: linear-gradient(135deg, #fff3df, #fce5c5);
		border-color: #efc98f;
		color: #9a5716;
	}
</style>
