
import Foundation
import PromiseKit
import PMKFoundation

public struct Action: Equatable, Hashable {

    // MARK: - Action Types

    public enum Kind: Equatable, Hashable {
        case upvote
        case downvote
        case unvote
        case undown
    }

    // MARK: - Properties

    public var kind: Kind
    public var url: URL

    // MARK: - Methods

    public func inverse() -> Action {
        let howValue: String
        switch kind {
        case .upvote, .downvote:
            howValue = "un"
        case .unvote:
            howValue = "up"
        case .undown:
            howValue = "down"
        }
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems?.removeAll(where: { $0.name == "how" })
        urlComponents.queryItems?.append(URLQueryItem(name: "how", value: howValue))
        let url = urlComponents.url!
        switch kind {
        case .upvote:
            return .unvote(url)
        case .downvote:
            return .undown(url)
        case .unvote:
            return .upvote(url)
        case .undown:
            return .downvote(url)
        }
    }

    // MARK: - Comparing

    public func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.kind == rhs.kind
    }

    // MARK: - Helper functions

    public static func upvote(_ url: URL) -> Action {
        Action(kind: .upvote, url: url)
    }

    public static func downvote(_ url: URL) -> Action {
        Action(kind: .downvote, url: url)
    }

    public static func unvote(_ url: URL) -> Action {
        Action(kind: .unvote, url: url)
    }

    public static func undown(_ url: URL) -> Action {
        Action(kind: .undown, url: url)
    }
}

// MARK: - Comments

extension Comment {

    static var urlSession = HackerNewsAPI.urlSession
    typealias APIError = HackerNewsAPI.APIError

    public func execute(_ action: Action, token: Token) -> Promise<Void> {
        let url = action.url
        var request = URLRequest(url: url)
        request.add(token)
        let promise = firstly {
            Self.urlSession.dataTask(.promise, with: request).validate()
        }.recover { error -> Promise<(data: Data, response: URLResponse)> in
            throw APIError.networkingFailed(error)
        }.map { _ in
            self.actions.remove(action)
            self.actions.insert(action.inverse())
        }
        return promise
    }
}

// MARK: - Stories

extension Story {

    static var urlSession = HackerNewsAPI.urlSession
    typealias APIError = HackerNewsAPI.APIError

    public func execute(_ action: Action, token: Token) -> Promise<Void> {
        let url = action.url
        var request = URLRequest(url: url)
        request.add(token)
        let promise = firstly {
            Self.urlSession.dataTask(.promise, with: request).validate()
        }.recover { error -> Promise<(data: Data, response: URLResponse)> in
            throw APIError.networkingFailed(error)
        }.map { _ in
            self.actions.remove(action)
            self.actions.insert(action.inverse())
        }
        return promise
    }
}
