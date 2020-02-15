
import Foundation
import PromiseKit
import PMKFoundation
import SwiftSoup

public struct HackerNewsAPI {

    // MARK: - Errors

    public enum APIError: Error {
        case networkingFailed(Error)
        case decodingFailed(Error)
        case parsingFailed(Error)
        case loginFailed
        case unknown
    }

    // MARK: - Static Properties

    static var urlSession = URLSession.shared

    // MARK: - Static Methods

    public static func logout() {
        guard let storage = urlSession.configuration.httpCookieStorage else {
            return
        }
        storage.removeCookies(since: .distantPast)
    }

    public static func login(toAccount account: String, password: String) -> Promise<Void> {
        logout()
        let url = URL(string: "https://news.ycombinator.com/login?acct=\(account)&pw=\(password)")!
        let promise = firstly {
            urlSession.dataTask(.promise, with: url).validate()
        }.recover { error -> Promise<(data: Data, response: URLResponse)> in
            throw APIError.networkingFailed(error)
        }.map { (data, response) in
            guard let storage = urlSession.configuration.httpCookieStorage else {
                return
            }
            let cookies = storage.cookies(for: url) ?? []
            guard cookies.first(where: { $0.name == "user" }) != nil else {
                throw APIError.loginFailed
            }
        }
        return promise
    }

    public static func items(from category: ItemListCategory) -> Promise<[ListableItem]> {
        let url = URL(string: "https://news.ycombinator.com/\(category.rawValue)")!
        let promise = firstly {
            urlSession.dataTask(.promise, with: url).validate()
        }.recover { error -> Promise<(data: Data, response: URLResponse)> in
            throw APIError.networkingFailed(error)
        }.map { (data, response) -> [ListableItem] in
            let html = String(data: data, urlResponse: response)!
            let document = try perform(SwiftSoup.parse(html)) { error in
                APIError.parsingFailed(error)
            }
            let parser = ItemListParser(document: document)
            let items = try parser.items()
            return items
        }
        return promise
    }

    public static func topItems() -> Promise<[ListableItem]> {
        items(from: .top)
    }

    public static func newItems() -> Promise<[ListableItem]> {
        items(from: .new)
    }

    public static func story(withID id: Int) -> Promise<Story> {
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

    public static func topLevelItem(from listableItem: ListableItem) -> Promise<TopLevelItem> {
        let id = listableItem.id
        switch listableItem.kind {
        case .story:
            return story(withID: id).map({ .story($0) })
        case .job:
            return job(withID: id).map({ .job($0) })
        case .poll:
            fatalError("Loading polls aren't implemented yet.")
        }
    }

    public static func job(withID id: Int) -> Promise<Job> {
        let url = URL(string: "https://news.ycombinator.com/item?id=\(id)")!
        let promise = firstly {
            urlSession.dataTask(.promise, with: url).validate()
        }.recover { error -> Promise<(data: Data, response: URLResponse)> in
            throw APIError.networkingFailed(error)
        }.map { (data, response) -> Job in
            let html = String(data: data, urlResponse: response)!
            let document = try perform(SwiftSoup.parse(html)) { error in
                APIError.parsingFailed(error)
            }
            let parser = StoryParser(document: document)
            let ageDescription = try parser.ageDescription()
            let title = try parser.title()
            let (url, text) = try parser.content()
            let job = Job(id: id, ageDescription: ageDescription, title: title, url: url,
                          text: text)
            return job
        }
        return promise
    }

    public static func user(withName name: String) -> Promise<User> {
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
            let description = try perform(Entities.unescape(user.about ?? ""), orThrow: APIError.unknown)
            let karma = user.karma
            return User(creation: creation, description: description, name: name, karma: karma)
        }
        return promise
    }
}
