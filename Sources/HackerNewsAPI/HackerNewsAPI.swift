
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
        case notCommentable
        case unknown
    }

    // MARK: - Static Properties

    static var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        return URLSession(configuration: configuration)
    }()

    static var urlSessionWithoutRedirection: URLSession = {
        class Delegate: NSObject, URLSessionTaskDelegate {
            public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
                completionHandler(nil)
            }
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        let delegate = Delegate()
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }()

    // MARK: - Static Methods

    public static func login(toAccount account: String, password: String) -> Promise<Token> {
        let url = URL(string: "https://news.ycombinator.com/login?acct=\(account)&pw=\(password)")!
        let promise = firstly {
            urlSessionWithoutRedirection.dataTask(.promise, with: url)
        }.recover { error -> Promise<(data: Data, response: URLResponse)> in
            throw APIError.networkingFailed(error)
        }.map { (data, response) -> Token in
            let response = response as! HTTPURLResponse
            guard let headerFields = response.allHeaderFields as? [String: String] else {
                throw APIError.unknown
            }
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            guard let userCookie = cookies.first(where: { $0.name == "user" }) else {
                throw APIError.loginFailed
            }
            return Token(cookie: userCookie)
        }
        return promise
    }

    public static func items(from category: ItemListCategory, token: Token? = nil) -> Promise<[ListableItem]> {
        let url = URL(string: "https://news.ycombinator.com/\(category.rawValue)")!
        var request = URLRequest(url: url)
        if let token = token {
            request.add(token)
        }
        let promise = firstly {
            urlSession.dataTask(.promise, with: request).validate()
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

    public static func topItems(token: Token? = nil) -> Promise<[ListableItem]> {
        items(from: .top, token: token)
    }

    public static func newItems(token: Token? = nil) -> Promise<[ListableItem]> {
        items(from: .new, token: token)
    }

    public static func story(withID id: Int, token: Token? = nil) -> Promise<Story> {
        let url = URL(string: "https://news.ycombinator.com/item?id=\(id)")!
        var request = URLRequest(url: url)
        if let token = token {
            request.add(token)
        }
        let promise = firstly {
            urlSession.dataTask(.promise, with: request).validate()
        }.recover { error -> Promise<(data: Data, response: URLResponse)> in
            throw APIError.networkingFailed(error)
        }.map { (data, response) -> Story in
            let html = String(data: data, urlResponse: response)!
            let document = try perform(SwiftSoup.parse(html)) { error in
                APIError.parsingFailed(error)
            }
            let parser = StoryParser(document: document)
            let story = try parser.story()
            return story
        }
        return promise
    }

    public static func topLevelItem(from listableItem: ListableItem, token: Token? = nil) -> Promise<TopLevelItem> {
        let id = listableItem.id
        switch listableItem.kind {
        case .story:
            return story(withID: id, token: token).map({ .story($0) })
        case .job:
            return job(withID: id).map({ .job($0) })
        case .poll:
            fatalError("Loading polls aren't implemented yet.")
        }
    }

    public static func job(withID id: Int, token: Token? = nil) -> Promise<Job> {
        let url = URL(string: "https://news.ycombinator.com/item?id=\(id)")!
        var request = URLRequest(url: url)
        if let token = token {
            request.add(token)
        }
        let promise = firstly {
            urlSession.dataTask(.promise, with: request).validate()
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

    static func comment(onItemWithID id: Int, as text: String, token: Token) -> Promise<Void> {
        let url = URL(string: "https://news.ycombinator.com/comment?parent=\(id)")!
        var request = URLRequest(url: url)
        request.add(token)
        let promise = firstly {
            urlSession.dataTask(.promise, with: request).validate()
        }.recover { error -> Promise<(data: Data, response: URLResponse)> in
            throw APIError.networkingFailed(error)
        }.then { (data, response) -> Promise<(data: Data, response: URLResponse)> in
            let html = String(data: data, urlResponse: response)!
            let document = try SwiftSoup.parse(html)
            let parser = CommentConfirmationParser(document: document)
            guard let hmac = parser.hmac() else {
                throw APIError.notCommentable
            }
            var urlComponents = URLComponents(string: "https://news.ycombinator.com/comment")!
            urlComponents.queryItems = [
                URLQueryItem(name: "parent", value: String(id)),
                URLQueryItem(name: "hmac", value: hmac),
                URLQueryItem(name: "text", value: text)
            ]
            let url = urlComponents.url!
            var request = URLRequest(url: url)
            request.add(token)
            // TODO: Check the site format and throw appropriate errors for rate limits, etc...
            let promise = urlSessionWithoutRedirection.dataTask(.promise, with: request).validateRedirection()
            return promise
        }.asVoid()
        return promise
    }

    public static func comment(on story: Story, as text: String, token: Token) -> Promise<Void> {
        guard story.isCommentable else {
            return Promise(error: APIError.notCommentable)
        }
        let id = story.id
        return comment(onItemWithID: id, as: text, token: token)
    }

    public static func comment(on comment: Comment, as text: String, token: Token) -> Promise<Void> {
        let id = comment.id
        return HackerNewsAPI.comment(onItemWithID: id, as: text, token: token)
    }
}
