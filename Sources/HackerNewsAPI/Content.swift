
import Foundation

public enum Content: Equatable {
    case url(URL)
    case text(String)

    var text: String? {
        switch self {
        case let .text(text): return text
        case .url: return nil
        }
    }

    var url: URL? {
        switch self {
        case .text: return nil
        case let .url(url): return url
        }
    }
}
