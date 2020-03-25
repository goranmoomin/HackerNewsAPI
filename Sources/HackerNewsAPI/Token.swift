
import Foundation
import PMKFoundation

public struct Token {
    var cookie: HTTPCookie
}

extension URLRequest {
    mutating func add(_ token: Token) {
        for (field, value) in HTTPCookie.requestHeaderFields(with: [token.cookie]) {
            addValue(value, forHTTPHeaderField: field)
        }
    }
}
