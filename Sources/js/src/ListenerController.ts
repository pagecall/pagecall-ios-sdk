class ListenerController<T> {
  listenersByEvent: {
    [K in keyof T]?: Set<(payload: T[K]) => void>;
  } = {};

  addListener<K extends keyof T>(
    eventName: K,
    listener: (payload: T[K]) => void
  ) {
    if (!this.listenersByEvent[eventName])
      this.listenersByEvent[eventName] = new Set<(payload: T[K]) => void>();
    this.listenersByEvent[eventName]?.add(listener);
  }

  removeListener<K extends keyof T>(
    eventName: K,
    listener: (payload: T[K]) => void
  ) {
    const listeners = this.listenersByEvent[eventName];
    if (!listeners) return;
    listeners.delete(listener);
  }

  emit<K extends keyof T>(eventName: K, payload: T[K]) {
    const listeners = this.listenersByEvent[eventName];
    if (!listeners) return;
    Array.from(listeners).map((listener) => listener(payload));
  }
}

export default ListenerController;
