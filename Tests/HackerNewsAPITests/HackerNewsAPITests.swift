import XCTest
import PromiseKit
@testable import HackerNewsAPI

final class HackerNewsAPITests: XCTestCase {

    func testLoadingURLStory() {
        do {
            let story = try hang(HackerNewsAPI.story(withID: 21997622))
            XCTAssertEqual(story.author.name, "pcr910303")
            XCTAssertEqual(story.id, 21997622)
            XCTAssertEqual(story.score, 115)
            XCTAssertEqual(story.text, nil)
            XCTAssertEqual(story.url, URL(string: "http://ijzerenhein.github.io/autolayout.js/"))
            XCTAssertEqual(story.time, Date(timeIntervalSince1970: 1578533115))
            XCTAssertEqual(story.title,
                           "Apple's auto layout and visual format language for JavaScript (2016)")
        } catch {
            XCTFail("Error \(error) thrown.")
        }
    }

    func testLoadingTextStory() {
        do {
            let story = try hang(HackerNewsAPI.story(withID: 121003))
            XCTAssertEqual(story.author.name, "tel")
            XCTAssertEqual(story.id, 121003)
            XCTAssertEqual(story.score, 25)
            XCTAssert(story.text?.hasPrefix("or HN: the Next Iteration") ?? false)
            XCTAssertEqual(story.time, Date(timeIntervalSince1970: 1203647620))
            XCTAssertEqual(story.title, "Ask HN: The Arc Effect")
        } catch {
            XCTFail("Error \(error) thrown.")
        }
    }

    static var allTests = [
        ("Story with URL", testLoadingURLStory),
        ("Story with text", testLoadingTextStory)
    ]
}
