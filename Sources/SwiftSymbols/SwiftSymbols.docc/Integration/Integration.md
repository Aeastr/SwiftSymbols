# Integrating a symbol picker

Choose selection behavior and connect the grid to your app's presentation.

@Metadata {
    @TopicsVisualStyle(detailedGrid)
}

## Load and filter

`SymbolIndexProvider.shared.index` provides the complete bundled catalog. Apps supply their own collections through `JSONSymbolDataSource(url:)`, `StaticSymbolDataSource(index:)` or a custom `SymbolDataSource`. JSON sources decode arrays named `symbols` and `categories`, matching the bundled catalog schema; `SymbolIndex(data:)` exposes the decoder directly. Source read/decoding errors propagate to callers. The provider coalesces concurrent loads and prepares lookup/search records away from the UI. Call `availableOnCurrentSystem()` on the main actor once before presentation. This filters names using public system-image lookup. Present a loading state and surface errors with an action appropriate to your app.

## Browse and search

Place `SymbolGrid(sections: index.sections, selection: $selected)` inside a ScrollView. Pass `index.search(query)` to the flat `symbols:` initializer for search results. Empty or whitespace-only queries return the full catalog. Every query term must match the name, keywords or category keys; exact symbol names and aliases rank first. Name matches precede alias prefixes and keyword prefixes. Use `.usage` or `.alphabetical` ranking when appropriate; exact matches stay pinned. Other contains names outside topical categories in a custom or full index. Apps maintain their own representatives, keywords and category assignments.

## Usage and favorites

Record explicit choices with `SymbolUsageTracker.shared.recordUse(name)` on the main actor. Scores persist in UserDefaults and decay on each choice, balancing frequency and recency. Provider favorites resolve history against the active collection so unsupported or excluded names are omitted. Supply `StaticSymbolDataSource(index: availableIndex)` after OS filtering to keep search and history within supported choices. Inject a tracker to use a separate history key. `isEnabled`, `clearScore(for:)` and `clearAll()` control that history.

## Confirm or toggle

The callback initializer invokes its closure on every tap. Use it for immediate confirmation and dismissal. Single selection uses `Binding<Symbol?>` and toggles the current symbol off when tapped again. Multiple selection uses `Binding<Set<String>>`, storing system names. Persist the selected symbol's `name` in the host model.

## Customize presentation

The grid's style controls layout, cells and section headers. The default uses adaptive lazy columns with 44-point cells. Large uses 56-point cells; compact uses a horizontal grid with 36-point cells. Wrap the compact grid in a horizontal ScrollView. The host chooses padding, search presentation and dismissal controls.

## Topics

### Components

- ``SymbolGrid``
- ``SymbolGridStyle``
