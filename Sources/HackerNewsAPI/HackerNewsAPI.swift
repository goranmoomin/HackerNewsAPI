
import Foundation
import PromiseKit
import PMKFoundation

struct HackerNewsAPI {

    static func example() -> Promise<String> {
        let url = URL(string: "https://httpbin.org/base64/SFRUUEJJTiBpcyBhd2Vzb21l")!
        let request = URLRequest(url: url)
        let promise = firstly {
            URLSession.shared.dataTask(.promise, with: request)
        }.map { (data, response) in
            String(data: data, urlResponse: response)!
        }
        return promise
    }
}
