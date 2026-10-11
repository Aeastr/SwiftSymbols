// Adapted from SwiftEmoji. Copyright (c) 2026 Aether; MIT License.
import SwiftUI
import SwiftSymbolsIndex

/// A grid view for displaying and selecting symbols.
///
/// `SymbolGrid` provides a flexible way to display symbols. The layout
/// is controlled by the style - use `.symbolGridStyle()` to customize.
///
/// It does NOT include a ScrollView - you wrap it yourself for full control.
///
/// ## Sectioned vs Flat
///
/// Pass `sections` for a categorized picker with headers:
/// ```swift
/// let sections = try SymbolIndex.load().sections
/// SymbolGrid(sections: sections) { symbol in
///     selected = symbol
/// }
/// ```
///
/// Pass `symbols` for a flat list (search results, favorites):
/// ```swift
/// let results = try SymbolIndex.load().search(query)
/// SymbolGrid(symbols: results) { symbol in
///     selected = symbol
/// }
/// ```
///
/// ## Selection Modes
///
/// ### Tap-only (no selection state)
/// ```swift
/// SymbolGrid(sections: sections) { symbol in
///     canvas.add(symbol)
///     dismiss()
/// }
/// ```
///
/// ### Single selection
/// ```swift
/// SymbolGrid(sections: sections, selection: $selected)
/// ```
///
/// ### Multiple selection
/// ```swift
/// SymbolGrid(sections: sections, selection: $selectedSet)
/// ```
///
/// ## Styling
///
/// ```swift
/// SymbolGrid(sections: sections, selection: $selected)
///     .symbolGridStyle(.large)
/// ```
public struct SymbolGrid: View {
    private let symbols: [Symbol]
    private let sections: [SymbolSection]?
    private let onTap: ((Symbol) -> Void)?
    private let selectionMode: SelectionMode

    @Binding private var singleSelection: Symbol?
    @Binding private var multipleSelection: Set<String>

    @Environment(\.symbolGridStyle) private var style

    private enum SelectionMode {
        case none
        case single
        case multiple
    }

    // MARK: - Flat Symbols (Tap-only)

    /// Creates an symbol grid with tap-only interaction.
    public init(
        symbols: [Symbol],
        onTap: @escaping (Symbol) -> Void
    ) {
        self.symbols = symbols
        self.sections = nil
        self.onTap = onTap
        self.selectionMode = .none
        self._singleSelection = .constant(nil)
        self._multipleSelection = .constant([])
    }

    // MARK: - Flat Symbols (Single Selection)

    /// Creates an symbol grid with single selection.
    public init(
        symbols: [Symbol],
        selection: Binding<Symbol?>
    ) {
        self.symbols = symbols
        self.sections = nil
        self.onTap = nil
        self.selectionMode = .single
        self._singleSelection = selection
        self._multipleSelection = .constant([])
    }

    // MARK: - Flat Symbols (Multiple Selection)

    /// Creates an symbol grid with multiple selection.
    public init(
        symbols: [Symbol],
        selection: Binding<Set<String>>
    ) {
        self.symbols = symbols
        self.sections = nil
        self.onTap = nil
        self.selectionMode = .multiple
        self._singleSelection = .constant(nil)
        self._multipleSelection = selection
    }

    // MARK: - Sectioned (Tap-only)

    /// Creates a sectioned symbol grid with tap-only interaction.
    public init(
        sections: [SymbolSection],
        onTap: @escaping (Symbol) -> Void
    ) {
        self.symbols = sections.flatMap(\.symbols)
        self.sections = sections
        self.onTap = onTap
        self.selectionMode = .none
        self._singleSelection = .constant(nil)
        self._multipleSelection = .constant([])
    }

    // MARK: - Sectioned (Single Selection)

    /// Creates a sectioned symbol grid with single selection.
    public init(
        sections: [SymbolSection],
        selection: Binding<Symbol?>
    ) {
        self.symbols = sections.flatMap(\.symbols)
        self.sections = sections
        self.onTap = nil
        self.selectionMode = .single
        self._singleSelection = selection
        self._multipleSelection = .constant([])
    }

    // MARK: - Sectioned (Multiple Selection)

    /// Creates a sectioned symbol grid with multiple selection.
    public init(
        sections: [SymbolSection],
        selection: Binding<Set<String>>
    ) {
        self.symbols = sections.flatMap(\.symbols)
        self.sections = sections
        self.onTap = nil
        self.selectionMode = .multiple
        self._singleSelection = .constant(nil)
        self._multipleSelection = selection
    }

    // MARK: - Body

    public var body: some View {
        if let sections {
            style.makeGrid(configuration: GridConfiguration(
                sections: sections,
                selection: currentSelection,
                isSelectable: selectionMode != .none,
                isSelected: isSymbolSelected,
                onTap: handleTap
            ))
        } else {
            style.makeGrid(configuration: GridConfiguration(
                symbols: symbols,
                selection: currentSelection,
                isSelectable: selectionMode != .none,
                isSelected: isSymbolSelected,
                onTap: handleTap
            ))
        }
    }

    // MARK: - Private

    private var currentSelection: Set<String> {
        switch selectionMode {
        case .none:
            return []
        case .single:
            if let selected = singleSelection {
                return [selected.id]
            }
            return []
        case .multiple:
            return multipleSelection
        }
    }

    private func isSymbolSelected(_ symbol: Symbol) -> Bool {
        switch selectionMode {
        case .none:
            return false
        case .single:
            return singleSelection?.id == symbol.id
        case .multiple:
            return multipleSelection.contains(symbol.id)
        }
    }

    private func handleTap(_ symbol: Symbol) {
        switch selectionMode {
        case .none:
            onTap?(symbol)
        case .single:
            singleSelection = (singleSelection?.id == symbol.id) ? nil : symbol
        case .multiple:
            if multipleSelection.contains(symbol.id) {
                multipleSelection.remove(symbol.id)
            } else {
                multipleSelection.insert(symbol.id)
            }
        }
    }
}

// MARK: - Environment

/// Type-erased wrapper for SymbolGridStyle.
struct AnySymbolGridStyle: @unchecked Sendable {
    private let _makeGrid: @MainActor (GridConfiguration) -> AnyView
    private let _makeCell: @MainActor (CellConfiguration) -> AnyView
    private let _makeSectionHeader: @MainActor (HeaderConfiguration) -> AnyView

    init<S: SymbolGridStyle>(_ style: S) {
        _makeGrid = { @MainActor in AnyView(style.makeGrid(configuration: $0)) }
        _makeCell = { @MainActor in AnyView(style.makeCell(configuration: $0)) }
        _makeSectionHeader = { @MainActor in AnyView(style.makeSectionHeader(configuration: $0)) }
    }

    @MainActor
    func makeGrid(configuration: GridConfiguration) -> AnyView {
        _makeGrid(configuration)
    }

    @MainActor
    func makeCell(configuration: CellConfiguration) -> AnyView {
        _makeCell(configuration)
    }

    @MainActor
    func makeSectionHeader(configuration: HeaderConfiguration) -> AnyView {
        _makeSectionHeader(configuration)
    }
}

private struct SymbolGridStyleKey: EnvironmentKey {
    static let defaultValue = AnySymbolGridStyle(DefaultSymbolGridStyle())
}

extension EnvironmentValues {
    var symbolGridStyle: AnySymbolGridStyle {
        get { self[SymbolGridStyleKey.self] }
        set { self[SymbolGridStyleKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for symbol grids within this view.
    public func symbolGridStyle<S: SymbolGridStyle>(_ style: S) -> some View {
        environment(\.symbolGridStyle, AnySymbolGridStyle(style))
    }
}

