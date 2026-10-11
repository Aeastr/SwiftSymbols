// Adapted from SwiftEmoji. Copyright (c) 2026 Aether; MIT License.
import SwiftUI
import SwiftSymbolsIndex

/// A view that displays a section header for an symbol category.
///
/// This is the default header view used by `SymbolGrid`. You can customize
/// its appearance using `SymbolGridStyle.makeSectionHeader`.
public struct SymbolSectionHeader: View {
    /// The category for this header.
    private let category: SymbolCategory?

    private let title: String?
    private let systemImage: String?

    /// Creates a section header.
    /// - Parameter category: The category to display
    public init(category: SymbolCategory) {
        self.category = category
        self.title = nil
        self.systemImage = nil
    }

    public init(_ title: String, systemImage: String){
        self.title = title
        self.systemImage = systemImage
        self.category = nil
    }

    private var resolvedTitle: String? { category?.displayName ?? title }

    private var resolvedSymbolName: String? { category?.symbolName ?? systemImage }

    public var body: some View {
        HStack {
            if let resolvedSymbolName {
                Image(systemName: resolvedSymbolName)
                    .foregroundStyle(.secondary)
                    .frame(width: 25)
            }

            if let resolvedTitle {
                Text(resolvedTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}

