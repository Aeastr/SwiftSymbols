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

final class SymbolSearchRelevanceTests: XCTestCase {
    func testRelevanceTiersAndExactPinning() {
        let keyword = Symbol(name: "atom", keywords: ["bookish", "chemistry"])
        let alias = Symbol(name: "text", aliases: ["book.reader"])
        let name = Symbol(name: "books.vertical")
        let exact = Symbol(name: "book")
        let index = SymbolIndex(symbols: [keyword, alias, name, exact], categories: [])
        XCTAssertEqual(index.search("book").map(\.name), ["book", "books.vertical", "text", "atom"])
        XCTAssertEqual(index.search("book", ranking: .usage, usageScores: ["atom": 10]).first?.name, "book")
        XCTAssertEqual(index.search("book", ranking: .alphabetical).first?.name, "book")
        XCTAssertEqual(index.symbol(for: "BOOK.READER")?.name, "text")
        XCTAssertTrue(index.search("ookish").isEmpty, "Keywords match word prefixes, as in SwiftEmoji")
        XCTAssertEqual(index.search("chem").map(\.name), ["atom"])
    }

    func testNormalizationAndDeduplication() {
        let symbol = Symbol(name: "book.closed", keywords: ["español", "Spanish literature"])
        let index = SymbolIndex(symbols: [symbol, symbol], categories: [])
        XCTAssertEqual(index.symbols.count, 1)
        XCTAssertEqual(index.search(" ESPANOL ").map(\.name), [symbol.name])
        XCTAssertEqual(index.search("span lit").map(\.name), [symbol.name])
        XCTAssertEqual(index.search("book.closed").map(\.name), [symbol.name])
    }

    func testAppSuppliedJSONAndDecodingErrors() async throws {
        let json = #"{"categories":[{"key":"custom","label":"Custom","icon":"book"}],"symbols":[{"name":"book.closed","categories":["custom"],"keywords":["host vocabulary"]}]}"#
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("json")
        try Data(json.utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let provider = SymbolIndexProvider(source: JSONSymbolDataSource(url: url))
        let results = try await provider.search("host")
        XCTAssertEqual(results.map(\.name), ["book.closed"])
        let sections = try await provider.sections
        XCTAssertEqual(sections.map(\.category.id), ["custom"])
        XCTAssertThrowsError(try SymbolIndex(data: Data("{}".utf8)))
    }

}

private actor CountingSymbolSource: SymbolDataSource {
    private(set) var calls = 0
    let failFirst: Bool
    init(failFirst: Bool = false) { self.failFirst = failFirst }
    func fetch() async throws -> SymbolIndex {
        calls += 1
        if failFirst && calls == 1 { throw CocoaError(.fileReadCorruptFile) }
        await Task.yield()
        return SymbolIndex(symbols: [Symbol(name: "book.closed")], categories: [])
    }
}

@MainActor
final class SymbolProviderTests: XCTestCase {
    func testConcurrentLoadCachingAndRefresh() async throws {
        let source = CountingSymbolSource()
        let provider = SymbolIndexProvider(source: source)
        try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<12 { group.addTask { try await provider.allSymbols.count } }
            for try await count in group { XCTAssertEqual(count, 1) }
        }
        let calls = await source.calls
        XCTAssertEqual(calls, 1)
        try await provider.refresh()
        let refreshed = await source.calls
        XCTAssertEqual(refreshed, 2)
    }

    func testFailedLoadCanRetry() async throws {
        let source = CountingSymbolSource(failFirst: true)
        let provider = SymbolIndexProvider(source: source)
        do {
            _ = try await provider.allSymbols
            XCTFail("Expected source error")
        } catch {}
        let symbols = try await provider.allSymbols
        XCTAssertEqual(symbols.map(\.name), ["book.closed"])
        let calls = await source.calls
        XCTAssertEqual(calls, 2)
    }

    func testUsagePersistsDecaysAndFiltersFavoritesToCatalog() async throws {
        let suite = "SwiftSymbolsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let tracker = SymbolUsageTracker(defaults: defaults)
        tracker.recordUse("atom")
        tracker.recordUse("book.closed")
        tracker.recordUse("unsupported.favorite")
        XCTAssertEqual(tracker.score(for: "atom"), 0.81, accuracy: 0.001)
        let restored = SymbolUsageTracker(defaults: defaults)
        XCTAssertEqual(restored.allScores, tracker.allScores)
        let index = SymbolIndex(symbols: [Symbol(name: "atom"), Symbol(name: "book.closed")], categories: [])
        let provider = SymbolIndexProvider(source: StaticSymbolDataSource(index: index), usageTracker: tracker)
        let favorites = try await provider.favorites()
        XCTAssertEqual(favorites.map(\.name), ["book.closed", "atom"])
        let ranked = try await provider.search("", ranking: .usage)
        XCTAssertEqual(ranked.map(\.name), ["book.closed", "atom"])
        tracker.isEnabled = false
        tracker.recordUse("atom")
        XCTAssertTrue(tracker.favorites.isEmpty)
        tracker.isEnabled = true
        tracker.clearAll()
        XCTAssertTrue(tracker.allScores.isEmpty)
    }
}

private actor RefreshFailureSource: SymbolDataSource {
    private var calls = 0
    func fetch() async throws -> SymbolIndex {
        calls += 1
        if calls > 1 { throw CocoaError(.fileReadCorruptFile) }
        return SymbolIndex(symbols: [Symbol(name: "atom")], categories: [])
    }
}

extension SymbolProviderTests {
    func testFailedRefreshPreservesLoadedIndex() async throws {
        let provider = SymbolIndexProvider(source: RefreshFailureSource())
        _ = try await provider.allSymbols
        do {
            try await provider.refresh()
            XCTFail("Expected refresh error")
        } catch {}
        let symbols = try await provider.allSymbols
        XCTAssertEqual(symbols.map(\.name), ["atom"])
    }
}
