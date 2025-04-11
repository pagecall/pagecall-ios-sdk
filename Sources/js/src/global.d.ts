type PagecallNativeBridge = import("./PagecallNative").PagecallNativeBridge;

interface Window {
  PagecallNative: Partial<PagecallNativeBridge>;
  PN: Partial<PagecallNativeBridge>;
  webkit: {
    messageHandlers: {
      pagecall: {
        postMessage: (message: any) => void;
      };
    };
  };
}
