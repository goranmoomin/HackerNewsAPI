
import Foundation

public class Job {

    // MARK: - Properties

    public var id: Int
    public var ageDescription: String
    public var title: String
    public var content: Content

    // MARK: - Init

    init(id: Int, ageDescription: String, title: String, content: Content) {
        self.id = id
        self.ageDescription = ageDescription
        self.title = title
        self.content = content
    }

    convenience init(id: Int, ageDescription: String, title: String, url: URL) {
        self.init(id: id, ageDescription: ageDescription, title: title, content: .url(url))
    }

    convenience init(id: Int, ageDescription: String, title: String, text: String) {
        self.init(id: id, ageDescription: ageDescription, title: title, content: .text(text))
    }
}
