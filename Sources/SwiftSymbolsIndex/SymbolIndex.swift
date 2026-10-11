import Foundation

public struct Symbol: Codable, Hashable, Identifiable, Sendable {
    public let name: String
    public let categories: [String]
    public let keywords: [String]
    public var id: String { name }
    public var displayName: String { name.replacingOccurrences(of: ".", with: " ") }

    public init(name: String, categories: [String] = [], keywords: [String] = []) {
        self.name = name
        self.categories = categories
        self.keywords = keywords
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

/// A value index independent of UI frameworks. Hosts filter availability for their OS.
public struct SymbolIndex: Sendable {
    public let symbols: [Symbol]
    public let categories: [SymbolCategory]

    public init(symbols: [Symbol], categories: [SymbolCategory]) {
        self.symbols = symbols
        self.categories = categories
    }

    public static func load() throws -> SymbolIndex {
        struct Catalog: Decodable {
            let symbols: [Symbol]
            let categories: [SymbolCategory]
        }
        guard let url = Bundle.module.url(forResource: "catalog", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))
        return SymbolIndex(symbols: catalog.symbols, categories: catalog.categories)
    }

    public var sections: [SymbolSection] {
        var sections = categories.compactMap { category -> SymbolSection? in
            let matches = symbols.filter { $0.categories.contains(category.id) }
            return matches.isEmpty ? nil : SymbolSection(category: category, symbols: matches)
        }
        let categoryIDs = Set(categories.map(\.id))
        let other = symbols.filter { categoryIDs.isDisjoint(with: $0.categories) }
        if !other.isEmpty {
            sections.append(SymbolSection(category: SymbolCategory(key: "other", label: "Other", icon: "square.grid.2x2"), symbols: other))
        }
        return sections
    }

    public func search(_ query: String) -> [Symbol] {
        let terms = query.lowercased().split { $0.isWhitespace || $0 == "." }
        guard !terms.isEmpty else { return symbols }
        return symbols.filter { symbol in
            let text = ([symbol.displayName] + symbol.keywords + symbol.categories).joined(separator: " ").lowercased()
            return terms.allSatisfy { text.contains($0) }
        }.sorted { lhs, rhs in
            let query = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let leftExact = lhs.name == query
            let rightExact = rhs.name == query
            return leftExact != rightExact ? leftExact : lhs.name < rhs.name
        }
    }
}
