
import Foundation
import SwiftSoup

class ItemListParser {

    // MARK: - Stored Properties

    var document: Document

    // MARK: - Init

    init(document: Document) {
        self.document = document
    }

    // MARK: - Methods

    func item(aThingEl: Element, subTextEl: Element) throws -> ListableItem {
        let id = try unwrap(Int(aThingEl.id()), orThrow: ParserError.unknown)
        var authorName: String?
        if let authorEl = try! subTextEl.select(".hnuser").first() {
            authorName = try perform(authorEl.text(), orThrow: ParserError.unknown)
        }
        let ageEl = try unwrap(try! subTextEl.select(".age").first(), orThrow: ParserError.unknown)
        let ageDescription = try perform(ageEl.text(), orThrow: ParserError.unknown)
        var score: Int?
        if let scoreEl = try! subTextEl.select(".score").first() {
            let scoreText = try perform(scoreEl.text().split(separator: .space)[0],
                                        orThrow: ParserError.unknown)
            score = try unwrap(Int(scoreText), orThrow: ParserError.unknown)
        }
        let titleAnchorEl = try unwrap(try! aThingEl.select(".storylink").first(),
                                       orThrow: ParserError.unknown)
        let title = try perform(titleAnchorEl.text(), orThrow: ParserError.unknown)
        let item = ListableItem(id: id, authorName: authorName, ageDescription: ageDescription,
                                score: score, title: title, actions: [])
        return item
    }

    func items() throws -> [ListableItem] {
        let aThingEls = try! document.select(".athing")
        let subTextEls = try! document.select(".athing + tr")
        let items = try zip(aThingEls, subTextEls).map({ try item(aThingEl: $0, subTextEl: $1) })
        return items
    }
}
