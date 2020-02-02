
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
        }.map { (data, response) -> Story in
            let html = String(data: data, urlResponse: response)!
            let document = try perform(SwiftSoup.parse(html)) { error in
                APIError.parsingFailed(error)
            }
            let parser = StoryParser(document: document)
            let authorName = try parser.authorName()
            let ageDescription = try parser.ageDescription()
            let score = try parser.score()
            let title = try parser.title()
            let actions = try parser.actions()
            let (url, text) = try parser.content()
            let comments = try parser.commentTree()
            let story = Story(id: id, authorName: authorName, ageDescription: ageDescription,
                              score: score, title: title, url: url, text: text, comments: comments,
                              actions: actions)
            return story
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
