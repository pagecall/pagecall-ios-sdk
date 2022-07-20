import type { MediaStat } from "@pagecall/common";

interface ChimeMeetingSessionConfiguration {
  meetingResponse: Record<string, unknown>;
  attendeeResponse: Record<string, unknown>;
}

type PayloadByNativeEvent = {
  audioDevices: MediaDeviceInfo[];
  audioVolume: number;
  remoteAudioStatus: { sessionId: string; muted: boolean };
  mediaStat: MediaStat;
  audioEnded: void;
  videoEnded: void;
  screenshareEnded: void;
  meetingEnded: void;
  error: { name: string; message: string };
};

type NativeEvent = keyof PayloadByNativeEvent;
interface PagecallNativeBridge {
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

  connect: (configuration: ChimeMeetingSessionConfiguration) => Promise<void>;
  disconnect: () => Promise<void>;

  pauseAudio: () => void;
  resumeAudio: () => void;
  setAudioDevice: (deviceId: number) => void;
  getAudioDevices: () => Promise<MediaDeviceInfo[]>;

  startScreenshare: () => void;
  stopScreenshare: () => void;
}

declare global {
  interface Window {
    PagecallNative: Partial<PagecallNativeBridge>;
  }
}

function registerGlobals() {
  window.PagecallNative = {
    useNativeMediaStore: () => {
      return true;
    },
  };
}

registerGlobals();
