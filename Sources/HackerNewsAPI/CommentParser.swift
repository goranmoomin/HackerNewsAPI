
import Foundation
import SwiftSoup

class CommentParser {

    // MARK: - Error

    enum ParserError: Error {
        case unknown
    }

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
}
