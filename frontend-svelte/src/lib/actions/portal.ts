/**
 * Pindahkan elemen ke <body> (portal), agar tidak terjebak di dalam ancestor yang
 * memakai transform/overflow (mis. panel modal). Penting untuk overlay fullscreen
 * agar posisinya relatif ke viewport, bukan ke modal.
 */
export function portal(node: HTMLElement, target: HTMLElement | string = 'body') {
	let destination: HTMLElement | null;
	function mount(t: HTMLElement | string) {
		destination = typeof t === 'string' ? document.querySelector<HTMLElement>(t) : t;
		if (destination) destination.appendChild(node);
	}
	mount(target);
	return {
		update(t: HTMLElement | string) {
			mount(t);
		},
		destroy() {
			node.parentNode?.removeChild(node);
		}
	};
}
