
import Foundation

public class Comment {

    // MARK: - Properties

    public var id: Int
    public var authorName: String
    public var ageDescription: String
    public var text: String
    public var comments: [Comment]
    public var commentCount: Int {
        comments.reduce(1, { $0 + $1.commentCount })
    }
    public var actions: Set<Action>

    // MARK: - Init

    init(id: Int, authorName: String, ageDescription: String, text: String, comments: [Comment],
         actions: Set<Action>) {
        self.id = id
        self.authorName = authorName
        self.ageDescription = ageDescription
        self.text = text
        self.comments = comments
        self.actions = actions
    }
}
