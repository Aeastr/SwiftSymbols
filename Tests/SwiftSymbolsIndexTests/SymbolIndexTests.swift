import XCTest
@testable import SwiftSymbolsIndex

final class SymbolIndexTests: XCTestCase {
    func testCatalogIntegrity() throws {
        let index = try SymbolIndex.load()
        XCTAssertGreaterThan(index.symbols.count, 5000)
        XCTAssertEqual(Set(index.symbols.map(\.id)).count, index.symbols.count)
        XCTAssertFalse(index.sections.isEmpty)
        XCTAssertEqual(Set(index.sections.flatMap(\.symbols).map(\.id)), Set(index.symbols.map(\.id)))
        XCTAssertTrue(index.symbols.contains { $0.name == "book.closed" })
        XCTAssertTrue(index.sections.allSatisfy { !$0.symbols.isEmpty })
    }

    func testSearchMatchesKeywordsAndAllTerms() throws {
        let index = try SymbolIndex.load()
        XCTAssertTrue(index.search("search").contains { $0.name == "magnifyingglass" })
        XCTAssertTrue(index.search(" book.closed ").contains { $0.name == "book.closed" })
        XCTAssertEqual(index.search("   ").count, index.symbols.count)
        XCTAssertTrue(index.search("unfindablezzzz").isEmpty)
        XCTAssertEqual(index.search("book.closed").first?.name, "book.closed")
        XCTAssertTrue(index.search("book fill").allSatisfy { $0.name.contains("book") && $0.name.contains("fill") })
    }
}
