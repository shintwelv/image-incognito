//
//  Colors.swift
//  image-incognito
//
//  Design System – Color Tokens
//  All semantic colors live here. Brand/background colors are backed by
//  named color sets in Assets.xcassets (supports automatic dark mode).
//
//  Asset Catalog reference:
//    AppPrimary   → #5E5CE6 (Indigo)  / Dark: #6E6CF6
//    AppBackground→ #F2F2F7           / Dark: #1C1C1E (Deep Gray)
//    AppSurface   → systemBackground  / Dark: #242424
//

import SwiftUI

extension Color {

    // MARK: - Brand

    /// App accent / CTA color. Asset: "AppPrimary" (#5E5CE6 / dark #6E6CF6).
    static let appPrimary = Color("AppPrimary")

    // MARK: - Background

    /// Screen background. Asset: "AppBackground" (#F2F2F7 / dark #1C1C1E).
    static let appBackground = Color("AppBackground")

    /// Card / sheet surface. Asset: "AppSurface" (systemBackground / dark #242424).
    static let appSurface = Color("AppSurface")

    // MARK: - Labels

    /// Primary label (adapts to dark mode automatically)
    static let appLabelPrimary = Color(uiColor: .label)

    /// Secondary label
    static let appLabelSecondary = Color(uiColor: .secondaryLabel)

    /// Tertiary label
    static let appLabelTertiary = Color(uiColor: .tertiaryLabel)

    // MARK: - Semantic

    /// Destructive / error
    static let appDestructive = Color(uiColor: .systemRed)

    /// Success
    static let appSuccess = Color(uiColor: .systemGreen)

    // MARK: - Separator

    static let appSeparator = Color(uiColor: .separator)
}
