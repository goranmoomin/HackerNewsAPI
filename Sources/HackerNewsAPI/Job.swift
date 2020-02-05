
import Foundation

struct Job: Item {
    var id: Int
    var ageDescription: String
    var title: String
    // Some jobs don't have a URL or an empty string
    var url: URL?
    // but have text.
    var text: String?
}
