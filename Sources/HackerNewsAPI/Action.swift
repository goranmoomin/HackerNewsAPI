
import Foundation

struct Action: Hashable {

    // MARK: - Action Types

    enum Kind: Hashable {
        case upvote
        case downvote
        case unvote
        case undown
    }

    // MARK: - Properties

    var kind: Kind
    var url: URL

    // MARK: - Comparing

    func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.kind == rhs.kind
    }

    // MARK: - Helper functions

    static func upvote(_ url: URL) -> Action {
        Action(kind: .upvote, url: url)
    }

    static func downvote(_ url: URL) -> Action {
        Action(kind: .downvote, url: url)
    }

    static func unvote(_ url: URL) -> Action {
        Action(kind: .unvote, url: url)
    }

    static func undown(_ url: URL) -> Action {
        Action(kind: .undown, url: url)
    }
}
