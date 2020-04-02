
import Foundation

public class Story {

    // MARK: - Properties

    public var id: Int
    public var authorName: String
    public var ageDescription: String
    public var score: Int
    public var title: String
    public var content: Content
    public var comments: [Comment]
    public var commentCount: Int {
        comments.reduce(0, { $0 + $1.commentCount })
    }
    public var actions: Set<Action>
    public var isCommentable: Bool

    // MARK: - Init

    init(id: Int, authorName: String, ageDescription: String, score: Int, title: String,
         content: Content, comments: [Comment], actions: Set<Action>, isCommentable: Bool) {
        self.id = id
        self.authorName = authorName
        self.ageDescription = ageDescription
        self.score = score
        self.title = title
        self.content = content
        self.comments = comments
        self.actions = actions
        self.isCommentable = isCommentable
    }
}
