
import Foundation

public class ListableItem {

    // MARK: - Helper Type

    public enum Kind: Equatable, Hashable {
        case story
        case job
        case poll
    }

    // MARK: - Properties

    public var kind: Kind
    // A job doesn't have an author name, score, and comments
    public var id: Int
    public var url: URL?
    public var authorName: String?
    public var ageDescription: String
    public var score: Int?
    public var title: String
    public var actions: Set<Action>
    public var commentCount: Int?

    // MARK: - Init

    init(kind: Kind, id: Int, url: URL?, authorName: String?, ageDescription: String, score: Int?,
         title: String, actions: Set<Action>, commentCount: Int?) {
        self.kind = kind
        self.id = id
        self.url = url
        self.authorName = authorName
        self.ageDescription = ageDescription
        self.score = score
        self.title = title
        self.actions = actions
        self.commentCount = commentCount
    }
}
