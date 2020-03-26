
import Foundation

extension URL {
    var isAbsolute: Bool {
        host != nil
    }
}

extension URL {
    var components: URLComponents? {
        URLComponents(url: self, resolvingAgainstBaseURL: true)
    }
}
