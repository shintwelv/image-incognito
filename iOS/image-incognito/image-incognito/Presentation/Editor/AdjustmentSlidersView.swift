//
//  AdjustmentSlidersView.swift
//  image-incognito
//
//  Bottom-panel sliders for controlling mask intensity, bounding-box size,
//  and fill color (solidClean style only).
//

import SwiftUI

// MARK: - Adjustment Sliders View

struct AdjustmentSlidersView: View {
    @Environment(SettingsStore.self) private var settingsStore
    @Binding var intensity: Double
    @Binding var sizeMultiplier: Double
    let selectedStyle: MaskingStyle
    @Binding var solidCleanColor: Color
    @Binding var selectedEmoji: String

    @State private var showAddEmojiAlert = false
    @State private var newEmojiText = ""

    var body: some View {
        VStack(spacing: Spacing.medium) {
            SliderRow(
                title: "editor.intensity",
                value: $intensity,
                range: 0...1,
                displayValue: "\(Int(intensity * 100))%"
            )
            .accessibilityIdentifier("editor.intensitySlider")
            SliderRow(
                title: "editor.range",
                value: $sizeMultiplier,
                range: 0.5...2.0,
                displayValue: "\(Int(sizeMultiplier * 100))%"
            )
            .accessibilityIdentifier("editor.sizeSlider")
            if selectedStyle == .solidClean {
                ColorPickerRow(color: $solidCleanColor)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .accessibilityIdentifier("editor.colorPicker")
            }
            if selectedStyle == .emojiOverlay {
                EmojiPickerRow(
                    selectedEmoji: $selectedEmoji,
                    emojiPresets: settingsStore.emojiPresets,
                    onAddEmoji: { showAddEmojiAlert = true },
                    onDeleteEmoji: { emoji in settingsStore.removeEmojiPreset(emoji) }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .accessibilityIdentifier("editor.emojiPicker")
            }
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .appShadow(.card)
        .animation(AppAnimation.standard, value: selectedStyle)
        .alert(String(localized: "editor.addEmojiTitle"), isPresented: $showAddEmojiAlert) {
            TextField("😎", text: $newEmojiText)
            Button(String(localized: "common.add")) {
                settingsStore.addEmojiPreset(newEmojiText)
                if !newEmojiText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    selectedEmoji = newEmojiText.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                newEmojiText = ""
            }
            Button(String(localized: "common.cancel"), role: .cancel) {
                newEmojiText = ""
            }
        } message: {
            Text(String(localized: "editor.addEmojiMessage"))
        }
    }
}

// MARK: - Slider Row

struct SliderRow: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>
    let displayValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            HStack {
                Text(title)
                    .font(.appFootnote)
                    .foregroundStyle(Color.appLabelSecondary)
                Spacer()
                Text(displayValue)
                    .font(.appCaption2)
                    .foregroundStyle(Color.appLabelTertiary)
                    .monospacedDigit()
                    .animation(nil, value: displayValue)
            }
            Slider(value: $value, in: range, step: 0.05)
                .tint(Color.appPrimary)
                .onChange(of: value) { _, _ in AppHaptics.selection() }
        }
    }
}

// MARK: - Color Picker Row

struct ColorPickerRow: View {
    @Binding var color: Color

    var body: some View {
        HStack {
            Text("editor.color")
                .font(.appFootnote)
                .foregroundStyle(Color.appLabelSecondary)
            Spacer()
            ColorPicker("", selection: $color, supportsOpacity: false)
                .labelsHidden()
                .onChange(of: color) { _, _ in AppHaptics.selection() }
        }
    }
}

// MARK: - Emoji Picker Row

struct EmojiPickerRow: View {
    @Binding var selectedEmoji: String
    let emojiPresets: [String]
    let onAddEmoji: () -> Void
    let onDeleteEmoji: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text("editor.emoji")
                .font(.appFootnote)
                .foregroundStyle(Color.appLabelSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    ForEach(emojiPresets, id: \.self) { emoji in
                        Button {
                            AppHaptics.selection()
                            selectedEmoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.system(size: 22))
                                .padding(Spacing.xxSmall + 2)
                                .background(
                                    Circle()
                                        .fill(selectedEmoji == emoji ? Color.appPrimary.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(selectedEmoji == emoji ? Color.appPrimary : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                onDeleteEmoji(emoji)
                            } label: {
                                Label("common.delete", systemImage: "trash")
                            }
                        }
                    }

                    Button {
                        AppHaptics.medium()
                        onAddEmoji()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.appPrimary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.appPrimary.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
        }
    }
}
