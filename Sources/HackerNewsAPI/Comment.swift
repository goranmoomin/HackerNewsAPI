
import Foundation

struct Comment: Item {
    var id: Int
    var author: User
    var text: String
    var comments: [Comment]
    var actions: Set<Action>
}
