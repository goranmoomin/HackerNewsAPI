import XCTest
import PromiseKit
@testable import HackerNewsAPI

final class HackerNewsAPITests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        do {
            let text = try hang(HackerNewsAPI.example())
            XCTAssertEqual(text, "HTTPBIN is awesome")
        } catch {
            XCTFail("Error \(error) thrown.")
        }
    }

    static var allTests: [(String, (HackerNewsAPITests) -> () -> ())] = []
}
