
import Foundation

public struct ListableItem: Item {
    // A job doesn't have an author name, score, and comments
    public var id: Int
    public var url: URL?
    public var authorName: String?
    public var ageDescription: String
    public var score: Int?
    public var title: String
    public var actions: Set<Action>
    public var commentCount: Int?
}
