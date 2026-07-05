//
//  IncomingImageStoreTests.swift
//  image-incognitoTests
//

import XCTest
@testable import image_incognito

@MainActor
final class IncomingImageStoreTests: XCTestCase {
    
    func testIncomingImageStoreInitialization() {
        let store = IncomingImageStore()
        XCTAssertTrue(store.pendingImages.isEmpty, "Store should initialize with empty pendingImages array.")
    }
    
    func testIncomingImageStoreMutation() {
        let store = IncomingImageStore()
        let testImage = UIImage()
        
        store.pendingImages.append(testImage)
        
        XCTAssertEqual(store.pendingImages.count, 1)
        XCTAssertEqual(store.pendingImages.first, testImage)
        
        store.pendingImages.removeAll()
        XCTAssertTrue(store.pendingImages.isEmpty)
    }
}
