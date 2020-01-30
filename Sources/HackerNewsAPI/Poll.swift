
import Foundation

struct Poll: Item {
    var id: Int
    var author: User
    var score: Int
    var title: String
    var text: String
    var actions: Set<Action>
}
