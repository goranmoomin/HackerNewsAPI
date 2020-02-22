
import Foundation

public class Job {

    // MARK: - Properties

    public var id: Int
    public var ageDescription: String
    public var title: String
    // Some jobs don't have a URL or an empty string
    public var url: URL?
    // but have text.
    public var text: String?

    // MARK: - Init

    init(id: Int, ageDescription: String, title: String, url: URL?, text: String?) {
        self.id = id
        self.ageDescription = ageDescription
        self.title = title
        self.url = url
        self.text = text
    }
}
