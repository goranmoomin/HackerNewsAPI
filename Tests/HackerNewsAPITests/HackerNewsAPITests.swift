import XCTest
import PromiseKit
@testable import HackerNewsAPI

final class HackerNewsAPITests: XCTestCase {

    func testLogin() {
        do {
            HackerNewsAPI.logout()
            try hang(HackerNewsAPI.login(toAccount: "hntestacc", password: "hntestpwd"))
            let story = try hang(HackerNewsAPI.story(withID: 22254596))
            XCTAssertEqual(story.actions, [])
        } catch {
            XCTFail("Error \(error) thrown.")
        }
    }

    func testLoadingTopItems() {
        do {
            let items = try hang(HackerNewsAPI.topItems())
            XCTAssertEqual(items.count, 30)
        } catch {
            XCTFail("Error \(error) thrown.")
        }
    }

    func testLoadingNewItems() {
        do {
            let items = try hang(HackerNewsAPI.newItems())
            XCTAssertEqual(items.count, 30)
        } catch {
            XCTFail("Error \(error) thrown.")
        }
    }

    func testLoadingURLStory() {
        do {
            let story = try hang(HackerNewsAPI.story(withID: 21997622))
            XCTAssertEqual(story.authorName, "pcr910303")
            XCTAssertEqual(story.id, 21997622)
            XCTAssertEqual(story.score, 115)
            XCTAssertEqual(story.text, nil)
            XCTAssertEqual(story.url, URL(string: "http://ijzerenhein.github.io/autolayout.js/"))
            XCTAssertEqual(story.title,
                           "Apple's auto layout and visual format language for JavaScript (2016)")
            XCTAssertEqual(story.comments.count, 9)
            XCTAssertEqual(story.comments[0].comments.count, 2)
            XCTAssert(story.comments[0].text.hasPrefix("I find this layout"))
            XCTAssertEqual(story.comments[0].actions.map({ $0.kind }), [.upvote])
        } catch {
            XCTFail("Error \(error) thrown.")
        }
    }

    func testLoadingTextStory() {
        do {
            let story = try hang(HackerNewsAPI.story(withID: 121003))
            XCTAssertEqual(story.authorName, "tel")
            XCTAssertEqual(story.id, 121003)
            XCTAssertEqual(story.score, 25)
            XCTAssert(story.text?.hasPrefix("or HN: the Next Iteration") ?? false)
            XCTAssertEqual(story.title, "Ask HN: The Arc Effect")
            XCTAssertEqual(story.actions.map({ $0.kind }), [.upvote])
        } catch {
            XCTFail("Error \(error) thrown.")
        }
    }

    func testLoadingURLJob() {
        do {
            let job = try hang(HackerNewsAPI.job(withID: 22188212))
            XCTAssertEqual(job.id, 22188212)
            XCTAssertEqual(job.title, "XIX (YC W17) Is Hiring Engineers in San Francisco")
            XCTAssertEqual(job.url, URL(string: "https://jobs.lever.co/xix"))
            XCTAssertEqual(job.text, nil)
        } catch {
            XCTFail("Error \(error) thrown.")
        }
    }

    func testLoadingTextJob() {
        do {
            let job = try hang(HackerNewsAPI.job(withID: 192327))
            XCTAssertEqual(job.id, 192327)
            XCTAssertEqual(job.ageDescription, "on May 16, 2008")
            XCTAssertEqual(job.title, "Justin.tv is looking for a Lead Flash Engineer!")
            XCTAssertEqual(job.url, nil)
            XCTAssert(job.text?.hasPrefix("Justin.tv is the biggest live") ?? false)
        } catch {
            XCTFail("Error \(error) thrown.")
        }
    }

    func testLoadingUser() {
        do {
            let user = try hang(HackerNewsAPI.user(withName: "pcr910303"))
            XCTAssertEqual(user.creation, Date(timeIntervalSince1970: 1553991192))
            XCTAssertEqual(user.description, "pcr910303 <at> icloud <dot> com")
            XCTAssertEqual(user.name, "pcr910303")
        } catch {
            XCTFail("Error \(error) thrown.")
        }
    }

    func testLoadingUserWithoutDescription() {
        do {
            let user = try hang(HackerNewsAPI.user(withName: "gshdg"))
            XCTAssertEqual(user.creation, Date(timeIntervalSince1970: 1556329319))
            XCTAssertEqual(user.description, nil)
            XCTAssertEqual(user.name, "gshdg")
        } catch {
            XCTFail("Error \(error) thrown.")
        }
    }

    static var allTests = [
        ("Story with URL", testLoadingURLStory),
        ("Story with text", testLoadingTextStory),
        ("User with description", testLoadingUser),
        ("User without description", testLoadingUserWithoutDescription)
    ]
}
