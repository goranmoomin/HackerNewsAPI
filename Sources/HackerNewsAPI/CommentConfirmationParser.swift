
import Foundation
import SwiftSoup

class CommentConfirmationParser {

    // MARK: - Stored Properties

    var document: Document

    // MARK: - Init

    init(document: Document) {
        self.document = document
    }

    // MARK: - Methods

    func hmac() -> String? {
        guard let hmacEl = try! document.select("input[name=hmac]").first() else {
            return nil
        }
        let hmac = try? hmacEl.val()
        return hmac
    }
}
