// Adapted from SwiftEmoji's index/source/provider architecture.
// Copyright (c) 2026 Aether; MIT License.
import Foundation

/// A source can supply a bundled profile or an app-owned/custom prepared index.
public protocol SymbolDataSource: Sendable {
    func fetch() async throws -> SymbolIndex
}

public struct BundledSymbolDataSource: SymbolDataSource {
    public init() {}
    public func fetch() async throws -> SymbolIndex { try SymbolIndex.load() }
}

/// Loads an app-owned catalog JSON file using the public catalog schema.
/// The provider performs this work off the UI actor and caches the prepared index.
public struct JSONSymbolDataSource: SymbolDataSource {
    public let url: URL
    public init(url: URL) { self.url = url }
    public func fetch() async throws -> SymbolIndex {
        try SymbolIndex(data: Data(contentsOf: url))
    }
}

public struct StaticSymbolDataSource: SymbolDataSource {
    public let index: SymbolIndex
    public init(index: SymbolIndex) { self.index = index }
    public func fetch() async throws -> SymbolIndex { index }
}

/// Async lookup/search contract corresponding to SwiftEmoji's index protocol.
public protocol SymbolIndexProtocol: Sendable {
    var allSymbols: [Symbol] { get async throws }
    var sections: [SymbolSection] { get async throws }
    func symbol(for name: String) async throws -> Symbol?
    func search(_ query: String, ranking: SearchRanking) async throws -> [Symbol]
    func favorites() async throws -> [Symbol]
    func refresh() async throws
}

/// Loads once, caches the prepared index and coalesces simultaneous load requests.
/// Actor isolation replaces SwiftEmoji's shared mutable provider/lock state.
public actor SymbolIndexProvider: SymbolIndexProtocol {
    public static let shared = SymbolIndexProvider()
    private let source: any SymbolDataSource
    private let usageTracker: SymbolUsageTracker?
    private var cached: SymbolIndex?
    private var pending: (id: UUID, task: Task<SymbolIndex, Error>)?
    public private(set) var lastUpdated: Date?
    public var isLoaded: Bool { cached != nil }

    public init(source: any SymbolDataSource = BundledSymbolDataSource(),
                usageTracker: SymbolUsageTracker? = nil) {
        self.source = source
        self.usageTracker = usageTracker
    }

    public var index: SymbolIndex { get async throws { try await load() } }
    public var allSymbols: [Symbol] { get async throws { try await load().symbols } }
    public var sections: [SymbolSection] { get async throws { try await load().sections } }

    public func symbol(for name: String) async throws -> Symbol? {
        try await load().symbol(for: name)
    }
    public func search(_ query: String, ranking: SearchRanking = .relevance) async throws -> [Symbol] {
        let index = try await load()
        let scores: [String: Double]
        if case .usage = ranking {
            scores = await tracker().allScores
        } else {
            scores = [:]
        }
        return index.search(query, ranking: ranking, usageScores: scores)
    }
    public func favorites() async throws -> [Symbol] {
        let index = try await load()
        let names = await tracker().favorites
        var seen = Set<String>()
        return names.compactMap { index.symbol(for: $0) }.filter { seen.insert($0.name).inserted }
    }
    /// Explicitly fetches again; concurrent readers share that refresh operation.
    public func refresh() async throws {
        // Keep a previous successful index if the refresh fails.
        let previous = cached
        cached = nil
        do {
            _ = try await load()
        } catch {
            if cached == nil, let previous { cached = previous }
            throw error
        }
    }

    @MainActor private func tracker() -> SymbolUsageTracker { usageTracker ?? .shared }

    private func load() async throws -> SymbolIndex {
        if let cached { return cached }
        let operation: (id: UUID, task: Task<SymbolIndex, Error>)
        if let pending {
            operation = pending
        } else {
            let source = self.source
            operation = (UUID(), Task { try await source.fetch() })
            pending = operation
        }
        do {
            let index = try await operation.task.value
            if pending?.id == operation.id {
                cached = index
                lastUpdated = Date()
                pending = nil
            }
            return index
        } catch {
            if pending?.id == operation.id { pending = nil }
            throw error
        }
    }
}
