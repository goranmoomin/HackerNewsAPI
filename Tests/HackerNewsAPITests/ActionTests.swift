
import XCTest
@testable import HackerNewsAPI

final class ActionTests: XCTestCase {

    func testActionSet() {
        var set: Set<Action> = []
        set.insert(.upvote(URL(string: "https://example.com")!))
        set.insert(.upvote(URL(string: "https://xkcd.com")!))
        XCTAssertEqual(set.count, 1)
    }
}
