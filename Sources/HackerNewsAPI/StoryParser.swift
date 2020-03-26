
import Foundation
import SwiftSoup

class StoryParser {

    // MARK: - Stored Properties

    var document: Document

    // MARK: - Init

    init(document: Document) {
        self.document = document
    }

    // MARK: - Helper Methods

    func fatItemEl() throws -> Element {
        let fatItemEl = try unwrap(try! document.select(".fatitem").first(),
                                   orThrow: ParserError.unknown)
        return fatItemEl
    }

    func rowEls() throws -> [Element] {
        let fatItemEl = try self.fatItemEl()
        let rowEls = try! fatItemEl.select("table.fatitem > tbody > tr").array()
        guard rowEls.count == 2 || rowEls.count == 4 || rowEls.count == 6 else {
            throw ParserError.unknown
        }
        return rowEls
    }

    func titleAnchorEl() throws -> Element {
        let rowEls = try self.rowEls()
        let itemEl = rowEls[0]
        let titleAnchorEl = try unwrap(try! itemEl.select(".storylink").first(),
                                       orThrow: ParserError.unknown)
        return titleAnchorEl
    }

    func subTextEl() throws -> Element {
        let fatItemEl = try self.fatItemEl()
        let subTextEl = try unwrap(try! fatItemEl.select(".subtext").first(),
                                   orThrow: ParserError.unknown)
        return subTextEl
    }

    func commentFormEl() throws -> Element? {
        let fatItemEl = try self.fatItemEl()
        let commentFormEl = try! fatItemEl.select("form[action=comment]").first()
        return commentFormEl
    }

    func hasText() throws -> Bool {
        let rowEls = try self.rowEls()
        let commentFormEl = try self.commentFormEl()
        if commentFormEl != nil {
            return rowEls.count == 6
        } else {
            return rowEls.count == 4
        }
    }

    // MARK: - Methods

    func id() throws -> Int {
        let fatItemEl = try self.fatItemEl()
        let aThingEl = try unwrap(try! fatItemEl.select(".athing").first(),
                                  orThrow: ParserError.unknown)
        let id = try unwrap(Int(aThingEl.id()), orThrow: ParserError.unknown)
        return id
    }

    func title() throws -> String {
        let titleAnchorEl = try self.titleAnchorEl()
        let title = try perform(titleAnchorEl.text(), orThrow: ParserError.unknown)
        return title
    }

    func score() throws -> Int {
        let subTextEl = try self.subTextEl()
        let scoreEl = try unwrap(try! subTextEl.select(".score").first(),
                                 orThrow: ParserError.unknown)
        let scoreText = try perform(scoreEl.text().split(separator: .space)[0],
                                    orThrow: ParserError.unknown)
        let score = try unwrap(Int(scoreText), orThrow: ParserError.unknown)
        return score
    }

    func authorName() throws -> String {
        let subTextEl = try self.subTextEl()
        let authorEl = try unwrap(try! subTextEl.select(".hnuser").first(),
                                  orThrow: ParserError.unknown)
        let authorName = try perform(authorEl.text(), orThrow: ParserError.unknown)
        return authorName
    }

    func ageDescription() throws -> String {
        let subTextEl = try self.subTextEl()
        let ageEl = try unwrap(try! subTextEl.select(".age").first(),
                               orThrow: ParserError.unknown)
        let ageDescription = try perform(ageEl.text(), orThrow: ParserError.unknown)
        return ageDescription
    }

    func actions() throws -> Set<Action> {
        let fatItemEl = try self.fatItemEl()
        let voteAnchorEls = try unwrap(try! fatItemEl.select(".votelinks a:has(.votearrow):not(.nosee)"),
                                       orThrow: ParserError.unknown)
        var actions: Set<Action> = []
        let base = URL(string: "https://news.ycombinator.com")
        for voteAnchorEl in voteAnchorEls {
            let href = try perform(voteAnchorEl.attr("href"), orThrow: ParserError.unknown)
            let url = try unwrap(URL(string: href, relativeTo: base), orThrow: ParserError.unknown)
            if url.components?.queryItems?.filter({ $0.name == "auth" }).isEmpty ?? true {
                continue
            }
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
        let subTextEl = try self.subTextEl()
        if let undoAnchorEl = try! subTextEl.select("[id^=unv] > a").first() {
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
        let hasText = try self.hasText()
        let rowEls = try self.rowEls()
        if hasText {
            let textEl = try unwrap(rowEls[3].child(1), orThrow: ParserError.unknown)
            text = try perform(textEl.text(), orThrow: ParserError.unknown)
        } else {
            let titleAnchorEl = try self.titleAnchorEl()
            let href = try perform(titleAnchorEl.attr("href"),
                                   orThrow: ParserError.unknown)
            url = URL(string: href)
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
                commentsPerLevel.last?.last?.comments = currentComments
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

    func story() throws -> Story {
        let id = try self.id()
        let authorName = try self.authorName()
        let ageDescription = try self.ageDescription()
        let score = try self.score()
        let title = try self.title()
        let actions = try self.actions()
        let (url, text) = try content()
        let comments = try commentTree()
        let isCommentable = try self.commentFormEl() != nil
        let story = Story(id: id, authorName: authorName, ageDescription: ageDescription,
                          score: score, title: title, url: url, text: text, comments: comments,
                          actions: actions, isCommentable: isCommentable)
        return story
    }
}
