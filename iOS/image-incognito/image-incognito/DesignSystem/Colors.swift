//
//  Colors.swift
//  image-incognito
//
//  Design System – Color Tokens
//  Primary: #5E5CE6 (Indigo) / BG: #F2F2F7 / Dark BG: #1C1C1E
//

import SwiftUI

extension Color {

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
