
import Foundation

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
