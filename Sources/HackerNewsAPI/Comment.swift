
import Foundation

struct Comment: Item {
    var id: Int
    var authorName: String
    var ageDescription: String
    var text: String
    var comments: [Comment]
    var actions: Set<Action>
}
