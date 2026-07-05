//
//  ShareSheetTests.swift
//  image-incognitoTests
//

import XCTest
import SwiftUI
@testable import image_incognito

@MainActor
final class ShareSheetTests: XCTestCase {
    
    func testShareSheetInitialization() {
        let textItem = "Hello World"
        let shareSheet = ShareSheet(items: [textItem])
        
        XCTAssertEqual(shareSheet.items.count, 1)
        XCTAssertEqual(shareSheet.items.first as? String, textItem)
    }
    
    // UIViewControllerRepresentable makeUIViewController is hard to test directly without context
    // but the struct initialization is covered.
}
