function registerGlobals() {
  window.PagecallNativeBridge = {
    useNativeMediaStore: () => {
      return true;
    },
  };
}

registerGlobals();
