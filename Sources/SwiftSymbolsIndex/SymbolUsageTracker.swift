// Adapted from SwiftEmoji. Copyright (c) 2026 Aether; MIT License.
import Foundation
import Observation

/// Persistent frequency/recency scores using SwiftEmoji's decay-and-boost algorithm.
/// Configure and record choices on the main actor; providers consume score snapshots.
@MainActor @Observable
public final class SymbolUsageTracker {
    public static let shared = SymbolUsageTracker()
    public var isEnabled = true
    public var maxFavorites = 24
    public var decayFactor = 0.9
    public var pruneThreshold = 0.01
    private var scores: [String: Double]
    private let defaults: UserDefaults
    private let storageKey: String

    public init(storageKey: String = "SwiftSymbolsIndex.usageScores", defaults: UserDefaults = .standard) {
        self.storageKey = storageKey
        self.defaults = defaults
        self.scores = (defaults.dictionary(forKey: storageKey) as? [String: Double] ?? [:])
            .filter { $0.value.isFinite && $0.value > 0 }
    }

    public var allScores: [String: Double] { isEnabled ? scores : [:] }
    public func score(for name: String) -> Double { allScores[name, default: 0] }
    public var favorites: [String] {
        allScores.filter { $0.value > pruneThreshold }
            .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .prefix(max(0, maxFavorites)).map(\.key)
    }
    public var hasFavorites: Bool { !favorites.isEmpty }

    /// Record an explicit choice, decaying older scores before boosting this name.
    public func recordUse(_ name: String) {
        guard isEnabled, !name.isEmpty else { return }
        let decay = decayFactor.isFinite ? min(1, max(0, decayFactor)) : 0.9
        scores = scores.mapValues { $0 * decay }.filter { $0.value > pruneThreshold }
        scores[name, default: 0] += 1
        save()
    }
    public func clearScore(for name: String) {
        scores[name] = nil
        save()
    }
    public func clearAll() {
        scores = [:]
        save()
    }
    private func save() { defaults.set(scores, forKey: storageKey) }
}
