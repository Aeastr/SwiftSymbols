# Integrating a symbol picker

Choose selection behavior and connect the grid to your app's presentation.

@Metadata {
    @TopicsVisualStyle(detailedGrid)
}

## Load and filter

`SymbolIndex.load()` throws if the bundled catalog cannot be read or decoded. Decode away from the main actor, then call `availableOnCurrentSystem()` on the main actor once before presentation. This filters names using public system-image lookup. Present a loading state and surface errors with an action appropriate to your app.

## Browse and search

Place `SymbolGrid(sections: index.sections, selection: $selected)` inside a ScrollView. Pass `index.search(query)` to the flat `symbols:` initializer for search results. Empty or whitespace-only queries return the full catalog. Every query term must match the name, keywords or category keys; exact symbol names rank first. Other contains names outside the topical categories.

## Confirm or toggle

The callback initializer invokes its closure on every tap. Use it for immediate confirmation and dismissal. Single selection uses `Binding<Symbol?>` and toggles the current symbol off when tapped again. Multiple selection uses `Binding<Set<String>>`, storing system names. Persist the selected symbol's `name` in the host model.

## Customize presentation

The grid's style controls layout, cells and section headers. The default uses adaptive lazy columns with 44-point cells. Large uses 56-point cells; compact uses a horizontal grid with 36-point cells. Wrap the compact grid in a horizontal ScrollView. The host chooses padding, search presentation and dismissal controls.

## Topics

### Components

- ``SymbolGrid``
- ``SymbolGridStyle``
