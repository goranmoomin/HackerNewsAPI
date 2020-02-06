
import Foundation

public struct ListableItem: Item {
    public var id: Int
    // Jobs don't have author names
    public var authorName: String?
    public var ageDescription: String
    public var score: Int?
    public var title: String
    public var actions: Set<Action>
}
