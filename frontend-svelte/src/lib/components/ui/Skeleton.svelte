<script lang="ts">
	// Primitive shimmer block. Compose these to build page skeletons.
	let {
		w = '100%',
		h = '1rem',
		radius = '9px',
		circle = false,
		mb = '0',
		class: className = ''
	}: {
		w?: string;
		h?: string;
		radius?: string;
		circle?: boolean;
		mb?: string;
		class?: string;
	} = $props();
</script>

<span
	class={`sk ${className}`}
	style={`width:${w};height:${h};border-radius:${circle ? '50%' : radius};margin-bottom:${mb};`}
	aria-hidden="true"
></span>

<style>
	.sk {
		display: block;
		flex: none;
		background: #e9e3d7;
		background-image: linear-gradient(
			100deg,
			rgba(255, 255, 255, 0) 30%,
			rgba(255, 255, 255, 0.6) 50%,
			rgba(255, 255, 255, 0) 70%
		);
		background-size: 220% 100%;
		background-repeat: no-repeat;
		animation: sk-shimmer 1.25s ease-in-out infinite;
	}

	@keyframes sk-shimmer {
		0% {
			background-position: 180% 0;
		}
		100% {
			background-position: -80% 0;
		}
	}

	@media (prefers-reduced-motion: reduce) {
		.sk {
			animation: none;
			opacity: 0.85;
		}
	}
</style>
