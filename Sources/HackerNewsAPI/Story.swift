
import Foundation

public struct Story: Item {
    public var id: Int
    public var authorName: String
    public var ageDescription: String
    public var score: Int
    public var title: String
    // Some stories don't have a URL or an empty string
    public var url: URL?
    // but have text.
    public var text: String?
    public var comments: [Comment]
    public var commentCount: Int {
        comments.reduce(0, { $0 + $1.commentCount })
    }
    public var actions: Set<Action>
}
