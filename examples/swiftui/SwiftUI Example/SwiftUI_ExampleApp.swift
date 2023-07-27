import SwiftUI
import PagecallCore

@main
struct SwiftUI_ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView(pagecallWebView: PagecallWebView())
        }
    }
}
