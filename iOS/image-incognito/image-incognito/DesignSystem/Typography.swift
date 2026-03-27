//
//  Typography.swift
//  image-incognito
//
//  Design System – Typography Tokens
//  Font: San Francisco (iOS System Font)
//  Title: 28pt Bold / Body: 17pt Regular
//

import SwiftUI

// MARK: - Font tokens

extension Font {

    // MARK: Display

    /// 34pt Bold – large hero text
    static let appDisplay: Font = .system(size: 34, weight: .bold, design: .default)

    // MARK: Titles

    /// 28pt Bold – screen title
    static let appTitle: Font = .system(size: 28, weight: .bold, design: .default)

    /// 22pt Semibold – section title
    static let appTitle2: Font = .system(size: 22, weight: .semibold, design: .default)

    /// 20pt Semibold – card / panel title
    static let appTitle3: Font = .system(size: 20, weight: .semibold, design: .default)

    // MARK: Body

    /// 17pt Regular – primary body text
    static let appBody: Font = .system(size: 17, weight: .regular, design: .default)

    /// 17pt Semibold – emphasized body
    static let appBodyEmphasized: Font = .system(size: 17, weight: .semibold, design: .default)

    // MARK: Supporting

    /// 15pt Regular – secondary / subheadline
    static let appSubheadline: Font = .system(size: 15, weight: .regular, design: .default)

    /// 13pt Regular – footnote
    static let appFootnote: Font = .system(size: 13, weight: .regular, design: .default)

    /// 12pt Regular – caption
    static let appCaption: Font = .system(size: 12, weight: .regular, design: .default)

    /// 11pt Semibold – tab bar label / badge
    static let appCaption2: Font = .system(size: 11, weight: .semibold, design: .default)
}

// MARK: - ViewModifier convenience

struct AppTextStyle: ViewModifier {
    let font: Font
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
    }
}

extension View {
    /// Apply a design-system text style in one call.
    func appTextStyle(_ font: Font, color: Color = .appLabelPrimary) -> some View {
        modifier(AppTextStyle(font: font, color: color))
    }
}
