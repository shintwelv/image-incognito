///
//  Tokens.swift
//  image-incognito
//
//  Design System – Spacing, Radius & Shadow Tokens
//

import SwiftUI

// MARK: - Spacing

enum Spacing {
    /// 4pt
    static let xxSmall: CGFloat = 4
    /// 8pt
    static let xSmall: CGFloat = 8
    /// 12pt
    static let small: CGFloat = 12
    /// 16pt
    static let medium: CGFloat = 16
    /// 20pt
    static let large: CGFloat = 20
    /// 24pt
    static let xLarge: CGFloat = 24
    /// 32pt
    static let xxLarge: CGFloat = 32
    /// 40pt
    static let xxxLarge: CGFloat = 40
}

// MARK: - Corner Radius  (Continuous / squircle style)

enum Radius {
    /// 12pt – small UI elements (toggles, chips, text fields)
    static let element: CGFloat = 12
    /// 16pt – buttons
    static let button: CGFloat = 16
    /// 20pt – cards and sheets
    static let card: CGFloat = 20
    /// Full pill – fully rounded elements
    static let pill: CGFloat = 999
}

// MARK: - Shadows

struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension AppShadow {
    /// Subtle ambient shadow for cards
    static let card = AppShadow(
        color: Color.black.opacity(0.08),
        radius: 12,
        x: 0,
        y: 4
    )
    /// Lifted shadow for floating elements (e.g. FAB)
    static let floating = AppShadow(
        color: Color.black.opacity(0.16),
        radius: 20,
        x: 0,
        y: 8
    )
}

// MARK: - View extension

extension View {
    /// Apply a design-system shadow preset.
    func appShadow(_ shadow: AppShadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}

// MARK: - Animation

enum AppAnimation {
    /// Standard spring used for most interactive transitions.
    static let standard: Animation = .spring(response: 0.35, dampingFraction: 0.75)
    /// Fast spring for immediate feedback elements.
    static let snappy: Animation = .spring(response: 0.25, dampingFraction: 0.8)
    /// Slow ease for decorative / loading transitions.
    static let gentle: Animation = .easeInOut(duration: 0.45)
}

// MARK: - Haptics

enum AppHaptics {
    /// Light feedback – face detected, toggle changed.
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    /// Medium feedback – masking applied.
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    /// Success – save completed.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    /// Selection – slider tick.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
