import Foundation

public struct Symbol: Codable, Hashable, Identifiable, Sendable {
    public let name: String
    public let categories: [String]
    public let keywords: [String]
    /// Alternative system names, used like SwiftEmoji shortcodes during search.
    public let aliases: [String]
    private enum CodingKeys: String, CodingKey { case name, categories, keywords, aliases }
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.categories = try container.decode([String].self, forKey: .categories)
        self.keywords = try container.decode([String].self, forKey: .keywords)
        self.aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
    }
    public var id: String { name }
    public var displayName: String { name.replacingOccurrences(of: ".", with: " ") }

    public init(name: String, categories: [String] = [], keywords: [String] = [], aliases: [String] = []) {
        self.name = name
        self.categories = categories
        self.keywords = keywords
        self.aliases = aliases
    }
}

public struct SymbolCategory: Codable, Hashable, Identifiable, Sendable {
    public let key: String
    public let label: String
    public let icon: String
    public var id: String { key }
    public var displayName: String { label }
    public var symbolName: String { icon }
    public init(key: String, label: String, icon: String) {
        self.key = key
        self.label = label
        self.icon = icon
    }
}

public struct SymbolSection: Identifiable, Sendable {
    public let category: SymbolCategory
    public let symbols: [Symbol]
    public var id: String { category.id }
    public init(category: SymbolCategory, symbols: [Symbol]) {
        self.category = category
        self.symbols = symbols
    }
}


/// Relevance tiers and optional usage/alphabetical ordering, adapted from SwiftEmoji.
public enum SearchRanking: Sendable {
    case relevance
    case usage
    case alphabetical
}

/// An immutable prepared index with direct name/alias lookups and cached sections.
/// Search follows SwiftEmoji's exact/name/alias/keyword relevance tiers.
public struct SymbolIndex: Sendable {
    public let symbols: [Symbol]
    public let categories: [SymbolCategory]
    public let sections: [SymbolSection]
    private let byName: [String: Symbol]
    private let byAlias: [String: Symbol]
    private let records: [SearchRecord]

    private struct SearchRecord: Sendable {
        let symbol: Symbol
        let name: String
        let aliases: [String]
        let keywords: [String]
    }

    public init(symbols: [Symbol], categories: [SymbolCategory]) {
        // Keep the first occurrence and its browse position, matching source order.
        var names: [String: Symbol] = [:]
        let uniqueSymbols = symbols.filter { names.updateValue($0, forKey: $0.name) == nil }
        self.symbols = uniqueSymbols
        self.categories = categories
        self.byName = Dictionary(uniqueSymbols.map { ($0.name.lowercased(), $0) }, uniquingKeysWith: { first, _ in first })
        var aliases: [String: Symbol] = [:]
        for symbol in uniqueSymbols {
            for alias in symbol.aliases where aliases[alias.lowercased()] == nil {
                aliases[alias.lowercased()] = symbol
            }
        }
        self.byAlias = aliases
        self.records = uniqueSymbols.map { symbol in
            SearchRecord(symbol: symbol, name: Self.normalize(symbol.name),
                         aliases: symbol.aliases.map(Self.normalize),
                         keywords: (symbol.keywords + symbol.categories).map(Self.normalize))
        }
        var sections = categories.compactMap { category -> SymbolSection? in
            let matches = uniqueSymbols.filter { $0.categories.contains(category.id) }
            return matches.isEmpty ? nil : SymbolSection(category: category, symbols: matches)
        }
        let categoryIDs = Set(categories.map(\.id))
        let other = uniqueSymbols.filter { categoryIDs.isDisjoint(with: $0.categories) }
        if !other.isEmpty {
            sections.append(SymbolSection(category: SymbolCategory(key: "other", label: "Other", icon: "square.grid.2x2"), symbols: other))
        }
        self.sections = sections
    }

    /// Decodes app-supplied catalog JSON with `symbols` and `categories` arrays.
    /// Uses the same schema as the bundled catalog and propagates decoding errors.
    public init(data: Data) throws {
        struct Catalog: Decodable {
            let symbols: [Symbol]
            let categories: [SymbolCategory]
        }
        let catalog = try JSONDecoder().decode(Catalog.self, from: data)
        self.init(symbols: catalog.symbols, categories: catalog.categories)
    }

    /// Reads the complete bundled catalog; apps can supply their own data sources.
    public static func load() throws -> SymbolIndex {
        guard let url = Bundle.module.url(forResource: "catalog", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try SymbolIndex(data: Data(contentsOf: url))
    }

    /// Constant-time lookup by current or historical system name, ignoring case.
    public func symbol(for name: String) -> Symbol? {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return byName[key] ?? byAlias[key]
    }

    /// Matches all query terms; exact names/aliases remain first for every ranking.
    /// Usage scores are supplied as a snapshot so this value stays concurrency-safe.
    public func search(_ query: String, ranking: SearchRanking = .relevance,
                       usageScores: [String: Double] = [:]) -> [Symbol] {
        let normalized = Self.normalize(query)
        let terms = normalized.split(separator: " ").map(String.init)
        var matches: [(symbol: Symbol, tier: Int, position: Int)] = []
        for (position, record) in records.enumerated() {
            let tier: Int
            if terms.isEmpty {
                tier = 1
            } else if record.name == normalized || record.aliases.contains(normalized) {
                tier = 0
            } else if terms.allSatisfy({ record.name.contains($0) }) {
                tier = 1
            } else if terms.allSatisfy({ term in
                record.name.contains(term) || record.aliases.contains { Self.hasPrefix(term, in: $0) }
            }) {
                tier = 2
            } else if terms.allSatisfy({ term in
                record.name.contains(term) || record.aliases.contains { Self.hasPrefix(term, in: $0) }
                    || record.keywords.contains { Self.hasPrefix(term, in: $0) }
            }) {
                tier = 3
            } else {
                continue
            }
            matches.append((record.symbol, tier, position))
        }
        return matches.sorted { lhs, rhs in
            if (lhs.tier == 0) != (rhs.tier == 0) { return lhs.tier == 0 }
            switch ranking {
            case .relevance:
                if lhs.tier != rhs.tier { return lhs.tier < rhs.tier }
            case .usage:
                let leftScore = usageScores[lhs.symbol.name, default: 0]
                let rightScore = usageScores[rhs.symbol.name, default: 0]
                if leftScore != rightScore { return leftScore > rightScore }
                if lhs.tier != rhs.tier { return lhs.tier < rhs.tier }
            case .alphabetical:
                if lhs.symbol.name != rhs.symbol.name { return lhs.symbol.name < rhs.symbol.name }
            }
            return lhs.position < rhs.position
        }.map(\.symbol)
    }

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .split { !$0.isLetter && !$0.isNumber }.joined(separator: " ")
    }

    private static func hasPrefix(_ term: String, in text: String) -> Bool {
        text.split(separator: " ").contains { $0.hasPrefix(term) }
    }
}
