import XCTest
@testable import HackerNewsAPI

final class HackerNewsAPITests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(HackerNewsAPI().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
