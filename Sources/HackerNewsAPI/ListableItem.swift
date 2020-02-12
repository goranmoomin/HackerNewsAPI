
import Foundation

public struct ListableItem {
    public enum Kind {
        case story
        case job
        case poll
    }
    public var kind: Kind
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
