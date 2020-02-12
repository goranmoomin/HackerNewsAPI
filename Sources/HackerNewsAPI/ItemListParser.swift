
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
        var kind: ListableItem.Kind = .story
        if let authorEl = try! subTextEl.select(".hnuser").first() {
            authorName = try perform(authorEl.text(), orThrow: ParserError.unknown)
        } else {
            kind = .job
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
        let href = try perform(titleAnchorEl.attr("href"), orThrow: ParserError.unknown)
        var url: URL? = URL(string: href)
        if !(url?.isAbsolute ?? false) {
            url = nil
        }
        let title = try perform(titleAnchorEl.text(), orThrow: ParserError.unknown)
        var commentCount: Int?
        let commentCountElSelector = "a:matches((?:comments?|discuss)$)"
        if let commentCountEl = try! subTextEl.select(commentCountElSelector).first() {
            let commentCountText = try perform(commentCountEl.text(), orThrow: ParserError.unknown)
            if commentCountText == "discuss" {
                commentCount = 0
            } else {
                let commentCountNumText = commentCountText.split(separator: .nonBreakingSpace)[0]
                commentCount = try unwrap(Int(commentCountNumText), orThrow: ParserError.unknown)
            }
        }
        let item = ListableItem(kind: kind, id: id, url: url, authorName: authorName,
                                ageDescription: ageDescription, score: score, title: title,
                                actions: [], commentCount: commentCount)
        return item
    }

    func items() throws -> [ListableItem] {
        let aThingEls = try! document.select(".athing")
        let subTextEls = try! document.select(".athing + tr")
        let items = try zip(aThingEls, subTextEls).map({ try item(aThingEl: $0, subTextEl: $1) })
        return items
    }
}
