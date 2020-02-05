
import Foundation
import SwiftSoup

class CommentParser {

    // MARK: - Stored Properties

    var commentEl: Element

    // MARK: - Init

    init(commentEl: Element) {
        self.commentEl = commentEl
    }

    // MARK: - Methods

    func id() throws -> Int {
        try unwrap(Int(commentEl.id()), orThrow: ParserError.unknown)
    }

    func indentation() throws -> Int {
        let indentEl = try unwrap(try! commentEl.select(".ind > img").first(),
                                  orThrow: ParserError.unknown)
        let indentWidth = try perform(indentEl.attr("width"),
                                      orThrow: ParserError.unknown)
        let indentation = try unwrap(Int(indentWidth), orThrow: ParserError.unknown) / 40
        return indentation
    }

    func authorName() throws -> String {
        let authorEl = try unwrap(try! commentEl.select(".hnuser").first(),
                                  orThrow: ParserError.unknown)
        let authorName = try perform(authorEl.text(), orThrow: ParserError.unknown)
        return authorName
    }

    func text() throws -> String {
        try perform(commentEl.select(".commtext").html(), orThrow: ParserError.unknown)
    }

    func ageDescription() throws -> String {
        let ageEl = try unwrap(try! commentEl.select(".age").first(),
                               orThrow: ParserError.unknown)
        let ageDescription = try perform(ageEl.text(), orThrow: ParserError.unknown)
        return ageDescription
    }

    func actions() throws -> Set<Action> {
        let voteAnchorEls = try! commentEl.select(".votelinks a:has(.votearrow)")
        var actions: Set<Action> = []
        let base = URL(string: "https://news.ycombinator.com")
        for voteAnchorEl in voteAnchorEls {
            let href = try perform(voteAnchorEl.attr("href"), orThrow: ParserError.unknown)
            let url = try unwrap(URL(string: href, relativeTo: base), orThrow: ParserError.unknown)
            let voteArrowEl = try unwrap(try! voteAnchorEl.select(".votearrow").first(),
            orThrow: ParserError.unknown)
            let title = try perform(voteArrowEl.attr("title"), orThrow: ParserError.unknown)
            switch title {
            case "upvote":
                actions.insert(.upvote(url))
            case "downvote":
                actions.insert(.downvote(url))
            default:
                throw ParserError.unknown
            }
        }
        if let undoAnchorEl = try! commentEl.select(".comhead [id^=unv] > a").first() {
            let href = try perform(undoAnchorEl.attr("href"), orThrow: ParserError.unknown)
            let url = try unwrap(URL(string: href, relativeTo: base), orThrow: ParserError.unknown)
            let text = try perform(undoAnchorEl.text(), orThrow: ParserError.unknown)
            switch text {
            case "unvote":
                actions.insert(.unvote(url))
            case "undown":
                actions.insert(.undown(url))
            default:
                throw ParserError.unknown
            }
        }
        return actions
    }
}
