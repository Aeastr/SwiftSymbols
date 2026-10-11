// Adapted from SwiftEmoji. Copyright (c) 2026 Aether; MIT License.
import SwiftUI
import SwiftSymbolsIndex

/// Configuration passed to `SymbolGridStyle.makeGrid`.
public struct GridConfiguration {
    /// All symbols being displayed (flat list).
    public let symbols: [Symbol]

    /// Symbol sections (when displaying by category).
    /// When non-nil, styles should render section headers.
    public let sections: [SymbolSection]?

    /// Currently selected symbol names.
    public let selection: Set<String>

    /// Whether selection is enabled.
    public let isSelectable: Bool

    /// Closure to check if an symbol is selected.
    public let isSelected: (Symbol) -> Bool

    /// Closure to handle symbol tap.
    public let onTap: (Symbol) -> Void

    /// Creates a new grid configuration with flat symbols.
    @MainActor
    public init(
        symbols: [Symbol],
        selection: Set<String>,
        isSelectable: Bool,
        isSelected: @escaping (Symbol) -> Bool,
        onTap: @escaping (Symbol) -> Void
    ) {
        self.symbols = symbols
        self.sections = nil
        self.selection = selection
        self.isSelectable = isSelectable
        self.isSelected = isSelected
        self.onTap = onTap
    }

    /// Creates a new grid configuration with sections.
    @MainActor
    public init(
        sections: [SymbolSection],
        selection: Set<String>,
        isSelectable: Bool,
        isSelected: @escaping (Symbol) -> Bool,
        onTap: @escaping (Symbol) -> Void
    ) {
        self.symbols = sections.flatMap(\.symbols)
        self.sections = sections
        self.selection = selection
        self.isSelectable = isSelectable
        self.isSelected = isSelected
        self.onTap = onTap
    }
}

/// Configuration passed to `SymbolGridStyle.makeCell`.
public struct CellConfiguration {
    /// The symbol for this cell.
    public let symbol: Symbol

    /// Whether this symbol is currently selected.
    public let isSelected: Bool

    /// Whether selection is enabled for the grid.
    public let isSelectable: Bool

    /// Action to call when tapped.
    public let onTap: () -> Void

    /// Creates a new cell configuration.
    @MainActor
    public init(
        symbol: Symbol,
        isSelected: Bool,
        isSelectable: Bool,
        onTap: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.isSelected = isSelected
        self.isSelectable = isSelectable
        self.onTap = onTap
    }
}

/// Configuration passed to `SymbolGridStyle.makeSectionHeader`.
public struct HeaderConfiguration {
    /// The category for this header.
    public let category: SymbolCategory

    /// Creates a new header configuration.
    public init(category: SymbolCategory) {
        self.category = category
    }
}
