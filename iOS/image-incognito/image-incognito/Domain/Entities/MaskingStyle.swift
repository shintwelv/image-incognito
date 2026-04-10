//
//  MaskingStyle.swift
//  image-incognito
//
//  Domain Entity – Available masking styles for face obfuscation.
//

import Foundation

nonisolated enum MaskingStyle: String, CaseIterable, Identifiable, Sendable {
    case blurredGlass
    case pixelArt
    case solidClean

    var id: String { rawValue }

    var label: String {
        switch self {
        case .blurredGlass: return "Blurred Glass"
        case .pixelArt:     return "Pixel Art"
        case .solidClean:   return "Solid Clean"
        }
    }

    var icon: String {
        switch self {
        case .blurredGlass: return "drop.halffull"
        case .pixelArt:     return "square.grid.3x3.fill"
        case .solidClean:   return "circle.fill"
        }
    }
}
