//
//  Colors.swift
//  image-incognito
//
//  Design System – Color Tokens
//  Primary: #5E5CE6 (Indigo) / BG: #F2F2F7 / Dark BG: #1C1C1E
//

import SwiftUI

extension Color {

    // MARK: - Brand

    /// Primary accent – Indigo #5E5CE6
    static let appPrimary = Color("AppPrimary")

    // MARK: - Backgrounds

    /// Main background – System Gray 6 (#F2F2F7) / Dark: Deep Gray (#1C1C1E)
    static let appBackground = Color("AppBackground")

    /// Secondary background – grouped table / card surface
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

// MARK: - UIColor convenience (for use outside SwiftUI)

extension UIColor {
    /// Primary accent – Indigo #5E5CE6
    static let appPrimary = UIColor(named: "AppPrimary") ?? UIColor(red: 0.369, green: 0.361, blue: 0.902, alpha: 1)
}
