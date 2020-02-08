
import Foundation

public struct Comment: Item {
    public var id: Int
    public var authorName: String
    public var ageDescription: String
    public var text: String
    public var comments: [Comment]
    public var commentCount: Int {
        comments.reduce(1, { $0 + $1.commentCount })
    }
    public var actions: Set<Action>
}
