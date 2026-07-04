<script lang="ts">
	import { AlertTriangle, HelpCircle, X } from '@lucide/svelte';
	import { confirmState, resolveConfirmation } from '$lib/ui/confirm';
</script>

{#if $confirmState}
	<div class="backdrop" role="presentation" onclick={() => resolveConfirmation(false)}>
		<div
			class:danger={$confirmState.tone === 'danger'}
			role="alertdialog"
			aria-modal="true"
			aria-labelledby="confirm-title"
			aria-describedby="confirm-description"
			onclick={(event) => event.stopPropagation()}
			onkeydown={(event) => event.stopPropagation()}
			tabindex="-1"
		>
			<button class="close" onclick={() => resolveConfirmation(false)} aria-label="Tutup dialog"
				><X size={18} /></button
			>
			<span class="icon"
				>{#if $confirmState.tone === 'danger'}<AlertTriangle size={24} />{:else}<HelpCircle
						size={24}
					/>{/if}</span
			>
			<h2 id="confirm-title">{$confirmState.title}</h2>
			<p id="confirm-description">{$confirmState.description}</p>
			<div class="actions">
				<button class="cancel" onclick={() => resolveConfirmation(false)}
					>{$confirmState.cancelLabel ?? 'Batal'}</button
				>
				<button class="confirm" onclick={() => resolveConfirmation(true)}
					>{$confirmState.confirmLabel ?? 'Lanjutkan'}</button
				>
			</div>
		</div>
	</div>
{/if}

<style>
	.backdrop {
		position: fixed;
		z-index: 900;
		inset: 0;
		display: grid;
		place-items: center;
		padding: 20px;
		background: rgb(29 23 18 / 52%);
		backdrop-filter: blur(8px);
	}
	[role='alertdialog'] {
		position: relative;
		width: min(100%, 420px);
		padding: 25px;
		background: white;
		border: 1px solid var(--color-border);
		border-radius: 22px;
		box-shadow: 0 28px 90px rgb(30 20 10 / 25%);
		animation: appear 0.18s ease-out;
	}
	.icon {
		display: grid;
		width: 50px;
		height: 50px;
		place-items: center;
		background: var(--color-primary-soft);
		border-radius: 15px;
		color: var(--color-primary-strong);
	}
	.danger .icon {
		background: var(--color-danger-soft);
		color: var(--color-danger);
	}
	h2 {
		margin: 16px 0 6px;
		font-size: 1.15rem;
	}
	p {
		margin: 0;
		color: var(--color-muted);
		font-size: 0.84rem;
		line-height: 1.55;
	}
	.close {
		position: absolute;
		top: 14px;
		right: 14px;
		display: grid;
		width: 38px;
		height: 38px;
		place-items: center;
		background: transparent;
		border: 0;
		border-radius: 50%;
		color: var(--color-muted);
	}
	.actions {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 9px;
		margin-top: 22px;
	}
	.actions button {
		min-height: 44px;
		border: 0;
		border-radius: 12px;
		font-size: 0.78rem;
		font-weight: 740;
	}
	.cancel {
		background: var(--color-canvas);
		color: var(--color-muted);
	}
	.confirm {
		background: var(--color-primary);
		color: white;
	}
	.danger .confirm {
		background: var(--color-danger);
	}
	@keyframes appear {
		from {
			opacity: 0;
			transform: translateY(8px) scale(0.98);
		}
	}
</style>
