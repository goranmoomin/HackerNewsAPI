
import Foundation

struct ListableItem: Item {
    var id: Int
    // Jobs don't have author names
    var authorName: String?
    var ageDescription: String
    var score: Int?
    var title: String
    var actions: Set<Action>
}
