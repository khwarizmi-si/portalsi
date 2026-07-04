import { env } from '$env/dynamic/public';
import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

export type RealtimeStatus = 'connected' | 'connecting' | 'unavailable' | 'disconnected';

let echo: Echo<'reverb'> | null = null;
let subscriberCount = 0;
let activityTimer: number | null = null;

function getEcho(): Echo<'reverb'> | null {
	const key = env.PUBLIC_REVERB_APP_KEY?.trim();
	const host = env.PUBLIC_REVERB_HOST?.trim();
	if (!key || !host || typeof window === 'undefined') return null;
	if (echo) return echo;

	const scheme = env.PUBLIC_REVERB_SCHEME === 'ws' ? 'ws' : 'wss';
	const port = Number.parseInt(env.PUBLIC_REVERB_PORT || (scheme === 'wss' ? '443' : '80'), 10);
	echo = new Echo<'reverb'>({
		broadcaster: 'reverb',
		key,
		wsHost: host,
		wsPort: port,
		wssPort: port,
		forceTLS: scheme === 'wss',
		enabledTransports: ['ws', 'wss'],
		authEndpoint: '/api/broadcasting/auth',
		client: Pusher
	});
	return echo;
}

export function subscribePrivate(
	channelName: string,
	eventName: string,
	onEvent: (payload: unknown) => void,
	onStatus?: (status: RealtimeStatus) => void
): () => void {
	const instance = getEcho();
	if (!instance) {
		onStatus?.('unavailable');
		return () => undefined;
	}

	subscriberCount += 1;
	onStatus?.('connecting');
	const event = eventName.startsWith('.') ? eventName : `.${eventName}`;
	const channel = instance.private(channelName);
	channel.listen(event, onEvent);
	channel.subscribed(() => onStatus?.('connected'));
	channel.error(() => onStatus?.('disconnected'));

	const connection = instance.connector.pusher.connection;
	const connected = () => {
		onStatus?.('connected');
		startActivityHeartbeat();
	};
	const disconnected = () => onStatus?.('disconnected');
	connection.bind('connected', connected);
	connection.bind('disconnected', disconnected);
	connection.bind('unavailable', disconnected);

	return () => {
		channel.stopListening(event, onEvent);
		connection.unbind('connected', connected);
		connection.unbind('disconnected', disconnected);
		connection.unbind('unavailable', disconnected);
		instance.leave(channelName);
		subscriberCount = Math.max(0, subscriberCount - 1);
		if (subscriberCount === 0) {
			instance.disconnect();
			echo = null;
			stopActivityHeartbeat();
		}
	};
}

function startActivityHeartbeat() {
	if (activityTimer !== null) return;
	void heartbeat('websocket/authenticate');
	activityTimer = window.setInterval(() => void heartbeat('websocket/update-activity'), 60_000);
}

function stopActivityHeartbeat() {
	if (activityTimer === null) return;
	window.clearInterval(activityTimer);
	activityTimer = null;
	void heartbeat('websocket/disconnect');
}

async function heartbeat(path: string) {
	try {
		await fetch(`/api/${path}`, { method: 'POST', headers: { Accept: 'application/json' } });
	} catch {
		// Reverb and polling reconnect independently; heartbeat failure is intentionally non-fatal.
	}
}
