
import Foundation

struct Poll: Item {
    var id: Int
    var time: Date
    var author: User
    var score: Int
    var title: String
    var text: String
    var actions: Set<Action>
}
