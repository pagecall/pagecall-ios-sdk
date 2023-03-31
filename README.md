# Integrate Pagecall for your iOS Application

[!] Bitcode is not supported, because it depends on [amazon-chime-sdk-ios](https://github.com/aws/amazon-chime-sdk-ios)'s binary file without bitcode.

## Prerequisites

- Make sure you set `NSMicrophoneUsageDescription`, and `NSCameraUsageDescription` if you are creating a video call application.
- Also, Those `UIBackgroundModes` should be enabled: `audio`, `fetch`, `voip`.

## Usage

- It is not suppored to instantiate from a storyboard, because a required `WKWebViewConfiguration` cannot be applied with it.

### 1. Programatically create a PagecallWebView

```swift
import UIKit
import WebKit
import PagecallCore

class ViewController: UIViewController, WKUIDelegate {
    var webView: PagecallWebView?

    override func viewDidLoad() {
        super.viewDidLoad()
        let webView = PagecallWebView(frame: CGRect.zero)
        self.webView = webView
        self.view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 80.0).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20.0).isActive = true
        webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20.0).isActive = true
        webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20.0).isActive = true

        if let meetUrl = URL(string: "https://app.pagecall.com/meet?room_id=64269ab541f8f8e9d7320374") {
            webView.load(URLRequest(url: meetUrl))
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        webView?.dispose()
        webView = nil
    }
}
```

## Tips

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
