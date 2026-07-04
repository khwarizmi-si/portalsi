<script lang="ts">
	import { progressState } from '$lib/ui/progress';
</script>

{#if $progressState.active}
	<div class="progress-track" aria-hidden="true">
		<span class:error={$progressState.status === 'error'} style:width={`${$progressState.value}%`}
		></span>
	</div>
{/if}

<style>
	.progress-track {
		position: fixed;
		z-index: 1000;
		top: 0;
		right: 0;
		left: 0;
		height: 4px;
		background: rgb(255 255 255 / 35%);
		pointer-events: none;
	}
	.progress-track span {
		display: block;
		height: 100%;
		background: linear-gradient(90deg, var(--color-primary), #f5a623 48%, var(--color-secondary));
		box-shadow: 0 0 14px rgb(8 127 114 / 45%);
		transition: width 180ms ease-out;
	}
	.progress-track span.error {
		background: linear-gradient(90deg, var(--color-primary), var(--color-danger));
	}
</style>
