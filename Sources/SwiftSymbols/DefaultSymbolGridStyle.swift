// Adapted from SwiftEmoji. Copyright (c) 2026 Aether; MIT License.
import SwiftUI
import SwiftSymbolsIndex

// MARK: - Style Shortcuts

extension SymbolGridStyle where Self == DefaultSymbolGridStyle {
    /// Default style with 44pt cells and 4pt spacing.
    public static var `default`: DefaultSymbolGridStyle { DefaultSymbolGridStyle() }

    /// Default style with custom cell size and spacing.
    public static func `default`(cellSize: CGFloat, spacing: CGFloat = 4) -> DefaultSymbolGridStyle {
        DefaultSymbolGridStyle(cellSize: cellSize, spacing: spacing)
    }
}

extension SymbolGridStyle where Self == LargeSymbolGridStyle {
    /// Large style with 56pt cells and backgrounds.
    public static var large: LargeSymbolGridStyle { LargeSymbolGridStyle() }
}

extension SymbolGridStyle where Self == CompactSymbolGridStyle {
    /// Compact horizontal style with 36pt cells.
    public static var compact: CompactSymbolGridStyle { CompactSymbolGridStyle() }
}

// MARK: - Default Style

/// The default symbol grid style.
public struct DefaultSymbolGridStyle: SymbolGridStyle, @unchecked Sendable {
    public let cellSize: CGFloat
    public let spacing: CGFloat
    public let columns: [GridItem]?

    public init(
        cellSize: CGFloat = 44,
        spacing: CGFloat = 4,
        columns: [GridItem]? = nil
    ) {
        self.cellSize = cellSize
        self.spacing = spacing
        self.columns = columns
    }

    public func makeGrid(configuration: GridConfiguration) -> some View {
        let gridColumns = columns ?? [GridItem(.adaptive(minimum: cellSize), spacing: spacing)]

        LazyVGrid(columns: gridColumns, spacing: spacing) {
            if let sections = configuration.sections {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.symbols) { symbol in
                            makeCell(configuration: CellConfiguration(
                                symbol: symbol,
                                isSelected: configuration.isSelected(symbol),
                                isSelectable: configuration.isSelectable,
                                onTap: { configuration.onTap(symbol) }
                            ))
                        }
                    } header: {
                        makeSectionHeader(configuration: HeaderConfiguration(category: section.category))
                    }
                }
            } else {
                ForEach(configuration.symbols) { symbol in
                    makeCell(configuration: CellConfiguration(
                        symbol: symbol,
                        isSelected: configuration.isSelected(symbol),
                        isSelectable: configuration.isSelectable,
                        onTap: { configuration.onTap(symbol) }
                    ))
                }
            }
        }
    }

    public func makeCell(configuration: CellConfiguration) -> some View {
        Button(action: configuration.onTap) {
            Image(systemName: configuration.symbol.name)
                .font(.system(size: cellSize * 0.5))
                .frame(width: cellSize, height: cellSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(configuration.symbol.displayName)
        .accessibilityAddTraits(configuration.isSelected ? .isSelected : [])
        .background {
            if configuration.isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.2))
            }
        }
//        .background(.red)
    }

    public func makeSectionHeader(configuration: HeaderConfiguration) -> some View {
        SymbolSectionHeader(category: configuration.category)
    }
}

/// A style with larger cells and more spacing.
public struct LargeSymbolGridStyle: SymbolGridStyle {
    public init() {}

    public func makeGrid(configuration: GridConfiguration) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 56))], spacing: 8) {
            if let sections = configuration.sections {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.symbols) { symbol in
                            makeCell(configuration: CellConfiguration(
                                symbol: symbol,
                                isSelected: configuration.isSelected(symbol),
                                isSelectable: configuration.isSelectable,
                                onTap: { configuration.onTap(symbol) }
                            ))
                        }
                    } header: {
                        makeSectionHeader(configuration: HeaderConfiguration(category: section.category))
                    }
                }
            } else {
                ForEach(configuration.symbols) { symbol in
                    makeCell(configuration: CellConfiguration(
                        symbol: symbol,
                        isSelected: configuration.isSelected(symbol),
                        isSelectable: configuration.isSelectable,
                        onTap: { configuration.onTap(symbol) }
                    ))
                }
            }
        }
    }

    public func makeCell(configuration: CellConfiguration) -> some View {
        Button(action: configuration.onTap) {
            Image(systemName: configuration.symbol.name)
                .font(.system(size: 28))
                .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(configuration.symbol.displayName)
        .accessibilityAddTraits(configuration.isSelected ? .isSelected : [])
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(configuration.isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
        }
        .overlay {
            if configuration.isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            }
        }
    }

    public func makeSectionHeader(configuration: HeaderConfiguration) -> some View {
        Text(configuration.category.displayName)
            .font(.headline)
            .padding(.vertical, 12)
    }
}

/// A compact horizontal style.
public struct CompactSymbolGridStyle: SymbolGridStyle {
    public init() {}

    public func makeGrid(configuration: GridConfiguration) -> some View {
        // Compact style ignores sections - it's designed for horizontal display
        LazyHGrid(rows: [GridItem(.fixed(36))], spacing: 4) {
            ForEach(configuration.symbols) { symbol in
                makeCell(configuration: CellConfiguration(
                    symbol: symbol,
                    isSelected: configuration.isSelected(symbol),
                    isSelectable: configuration.isSelectable,
                    onTap: { configuration.onTap(symbol) }
                ))
            }
        }
    }

    public func makeCell(configuration: CellConfiguration) -> some View {
        Button(action: configuration.onTap) {
            Image(systemName: configuration.symbol.name)
                .font(.system(size: 24))
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(configuration.symbol.displayName)
        .accessibilityAddTraits(configuration.isSelected ? .isSelected : [])
        .background {
            if configuration.isSelected {
                Circle().fill(Color.accentColor.opacity(0.2))
            }
        }
    }

    public func makeSectionHeader(configuration: HeaderConfiguration) -> some View {
        EmptyView()
    }
}
