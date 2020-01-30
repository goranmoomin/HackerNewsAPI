
import Foundation

struct PollOption: Item {
    var id: Int
    var author: User
    var score: Int
    var text: String
    var actions: Set<Action>
}
