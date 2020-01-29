
import Foundation

struct Comment: Item {
    var id: Int
    var time: Date
    var author: User
    var text: String
    var comments: [Comment]
    var actions: Set<Action>
}
