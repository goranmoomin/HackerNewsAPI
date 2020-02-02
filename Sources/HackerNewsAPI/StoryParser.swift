
import Foundation
import SwiftSoup

class StoryParser {

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
        guard let titleAnchorEl = titleAnchorEl else {
            throw ParserError.unknown
        }
        let title = try perform(titleAnchorEl.text(), orThrow: ParserError.unknown)
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

    func actions() throws -> Set<Action> {
        let voteAnchorEls = try unwrap(try! fatItemEl?.select(".votelinks a:has(.votearrow)"),
                                       orThrow: ParserError.unknown)
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
        if let undoAnchorEl = try! subTextEl?.select("[id^=unv] > a").first() {
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
        func attachComments(untilLevel level: Int) throws {
            while commentsPerLevel.count - 1 > level {
                let currentComments = try unwrap(commentsPerLevel.popLast(),
                                                 orThrow: ParserError.unknown)
                let currentLevel = commentsPerLevel.count - 1
                let commentsCount = commentsPerLevel[currentLevel].count
                commentsPerLevel[currentLevel][commentsCount - 1].comments = currentComments
            }
        }
        for commentEl in commentEls {
            let parser = CommentParser(commentEl: commentEl)
            let currentLevel = commentsPerLevel.count - 1
            let level = try parser.indentation()
            guard level <= currentLevel + 1 else {
                throw ParserError.unknown
            }
            let id = try parser.id()
            let authorName = try parser.authorName()
            let text = try parser.text()
            let ageDescription = try parser.ageDescription()
            let actions = try parser.actions()
            let comment = Comment(id: id, authorName: authorName, ageDescription: ageDescription,
                                  text: text, comments: [], actions: actions)
            if level <= currentLevel {
                try attachComments(untilLevel: level)
                let currentLevel = commentsPerLevel.count - 1
                commentsPerLevel[currentLevel].append(comment)
            } else {
                // level = currentLevel + 1
                commentsPerLevel.append([comment])
            }
        }
        try attachComments(untilLevel: 0)
        guard commentsPerLevel.count == 1 else {
            throw ParserError.unknown
        }
        let comments = commentsPerLevel[0]
        return comments
    }
}
