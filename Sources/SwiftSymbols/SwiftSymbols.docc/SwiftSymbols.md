# ``SwiftSymbols``

Browse, search and select SF Symbols with a styleable SwiftUI grid.

@Metadata {
    @TopicsVisualStyle(detailedGrid)
}

## Overview

Supply an app-owned catalog through `SymbolDataSource` or load the complete bundled catalog through `SymbolIndexProvider`, filter it for the current system, then display flat results or categorized sections. The host supplies scrolling, navigation and selection storage. The Foundation-only SwiftSymbolsIndex product owns cached loading, name/alias indexing, relevance and usage search, and persistent frequency/recency history.

## Topics

### Integration

- <doc:Integration>

### Grids and styling

- ``SymbolGrid``
- ``SymbolGridStyle``
- ``DefaultSymbolGridStyle``
- ``LargeSymbolGridStyle``
- ``CompactSymbolGridStyle``
- ``SymbolSectionHeader``
