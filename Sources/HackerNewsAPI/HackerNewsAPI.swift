
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

    static func logout() {
        guard let storage = urlSession.configuration.httpCookieStorage else {
            return
        }
        storage.removeCookies(since: .distantPast)
    }

    static func login(toAccount account: String, password: String) -> Promise<Void> {
        let url = URL(string: "https://news.ycombinator.com/login?acct=\(account)&pw=\(password)")!
        let promise = firstly {
            urlSession.dataTask(.promise, with: url).validate()
        }.recover { error -> Promise<(data: Data, response: URLResponse)> in
            throw APIError.networkingFailed(error)
        }.asVoid()
        return promise
    }

    static func story(withID id: Int) -> Promise<Story> {
        let url = URL(string: "https://news.ycombinator.com/item?id=\(id)")!
        let promise = firstly {
            urlSession.dataTask(.promise, with: url).validate()
        }.recover { error -> Promise<(data: Data, response: URLResponse)> in
            throw APIError.networkingFailed(error)
        }.then { (data, response) -> Promise<Story> in
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
            let commentEls = try! document.select(".comtr").array()
            var commentsPerLevel: [[Comment]] = [[]]
            for commentEl in commentEls {
                let currentLevel = commentsPerLevel.count - 1
                let indentEl = try unwrap(try! commentEl.select(".ind > img").first(),
                                          orThrow: APIError.unknown)
                let indentWidth = try perform(indentEl.attr("width"), orThrow: APIError.unknown)
                let level = try unwrap(Int(indentWidth), orThrow: APIError.unknown) / 40
                guard level <= currentLevel + 1 else {
                    throw APIError.unknown
                }
                let id = try unwrap(Int(commentEl.id()), orThrow: APIError.unknown)
                let authorEl = try unwrap(try! commentEl.select(".hnuser").first(),
                                          orThrow: APIError.unknown)
                let authorName = try perform(authorEl.text(), orThrow: APIError.unknown)
                let text = try perform(commentEl.select(".commtext").html(),
                                       orThrow: APIError.unknown)
                let comment = Comment(id: id, author: User(creation: Date(), description: nil,
                                                           name: authorName, karma: 0),
                                      text: text, comments: [], actions: [])
                if level <= currentLevel {
                    while commentsPerLevel.count > level + 1 {
                        let currentComments = try unwrap(commentsPerLevel.popLast(),
                                                         orThrow: APIError.unknown)
                        let currentLevel = commentsPerLevel.count - 1
                        let preCommentsCount = commentsPerLevel[currentLevel].count
                        commentsPerLevel[currentLevel][preCommentsCount - 1].comments
                            = currentComments
                    }
                    let currentLevel = commentsPerLevel.count - 1
                    commentsPerLevel[currentLevel].append(comment)
                } else {
                    // level = currentLevel + 1
                    commentsPerLevel.append([comment])
                }
            }
            while commentsPerLevel.count > 1 {
                let currentComments = try unwrap(commentsPerLevel.popLast(),
                                                 orThrow: APIError.unknown)
                let currentLevel = commentsPerLevel.count - 1
                let preCommentsCount = commentsPerLevel[currentLevel].count
                commentsPerLevel[currentLevel][preCommentsCount - 1].comments
                    = currentComments
            }
            guard commentsPerLevel.count == 1 else {
                throw APIError.unknown
            }
            let comments = commentsPerLevel[0]
            let promise = firstly {
                user(withName: authorName)
            }.map { author -> Story in
                Story(id: id, author: author, score: score, title: title, url: url, text: text,
                      comments: comments, actions: [])
            }
            return promise
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
