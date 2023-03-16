import type { MediaStat } from "@pagecall/common";
import ListenerController from "./ListenerController";
import RequestController, { Callback } from "./RequestController";

interface ChimeMeetingSessionConfiguration {
  meetingResponse: Record<string, unknown>;
  attendeeResponse: Record<string, unknown>;
}

type PayloadByNativeEvent = {
  audioDevice: MediaDeviceInfo;
  audioDevices: MediaDeviceInfo[];
  audioVolume: number;
  audioStatus: { sessionId: string; muted: boolean };
  audioSessionRouteChanged: {
    reason: string;
    outputs: { portType: string; portName: string; uid: string }[];
    category: string;
  };
  audioSessionInterrupted: {
    reason: "Default" | "BuiltInMicMuted" | "Unknown" | "None";
    type: "Began" | "Ended" | "Unknown" | "None";
    options: "ShouldResume" | "Unknown" | "None";
  }
  mediaStat: MediaStat;
  audioEnded: void;
  videoEnded: void;
  connected: void;
  disconnected: void;
  screenshareEnded: void;
  meetingEnded: void;
  log: string;
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
  dispose: () => void;

  getPermissions: (constraints: {
    video: boolean;
    audio: boolean;
  }) => Promise<{ video?: boolean; audio?: boolean }>;
  requestPermission: (mediaType: "audio" | "video") => Promise<boolean>;

  pauseAudio: () => void;
  resumeAudio: () => void;
  setAudioDevice: (deviceId: string) => void;
  getAudioDevices: () => Promise<MediaDeviceInfo[]>;
  requestAudioVolume: () => Promise<number>;

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

  const pagecallNativePublicStatic: Partial<PagecallNativePublic> = {
    getPlatform: () => 'ios',
    useNativeMediaStore: () => true,
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
    requestPermission: (mediaType) => {
      return new Promise((resolve, reject) => {
        postMessage(
          {
            action: "requestPermission",
            payload: JSON.stringify({ mediaType }),
          },
          { resolve, reject }
        );
      });
    },
    setAudioDevice: (deviceId) => {
      postMessage({
        action: "setAudioDevice",
        payload: JSON.stringify({ deviceId }),
      });
    },
  };
  const pagecallNative = new Proxy({
    ...pagecallNativePrivate,
    ...pagecallNativePublicStatic
  }, {
    get(staticMethods, action) {
      const staticMethod = staticMethods[action as keyof typeof staticMethods];
      if (staticMethod) return staticMethod;
      if (typeof action === 'symbol') throw new Error('Invalid access');
      return (payload: unknown) => new Promise((resolve, reject) => {
        postMessage(
          { action, payload: JSON.stringify(payload) },
          { resolve, reject }
        );
      });
    }
  });

  window.PagecallNative = pagecallNative
}

registerGlobals();
