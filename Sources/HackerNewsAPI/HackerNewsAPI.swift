
import Foundation
import PromiseKit
import PMKFoundation
import SwiftSoup
import HTMLEntities

struct HackerNewsAPI {

    // MARK: - Errors

    enum APIError: Error {
        case networkingFailed(Error)
        case decodingFailed(Error)
        case parsingFailed(Error)
        case unknown
    }

    // MARK: - Static Properties

    static var urlSession = URLSession.shared

    // MARK: - Static Methods

    static func story(withID id: Int) -> Promise<Story> {
        let hnURL = URL(string: "https://news.ycombinator.com/item?id=\(id)")!
        let apiURL = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json")!
        struct StoryContainer: Decodable {
            var time: Date
            var type: String
        }
        let apiPromise = firstly {
            urlSession.dataTask(.promise, with: apiURL).validate()
        }.recover { error -> Promise<(data: Data, response: URLResponse)> in
            throw APIError.networkingFailed(error)
        }.map { (data, _) -> Date in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let story = try perform(decoder.decode(StoryContainer.self, from: data)) { error in
                APIError.decodingFailed(error)
            }
            guard story.type == "story" else {
                throw APIError.unknown
            }
            let time = story.time
            return time
        }
        let hnPromise = firstly {
            urlSession.dataTask(.promise, with: hnURL).validate()
        }.recover { error -> Promise<(data: Data, response: URLResponse)> in
            throw APIError.networkingFailed(error)
        }.then { (data, response) ->
            Promise<(title: String, score: Int, author: User, url: URL?, text: String?)> in
            let html = String(data: data, urlResponse: response)!
            let document = try perform(SwiftSoup.parse(html)) { error in
                APIError.parsingFailed(error)
            }
            let fatItem = try unwrap(try! document.select(".fatitem").first(),
                                     orThrow: APIError.unknown)
            let rows = try! fatItem.select("table.fatitem > tbody > tr").array()
            guard rows.count == 2 || rows.count == 4 else {
                throw APIError.unknown
            }
            let itemEl = rows[0]
            guard itemEl.id() == String(id) else {
                throw APIError.unknown
            }
            let titleAnchor = try unwrap(try! itemEl.select(".storylink").first(),
                                         orThrow: APIError.unknown)
            let title = try perform(titleAnchor.text(), orThrow: APIError.unknown)
            let subTextEl = rows[1]
            let scoreEl = try! subTextEl.select(".score")
            let scoreText = try perform(scoreEl.text().split(separator: .space)[0],
                                        orThrow: APIError.unknown)
            let score = try unwrap(Int(scoreText), orThrow: APIError.unknown)
            let authorEl = try! subTextEl.select(".hnuser")
            let authorName = try perform(authorEl.text(), orThrow: APIError.unknown)
            var url: URL?
            var text: String?
            if rows.count == 2 {
                // Story with url
                let urlString = try perform(titleAnchor.attr("href"), orThrow: APIError.unknown)
                url = URL(string: urlString)
            } else if rows.count == 4 {
                // Story with text
                let textEl = rows[3].child(1)
                text = try perform(textEl.text(), orThrow: APIError.unknown)
            }
            let promise = firstly {
                user(withName: authorName)
            }.map { author -> (title: String, score: Int, author: User, url: URL?, text: String?) in
                (title, score, author, url, text)
            }
            return promise
        }
        let promise = firstly {
            when(fulfilled: apiPromise, hnPromise)
        }.map { time, storyInfo -> Story in
            let (title, score, author, url, text) = storyInfo
            return Story(id: id, time: time, author: author, score: score, title: title, url: url,
                         text: text, comments: [], actions: [])
        }
        return promise
    }

    static func user(withName name: String) -> Promise<User> {
        let url = URL(string: "https://hacker-news.firebaseio.com/v0/user/\(name).json")!
        struct UserContainer: Decodable {
            var about: String?
            var created: Date
            var karma: Int
        }
        let promise = firstly {
            urlSession.dataTask(.promise, with: url)
        }.map { (data, _) -> User in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let user = try perform(decoder.decode(UserContainer.self, from: data)) { error in
                APIError.decodingFailed(error)
            }
            let creation = user.created
            let description = user.about?.htmlUnescape()
            let karma = user.karma
            return User(creation: creation, description: description, name: name, karma: karma)
        }
        return promise
    }
}
