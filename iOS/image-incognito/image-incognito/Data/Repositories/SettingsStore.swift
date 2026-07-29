//
//  SettingsStore.swift
//  image-incognito
//
//  Data Repository – App-wide settings container.
//  Persists ExportSettings to UserDefaults so they survive app termination.
//  Lives in the Data layer because UserDefaults is an infrastructure concern.
//

import Observation
import Foundation

@Observable
final class SettingsStore {

    private static let userDefaultsKey = "com.image-incognito.exportSettings"
    private static let emojiPresetsKey = "com.image-incognito.emojiPresets"

    static let defaultEmojiPresets: [String] = ["😎", "🐱", "🙈", "🎭", "⭐️", "💩", "🤡", "🎃", "🐶"]

    /// Default export options applied whenever a new export session starts.
    /// Any change is immediately written to UserDefaults.
    var exportSettings: ExportSettings {
        didSet { persistSettings() }
    }

    /// User-managed list of available emoji presets for masking.
    var emojiPresets: [String] {
        didSet { persistEmojis() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
           let decoded = try? JSONDecoder().decode(ExportSettings.self, from: data) {
            exportSettings = decoded
        } else {
            exportSettings = ExportSettings()
        }

        if let savedPresets = UserDefaults.standard.stringArray(forKey: Self.emojiPresetsKey),
           !savedPresets.isEmpty {
            emojiPresets = savedPresets
        } else {
            emojiPresets = Self.defaultEmojiPresets
        }
    }

    // MARK: - Emoji Management

    func addEmojiPreset(_ rawEmoji: String) {
        let trimmed = rawEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !emojiPresets.contains(trimmed) else { return }
        emojiPresets.append(trimmed)
    }

    func removeEmojiPreset(_ emoji: String) {
        emojiPresets.removeAll { $0 == emoji }
        if emojiPresets.isEmpty {
            emojiPresets = Self.defaultEmojiPresets
        }
    }

    func resetEmojiPresets() {
        emojiPresets = Self.defaultEmojiPresets
    }

    // MARK: - Private

    private func persistSettings() {
        guard let data = try? JSONEncoder().encode(exportSettings) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }

    private func persistEmojis() {
        UserDefaults.standard.set(emojiPresets, forKey: Self.emojiPresetsKey)
    }
}
