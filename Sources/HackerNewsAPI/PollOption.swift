
import Foundation

public struct PollOption: Item {
    public var id: Int
    public var author: User
    public var score: Int
    public var text: String
    public var actions: Set<Action>
}
