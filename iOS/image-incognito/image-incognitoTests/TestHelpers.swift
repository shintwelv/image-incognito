//
//  TestHelpers.swift
//  image-incognitoTests
//
//  Shared utilities for creating synthetic UIImages used across all unit tests.
//

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
