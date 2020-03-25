
import Foundation
import PromiseKit
import PMKFoundation

public extension Promise where T == (data: Data, response: URLResponse) {
    func validateRedirection() -> Promise<T> {
        return map {
            guard let response = $0.response as? HTTPURLResponse else { return $0 }
            switch response.statusCode {
            case 300..<400:
                return $0
            case let code:
                throw PMKHTTPError.badStatusCode(code, $0.data, response)
            }
        }
    }
}
