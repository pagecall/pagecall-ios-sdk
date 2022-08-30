import type { MediaStat } from "@pagecall/common";
import ListenerController from "./ListenerController";
import RequestController, { Callback } from "./RequestController";

interface ChimeMeetingSessionConfiguration {
  meetingResponse: Record<string, unknown>;
  attendeeResponse: Record<string, unknown>;
}

type PayloadByNativeEvent = {
  audioDevices: MediaDeviceInfo[];
  audioVolume: number;
  audioStatus: { sessionId: string; muted: boolean };
  mediaStat: MediaStat;
  audioEnded: void;
  videoEnded: void;
  screenshareEnded: void;
  meetingEnded: void;
  error: { name: string; message: string };
};

type NativeEvent = keyof PayloadByNativeEvent;
interface PagecallNativePublic {
  getPlatform: () => "android" | "ios";
  useNativeMediaStore: () => boolean;

  addListener<T extends NativeEvent>(
    eventName: T,
    listener: (payload: PayloadByNativeEvent[T]) => void
  ): void;
  removeListener<T extends NativeEvent>(
    eventName: T,
    listener: (payload: PayloadByNativeEvent[T]) => void
  ): void;

  createSession: (
    configuration: ChimeMeetingSessionConfiguration
  ) => Promise<void>;
  start: () => void;
  stop: () => void;

  getPermissions: (constraints: {
    video: boolean;
    audio: boolean;
  }) => Promise<{ video?: boolean; audio?: boolean }>;
  requestPermissions: (constraints: {
    video: boolean;
    audio: boolean;
  }) => Promise<{ video?: boolean; audio?: boolean }>;

  pauseAudio: () => void;
  resumeAudio: () => void;
  setAudioDevice: (deviceId: string) => void;
  getAudioDevices: () => Promise<MediaDeviceInfo[]>;

  startScreenshare: () => void;
  stopScreenshare: () => void;
}

interface PagecallNativePrivate {
  emit<T extends NativeEvent>(eventName: T, payload?: string): void;
  response(requestId: string, payload?: string): void;
  throw(requestId: string, message?: string): void;
}

export type PagecallNativeBridge = PagecallNativePublic & PagecallNativePrivate;

function registerGlobals() {
  const requestController = new RequestController();
  const listenerController = new ListenerController<PayloadByNativeEvent>();

  const postMessage = (
    data: { action: string; payload?: string },
    callback?: { resolve: Callback; reject: Callback }
  ) => {
    const { action, payload } = data;
    const requestId = callback
      ? requestController.request(callback.resolve, callback.reject)
      : undefined;
    window.webkit.messageHandlers.pagecall.postMessage(
      JSON.stringify({ action, payload, requestId })
    );
  };

  const pagecallNativePublic: Partial<PagecallNativePublic> = {
    getPlatform: () => {
      return "ios";
    },
    useNativeMediaStore: () => {
      return true;
    },

    addListener: <T extends NativeEvent>(
      eventName: T,
      listener: (payload: PayloadByNativeEvent[T]) => void
    ) => {
      listenerController.addListener(eventName, listener);
    },
    removeListener: <T extends NativeEvent>(
      eventName: T,
      listener: (payload: PayloadByNativeEvent[T]) => void
    ) => {
      listenerController.removeListener(eventName, listener);
    },

    createSession: (configuration: ChimeMeetingSessionConfiguration) => {
      return new Promise((resolve, reject) => {
        postMessage(
          { action: "createSession", payload: JSON.stringify(configuration) },
          { resolve, reject }
        );
      });
    },
    start: () => {
      postMessage({ action: "start" });
    },
    stop: () => {
      postMessage({ action: "stop" });
    },

    getPermissions: (constraints: { video: boolean; audio: boolean }) => {
      return new Promise((resolve, reject) => {
        postMessage(
          { action: "getPermissions", payload: JSON.stringify(constraints) },
          { resolve, reject }
        );
      });
    },
    requestPermissions: (constraints: { video: boolean; audio: boolean }) => {
      return new Promise((resolve, reject) => {
        postMessage(
          {
            action: "requestPermissions",
            payload: JSON.stringify(constraints),
          },
          { resolve, reject }
        );
      });
    },

    pauseAudio: () => {
      postMessage({ action: "pauseAudio" });
    },
    resumeAudio: () => {
      postMessage({ action: "resumeAudio" });
    },
    setAudioDevice: (deviceId: string) => {
      postMessage({
        action: "setAudioDevice",
        payload: JSON.stringify({ deviceId }),
      });
    },
    getAudioDevices: () => {
      return new Promise((resolve, reject) => {
        postMessage({ action: "getAudioDevices" }, { resolve, reject });
      });
    },
  };

  const pagecallNativePrivate: Partial<PagecallNativePrivate> = {
    emit: (eventName, payload) => {
      const parsedPayload = payload ? JSON.parse(payload) : undefined;
      listenerController.emit(eventName, parsedPayload);
    },

    response: (requestId, payload) => {
      const parsedPayload = payload ? JSON.parse(payload) : undefined;
      requestController.response(requestId, parsedPayload);
    },

    throw: (requestId, message) => {
      requestController.throw(requestId, message);
    },
  };

  window.PagecallNative = { ...pagecallNativePrivate, ...pagecallNativePublic };
}

registerGlobals();
