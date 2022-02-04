# Integrate Pagecall for your iOS Application

[!] Bitcode is not supported, because it depends on WebRTC framework which does not supported bitcode for now.

## Prerequisites
- Make sure you set `NSMicrophoneUsageDescription`, and `NSCameraUsageDescription` if you are creating a video call application.
- Also, Those `UIBackgroundModes` should be enabled: `audio`, `fetch`, `voip`.

## Usage
- It is not suppored to instantiate from a storyboard, because a required `WKWebViewConfiguration` cannot be applied with it.

### Programatically create a PagecallWebView
```swift
import UIKit
import WebKit
import PagecallSDK

class ViewController: UIViewController, WKUIDelegate {
    var webView: PagecallWebView?

    override func viewDidLoad() {
        super.viewDidLoad()
        let webView = PagecallWebView(frame: CGRect.zero)
        webView.load(URLRequest(url: "https://app.pagecall.net/my_room_id"))
        self.view.addSubview(webView)
        self.webView = webView

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 80.0).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20.0).isActive = true
        webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20.0).isActive = true
        webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20.0).isActive = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        // If it is not called, the webView can still have the access to microphone or camera
        webView?.dispose()
        webView = nil
    }
}
```

## Tips
- You may not want to ask for permission everytime an user enters the meeting room. From iOS 15.0, you can opt in not to ask again.
    ```swift
    class ViewController: UIViewController, WKUIDelegate {
        override func viewDidLoad() {
            // Wherever a PagecallWebView is created
            webView.uiDelegate = self
        }

        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
    }
    ```
- If you want something to happen on a webview closing, you need to handle it in your view controller.
    ```swift
    class ViewController: UIViewController, WKUIDelegate {
        override func viewDidLoad() {
            // Wherever a PagecallWebView is created
            webView.uiDelegate = self
        }
      
        func webViewDidClose(_ webView: WKWebView) {
            self.dismiss(animated: true)
        }
    }
    ```
