
import Foundation

public struct Job {
    public var id: Int
    public var ageDescription: String
    public var title: String
    // Some jobs don't have a URL or an empty string
    public var url: URL?
    // but have text.
    public var text: String?
}
