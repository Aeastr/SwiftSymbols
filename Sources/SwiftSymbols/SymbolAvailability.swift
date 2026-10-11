import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension SymbolIndex {
    /// Removes names the current system cannot render. No private framework is loaded.
    @MainActor public func availableOnCurrentSystem() -> SymbolIndex {
        SymbolIndex(symbols: symbols.filter {
#if canImport(UIKit)
            UIImage(systemName: $0.name) != nil
#elseif canImport(AppKit)
            NSImage(systemSymbolName: $0.name, accessibilityDescription: nil) != nil
#else
            false
#endif
        }, categories: categories)
    }
}
