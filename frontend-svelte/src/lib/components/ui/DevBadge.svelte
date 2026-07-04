<script lang="ts">
	let { label = 'Pengembang Portal SI' }: { label?: string } = $props();
</script>

<span class="dev-badge" aria-label={label} title={label}><b>&lt;/&gt;</b> DEV</span>

<style>
	.dev-badge {
		display: inline-flex;
		height: 18px;
		align-items: center;
		gap: 3px;
		padding: 0 6px;
		background: linear-gradient(135deg, #111827, #334155);
		border: 1px solid rgb(255 255 255 / 16%);
		border-radius: 6px;
		box-shadow: 0 2px 7px rgb(15 23 42 / 20%);
		color: #e0f2fe;
		font-size: 0.52rem;
		font-weight: 850;
		letter-spacing: 0.06em;
		line-height: 1;
		vertical-align: middle;
	}
	.dev-badge b {
		color: #38bdf8;
		font-size: 0.58rem;
		letter-spacing: -0.1em;
	}
</style>
