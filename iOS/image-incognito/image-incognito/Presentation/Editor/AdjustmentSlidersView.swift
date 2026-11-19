//
//  AdjustmentSlidersView.swift
//  image-incognito
//
//  Bottom-panel controls for the selected region: inclusion, delete, apply to
//  all, shape (manual only), intensity, size (faces only), color, and emoji.
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

    /// When provided, enables the full region panel (status, actions, shape).
    var region: MaskRegion? = nil
    var onToggleInclusion: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onApplyToAll: (() -> Void)? = nil
    var onShapeChange: ((MaskRegion.Shape) -> Void)? = nil

    @State private var showAddEmojiAlert = false
    @State private var newEmojiText = ""

    private var showsSizeSlider: Bool {
        region?.isFace ?? true
    }

    var body: some View {
        VStack(spacing: Spacing.medium) {
            if let region {
                regionHeader(region)
                actionRow(region)

                if region.isManual {
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text("editor.shape.title")
                            .font(.appFootnote)
                            .foregroundStyle(Color.appLabelSecondary)
                        ShapePickerRow(
                            selectedShape: region.shape,
                            onSelect: { onShapeChange?($0) }
                        )
                        Text("editor.shape.switchHint")
                            .font(.appCaption)
                            .foregroundStyle(Color.appLabelTertiary)
                    }
                }
            }

            SliderRow(
                title: "editor.intensity",
                value: $intensity,
                range: 0...1,
                displayValue: "\(Int(intensity * 100))%"
            )
            .accessibilityIdentifier("editor.intensitySlider")

            if showsSizeSlider {
                SliderRow(
                    title: "editor.range",
                    value: $sizeMultiplier,
                    range: 0.5...2.0,
                    displayValue: "\(Int(sizeMultiplier * 100))%"
                )
                .accessibilityIdentifier("editor.sizeSlider")
            } else {
                Text("editor.region.handlesHint")
                    .font(.appCaption)
                    .foregroundStyle(Color.appLabelTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("editor.manualHandlesHint")
            }

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
        .accessibilityIdentifier("editor.adjustmentPanel")
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

    // MARK: - Region header

    private func regionHeader(_ region: MaskRegion) -> some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: region.isManual ? region.shape.iconName : "person.fill")
                .imageScale(.small)
                .foregroundStyle(Color.appPrimary)

            Text(LocalizedStringKey(region.isManual ? "editor.region.manual" : "editor.region.face"))
                .font(.appFootnote)
                .foregroundStyle(Color.appLabelSecondary)

            Text("·")
                .font(.appCaption)
                .foregroundStyle(Color.appLabelTertiary)

            Text(LocalizedStringKey(region.isIncluded ? "editor.region.included" : "editor.region.excluded"))
                .font(.appCaption2)
                .foregroundStyle(region.isIncluded ? Color.appPrimary : Color.appDestructive)

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Actions

    private func actionRow(_ region: MaskRegion) -> some View {
        HStack(spacing: Spacing.small) {
            panelAction(
                titleKey: region.isIncluded ? "editor.region.exclude" : "editor.region.include",
                icon: region.isIncluded ? "eye.slash" : "eye",
                color: .appPrimary,
                identifier: "editor.inclusionToggle"
            ) {
                onToggleInclusion?()
            }

            panelAction(
                titleKey: "editor.region.delete",
                icon: "trash",
                color: .appDestructive,
                identifier: "editor.deleteRegion"
            ) {
                onDelete?()
            }

            Spacer(minLength: Spacing.xSmall)

            panelAction(
                titleKey: "editor.style.applyToAll",
                icon: "square.on.square",
                color: .appPrimary,
                identifier: "editor.applyToAll"
            ) {
                onApplyToAll?()
            }
        }
    }

    private func panelAction(
        titleKey: String,
        icon: String,
        color: Color,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            AppHaptics.light()
            action()
        } label: {
            HStack(spacing: Spacing.xxSmall) {
                Image(systemName: icon)
                    .imageScale(.small)
                Text(LocalizedStringKey(titleKey))
                    .font(.appCaption)
                    .lineLimit(1)
            }
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.xSmall)
            .frame(minHeight: 44)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: Radius.element, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
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
