type PagecallNativeBridge = import("./PagecallNative").PagecallNativeBridge;

interface Window {
  PagecallNative: Partial<PagecallNativeBridge>;
  webkit: {
    messageHandlers: {
      pagecall: {
        postMessage: (message: any) => void;
      };
    };
  };
}
