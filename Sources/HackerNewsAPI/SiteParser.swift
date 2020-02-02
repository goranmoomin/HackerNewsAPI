
import Foundation
import SwiftSoup

class SiteParser {

    // MARK: - Error

    enum ParserError: Error {
        case unknown
    }

    // MARK: - Stored Properties

    var document: Document

    // MARK: - Computed Properties

    var fatItemEl: Element? {
        try! document.select(".fatitem").first()
    }
    var rowEls: [Element]? {
        let rowEls = try! fatItemEl?.select("table.fatitem > tbody > tr").array()
        guard rowEls?.count == 2 || rowEls?.count == 4 || rowEls?.count == 6 else {
            return nil
        }
        return rowEls
    }
    var itemEl: Element? {
        rowEls?[0]
    }
    var titleAnchorEl: Element? {
        try! itemEl?.select(".storylink").first()
    }
    var subTextEl: Element? {
        rowEls?[1]
    }
    var isCommentable: Bool? {
        try! fatItemEl?.select("form[action=comment]").first() != nil
    }
    var hasText: Bool? {
        guard let isCommentable = isCommentable else {
            return nil
        }
        if isCommentable {
            return rowEls?.count == 6
        } else {
            return rowEls?.count == 4
        }
    }

    // MARK: - Init

    init(document: Document) {
        self.document = document
    }

    // MARK: - Methods

    func title() throws -> String {
        let titleAnchor = try unwrap(try! itemEl?.select(".storylink").first(),
                                     orThrow: ParserError.unknown)
        let title = try perform(titleAnchor.text(), orThrow: ParserError.unknown)
        return title
    }

    func score() throws -> Int {
        let scoreEl = try unwrap(try! subTextEl?.select(".score"),
                                 orThrow: ParserError.unknown)
        let scoreText = try perform(scoreEl.text().split(separator: .space)[0],
                                    orThrow: ParserError.unknown)
        let score = try unwrap(Int(scoreText), orThrow: ParserError.unknown)
        return score
    }

    func authorName() throws -> String {
        let authorEl = try unwrap(try! subTextEl?.select(".hnuser"),
                                  orThrow: ParserError.unknown)
        let authorName = try perform(authorEl.text(), orThrow: ParserError.unknown)
        return authorName
    }

    func ageDescription() throws -> String {
        let ageEl = try unwrap(try! subTextEl?.select(".age").first(),
                               orThrow: ParserError.unknown)
        let ageDescription = try perform(ageEl.text(), orThrow: ParserError.unknown)
        return ageDescription
    }

    // FIXME: Use proper modeling with enums
    func content() throws -> (URL?, String?) {
        var url: URL?
        var text: String?
        guard let hasText = hasText else {
            throw ParserError.unknown
        }
        if hasText {
            let textEl = try unwrap(rowEls?[3].child(1), orThrow: ParserError.unknown)
            text = try perform(textEl.text(), orThrow: ParserError.unknown)
        } else {
            guard let titleAnchorEl = titleAnchorEl else {
                throw ParserError.unknown
            }
            let urlString = try perform(titleAnchorEl.attr("href"),
                                        orThrow: ParserError.unknown)
            url = URL(string: urlString)
        }
        return (url, text)
    }

    func commentTree() throws -> [Comment] {
        let commentEls = try! document.select(".comtr").array()
        var commentsPerLevel: [[Comment]] = [[]]
        for commentEl in commentEls {
            let currentLevel = commentsPerLevel.count - 1
            let indentEl = try unwrap(try! commentEl.select(".ind > img").first(),
                                      orThrow: ParserError.unknown)
            let indentWidth = try perform(indentEl.attr("width"),
                                          orThrow: ParserError.unknown)
            let level = try unwrap(Int(indentWidth), orThrow: ParserError.unknown) / 40
            guard level <= currentLevel + 1 else {
                throw ParserError.unknown
            }
            let id = try unwrap(Int(commentEl.id()), orThrow: ParserError.unknown)
            let authorEl = try unwrap(try! commentEl.select(".hnuser").first(),
                                      orThrow: ParserError.unknown)
            let authorName = try perform(authorEl.text(), orThrow: ParserError.unknown)
            let text = try perform(commentEl.select(".commtext").html(),
                                   orThrow: ParserError.unknown)
            let ageEl = try unwrap(try! commentEl.select(".age").first(),
                                   orThrow: ParserError.unknown)
            let ageDescription = try perform(ageEl.text(), orThrow: ParserError.unknown)
            let comment = Comment(id: id, authorName: authorName, ageDescription: ageDescription,
                                  text: text, comments: [], actions: [])
            if level <= currentLevel {
                while commentsPerLevel.count > level + 1 {
                    let currentComments = try unwrap(commentsPerLevel.popLast(),
                                                     orThrow: ParserError.unknown)
                    let currentLevel = commentsPerLevel.count - 1
                    let preCommentsCount = commentsPerLevel[currentLevel].count
                    commentsPerLevel[currentLevel][preCommentsCount - 1].comments
                        = currentComments
                }
                let currentLevel = commentsPerLevel.count - 1
                commentsPerLevel[currentLevel].append(comment)
            } else {
                // level = currentLevel + 1
                commentsPerLevel.append([comment])
            }
        }
        while commentsPerLevel.count > 1 {
            let currentComments = try unwrap(commentsPerLevel.popLast(),
                                             orThrow: ParserError.unknown)
            let currentLevel = commentsPerLevel.count - 1
            let preCommentsCount = commentsPerLevel[currentLevel].count
            commentsPerLevel[currentLevel][preCommentsCount - 1].comments
                = currentComments
        }
        guard commentsPerLevel.count == 1 else {
            throw ParserError.unknown
        }
        let comments = commentsPerLevel[0]
        return comments
    }
}
