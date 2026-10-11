<div>
  <h1>SwiftSymbols <img src="Resources/icon/placeholder.svg" alt="SwiftSymbols icon placeholder" width="96" height="96" align="right"></h1>
  <p>Browse and select SF Symbols in a searchable, categorized SwiftUI grid.</p>
  <p><img src="https://img.shields.io/badge/iOS-17%2B-000000?logo=apple" alt="iOS 17+"> <img src="https://img.shields.io/badge/macOS-14%2B-000000?logo=apple" alt="macOS 14+"> <img src="https://img.shields.io/badge/tvOS-17%2B-000000?logo=apple" alt="tvOS 17+"> <img src="https://img.shields.io/badge/visionOS-1%2B-000000?logo=apple" alt="visionOS 1+"> <img src="https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift&amp;logoColor=white" alt="Swift 6.0+"></p>
</div>

## Installation

Add this directory as a local Swift package in Xcode and link **SwiftSymbols**. Link **SwiftSymbolsIndex** alone for Foundation-only catalog and search access.

## Quick start

```swift
import SwiftUI
import SwiftSymbols

struct SymbolPicker: View {
    @State private var sections: [SymbolSection] = []
    @State private var selected: Symbol?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let errorMessage {
                    Text(errorMessage)
                } else {
                    SymbolGrid(sections: sections, selection: $selected)
                        .padding()
                }
            }
            .navigationTitle("Symbols")
            .task {
                do {
                    let catalog = try await SymbolIndexProvider.shared.index
                    sections = catalog.availableOnCurrentSystem().sections
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
```

Apps own curated collections, subject vocabulary and browse categories. Use `.shared` for the complete bundled name catalog, `JSONSymbolDataSource` for an app-owned JSON file, or implement `SymbolDataSource` for another storage format. A `Symbol?` binding toggles single selection; a `Set<String>` binding toggles multiple symbol names. The callback initializer reports every tap, letting the host confirm a choice and dismiss. The host owns scrolling and navigation.

## Supply an app-owned index

Include your catalog JSON in the app's resources, then supply its URL:

```swift
func makeSymbolProvider(bundle: Bundle = .main) throws -> SymbolIndexProvider {
    guard let url = bundle.url(forResource: "symbols", withExtension: "json") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return SymbolIndexProvider(source: JSONSymbolDataSource(url: url))
}
```

The catalog schema is:

```json
{
  "categories": [{"key": "learning", "label": "Learning", "icon": "book.closed"}],
  "symbols": [{
    "name": "book.closed",
    "categories": ["learning"],
    "keywords": ["reading", "literature"],
    "aliases": []
  }]
}
```

`aliases` may be omitted. `SymbolIndex(data:)` decodes the same schema directly. `StaticSymbolDataSource` accepts an index constructed from models in code. The provider searches and resolves favorites within the supplied collection.

## Styling and search

Apply `.symbolGridStyle(.default(cellSize: 44, spacing: 4))`, `.large` or `.compact`. Implement `SymbolGridStyle` to customize grid layout, cells and headers.

`SymbolIndexProvider` adapts SwiftEmoji's index, data-source and search system: cached/coalesced loading, constant-time name and alias lookup, relevance tiers and usage ranking. Exact name or alias matches remain first, followed by name matches, alias prefixes and keyword prefixes. Every query term must match. Normalization handles case, accents, spaces and symbol-name punctuation.

```swift
let provider = SymbolIndexProvider.shared
let results = try await provider.search("computer science", ranking: .relevance)
let symbol = try await provider.symbol(for: "book.closed")
```

Call `SymbolUsageTracker.shared.recordUse(symbol.name)` on the main actor when a user chooses a symbol. `try await provider.favorites()` returns frequently/recently used choices from that provider's collection; `.usage` ranking uses the same persisted decay-and-boost scores as SwiftEmoji. Inject a tracker with a custom UserDefaults key to isolate histories. Hosts can disable tracking and clear history.

`availableOnCurrentSystem()` filters names using public UIImage/NSImage lookup; apply it once before displaying the catalog, then wrap the filtered index in `StaticSymbolDataSource` for lookup, search and favorites within that collection. Loading and search propagate source/decoding errors. `refresh()` reloads the source and preserves a previously successful index if the refresh fails.

## Used by

[Kyo Renaissance](https://github.com/Aeastr/Kyo) uses SwiftSymbols for its class symbol picker, supplying its own curated symbol catalog and subject search vocabulary.

## Documentation

See the [DocC introduction](Sources/SwiftSymbols/SwiftSymbols.docc/SwiftSymbols.md) and [picker integration guide](Sources/SwiftSymbols/SwiftSymbols.docc/Integration/Integration.md).

## Catalog maintenance

The bundled name/category/search metadata comes from the installed Apple SF Symbols app. System name/alias metadata is regenerated with `python3 Tools/build_catalog.py '/Applications/SF Symbols.app'`. Artwork is rendered by the operating system and remains subject to Apple's applicable SF Symbols use terms. Regenerate the complete catalog to include newly introduced names. Maintain app-specific representatives and search vocabulary in the consuming app.

## Tests and license

Run `swift test` for catalog integrity and search coverage. SwiftSymbols is MIT licensed; its grid, index-provider/search architecture and usage algorithm are adapted from Aether's SwiftEmoji, with attribution retained in [LICENSE](LICENSE).
