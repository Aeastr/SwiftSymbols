// Adapted from SwiftEmoji. Copyright (c) 2026 Aether; MIT License.
import SwiftUI
import SwiftSymbolsIndex

/// A protocol for customizing the appearance and layout of symbol grids.
///
/// The style is responsible for creating the entire grid layout, cell views,
/// and section headers. This gives you full control over spacing, sizing,
/// animations, and visual appearance.
///
/// ## Creating a Custom Style
///
/// ```swift
/// struct MyStyle: SymbolGridStyle {
///     func makeGrid(configuration: GridConfiguration) -> some View {
///         LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
///             ForEach(configuration.symbols) { symbol in
///                 makeCell(configuration: CellConfiguration(
///                     symbol: symbol,
///                     isSelected: configuration.isSelected(symbol),
///                     isSelectable: configuration.isSelectable,
///                     onTap: { configuration.onTap(symbol) }
///                 ))
///             }
///         }
///     }
///
///     func makeCell(configuration: CellConfiguration) -> some View {
///         Button(action: configuration.onTap) {
///             Image(systemName: configuration.symbol.name)
///                 .font(.system(size: 32))
///         }
///         .background(configuration.isSelected ? Color.blue.opacity(0.2) : .clear)
///     }
///
///     func makeSectionHeader(configuration: HeaderConfiguration) -> some View {
///         Text(configuration.category.displayName)
///             .font(.headline)
///     }
/// }
/// ```
///
/// ## Applying a Style
///
/// ```swift
/// SymbolGrid(symbols: symbols, selection: $selection)
///     .symbolGridStyle(MyStyle())
/// ```
public protocol SymbolGridStyle: Sendable {
    associatedtype GridBody: View
    associatedtype CellBody: View
    associatedtype HeaderBody: View

    /// Creates the grid layout with all cells.
    @MainActor @ViewBuilder
    func makeGrid(configuration: GridConfiguration) -> GridBody

    /// Creates an individual cell view.
    @MainActor @ViewBuilder
    func makeCell(configuration: CellConfiguration) -> CellBody

    /// Creates a section header view.
    @MainActor @ViewBuilder
    func makeSectionHeader(configuration: HeaderConfiguration) -> HeaderBody
}
