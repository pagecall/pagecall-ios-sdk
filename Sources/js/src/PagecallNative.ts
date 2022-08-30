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
  }) => Promise<{ video?: boolean | null; audio?: boolean | null }>;
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
}

export type PagecallNativeBridge = PagecallNativePublic & PagecallNativePrivate;

function registerGlobals() {
  const requestController = new RequestController();
  const listenerController = new ListenerController<PayloadByNativeEvent>();

  const postMessage = (
    data: { action: string; payload?: string },
    callback?: Callback
  ) => {
    const { action, payload } = data;
    const requestId = callback
      ? requestController.request(callback)
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
      return new Promise<void>((resolve) => {
        postMessage(
          { action: "createSession", payload: JSON.stringify(configuration) },
          () => {
            resolve();
          }
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
      return new Promise((resolve) => {
        postMessage(
          { action: "getPermissions", payload: JSON.stringify(constraints) },
          (response: { video?: boolean | null; audio?: boolean | null }) => {
            resolve(response);
          }
        );
      });
    },
    requestPermissions: (constraints: { video: boolean; audio: boolean }) => {
      return new Promise((resolve) => {
        postMessage(
          {
            action: "requestPermissions",
            payload: JSON.stringify(constraints),
          },
          (response: { video?: boolean; audio?: boolean }) => {
            resolve(response);
          }
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
      return new Promise((resolve) => {
        postMessage(
          { action: "getAudioDevices" },
          (response: MediaDeviceInfo[]) => {
            resolve(response);
          }
        );
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
  };

  window.PagecallNative = { ...pagecallNativePrivate, ...pagecallNativePublic };
}

registerGlobals();
