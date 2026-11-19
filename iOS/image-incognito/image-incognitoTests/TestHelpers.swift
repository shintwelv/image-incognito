//
//  TestHelpers.swift
//  image-incognitoTests
//
//  Shared utilities for creating synthetic UIImages used across all unit tests.
//

import CoreGraphics
import UIKit

func makeTestImage(
    size: CGSize = CGSize(width: 100, height: 100),
    color: UIColor = .systemBlue
) -> UIImage {
    UIGraphicsImageRenderer(size: size).image { ctx in
        color.setFill()
        ctx.fill(CGRect(origin: .zero, size: size))
    }
}

/// Compares two rects component-wise, tolerating floating-point drift from
/// clamping/intersection math.
nonisolated func rectsAreEqual(
    _ lhs: CGRect,
    _ rhs: CGRect,
    accuracy: CGFloat = 0.0001
) -> Bool {
    abs(lhs.origin.x - rhs.origin.x) < accuracy
        && abs(lhs.origin.y - rhs.origin.y) < accuracy
        && abs(lhs.size.width - rhs.size.width) < accuracy
        && abs(lhs.size.height - rhs.size.height) < accuracy
}
