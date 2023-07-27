import SwiftUI
import PagecallCore

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
