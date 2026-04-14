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
    @Binding var intensity: Double
    @Binding var sizeMultiplier: Double
    let selectedStyle: MaskingStyle
    @Binding var solidCleanColor: Color

    var body: some View {
        VStack(spacing: Spacing.medium) {
            SliderRow(
                title: "강도",
                value: $intensity,
                range: 0...1,
                displayValue: "\(Int(intensity * 100))%"
            )
            .accessibilityIdentifier("editor.intensitySlider")
            SliderRow(
                title: "범위",
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
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .appShadow(.card)
        .animation(AppAnimation.standard, value: selectedStyle)
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
            Text("색상")
                .font(.appFootnote)
                .foregroundStyle(Color.appLabelSecondary)
            Spacer()
            ColorPicker("", selection: $color, supportsOpacity: false)
                .labelsHidden()
                .onChange(of: color) { _, _ in AppHaptics.selection() }
        }
    }
}
