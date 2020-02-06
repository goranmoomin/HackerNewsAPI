
import Foundation

public struct Poll: Item {
    public var id: Int
    public var author: User
    public var score: Int
    public var title: String
    public var text: String
    public var actions: Set<Action>
}
