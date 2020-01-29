
import Foundation

struct PollOption: Item {
    var id: Int
    var time: Date
    var author: User
    var score: Int
    var text: String
    var actions: Set<Action>
}
