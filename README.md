# Integrate Pagecall for your iOS Application

[!] macOS is not supported.

## Prerequisites

- Make sure you set `NSMicrophoneUsageDescription`
  - Video call is currently not supported. If you need video conferencing integrated in your service, please contact support@pagecall.com
- Also, Those `UIBackgroundModes` should be enabled: `audio`, `voip`.

## Usages

- Be sure to call the `cleanup` method when a `PagecallWebView` instance is no longer in use.
- Please add the following code. If not added, CallKit may not be activated on the first run, resulting in decreased voice call stability.

```swift
...
class AppDelegate: UIResponder, UIApplicationDelegate {
    ...
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PagecallWebView.configure()
        ...
        return true
    }
}
```

### [UIKit Example](/examples/uikit)
It is not supported to instantiate from a storyboard. You need to programatically create a PagecallWebView or PagecallWebViewController.


## API References

You can learn how to obtain a roomId and manage resources related to Pagecall.

https://docs.pagecall.com/
