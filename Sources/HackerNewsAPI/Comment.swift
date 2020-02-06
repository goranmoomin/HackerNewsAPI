
import Foundation

public struct Comment: Item {
    public var id: Int
    public var authorName: String
    public var ageDescription: String
    public var text: String
    public var comments: [Comment]
    public var actions: Set<Action>
}
