import SwiftUI
import PagecallCore

@available(iOS 15.0, *)
@main
struct SwiftUI_ExampleApp: App {
    let pagecallWebView = PagecallWebView()
    let pagecallManager = PagecallManager()
    
    init() {
        pagecallWebView.delegate = pagecallManager
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView(pagecallWebView: pagecallWebView)
        }
    }
}
