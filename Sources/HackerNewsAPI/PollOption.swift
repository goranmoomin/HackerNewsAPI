
import Foundation

public struct PollOption: Equatable, Hashable {
    public var id: Int
    public var author: User
    public var score: Int
    public var text: String
    public var actions: Set<Action>
}
