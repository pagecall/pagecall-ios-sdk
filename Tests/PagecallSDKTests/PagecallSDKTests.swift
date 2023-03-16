@testable import PagecallCore
import XCTest

final class PagecallSDKTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let webView = PagecallWebView()
        XCTAssertEqual(webView.url, nil)
    }
}
