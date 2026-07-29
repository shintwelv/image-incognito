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
    case crystalize
    case solidClean
    case emojiOverlay

    var id: String { rawValue }

    var label: String {
        switch self {
        case .blurredGlass: return "style.blurredGlass"
        case .pixelArt:     return "style.pixelArt"
        case .crystalize:   return "style.crystalize"
        case .solidClean:   return "style.solidClean"
        case .emojiOverlay: return "style.emojiOverlay"
        }
    }

    var icon: String {
        switch self {
        case .blurredGlass: return "drop.halffull"
        case .pixelArt:     return "square.grid.3x3.fill"
        case .crystalize:   return "diamond.fill"
        case .solidClean:   return "circle.fill"
        case .emojiOverlay: return "face.smiling"
        }
    }
}
