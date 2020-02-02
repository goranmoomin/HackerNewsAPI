
import Foundation

struct Story: Item {
    var id: Int
    var authorName: String
    var ageDescription: String
    var score: Int
    var title: String
    // Some stories don't have a URL or an empty string
    var url: URL?
    // but have text.
    var text: String?
    var comments: [Comment]
    var actions: Set<Action>
}
