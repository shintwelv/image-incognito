//
//  ShareIntegrationTests.swift
//  image-incognitoTests
//
//  Unit tests for system share & external app image handoff integration.
//

import Testing
import UIKit
@testable import image_incognito

@MainActor
@Suite("ShareIntegration")
struct ShareIntegrationTests {

    @Test("IncomingImageStore starts empty")
    func storeStartsEmpty() {
        let store = IncomingImageStore()
        #expect(store.pendingImages.isEmpty)
    }

    @Test("IncomingImageStore stores received images")
    func storeStoresImages() {
        let store = IncomingImageStore()
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        store.pendingImages = [testImage]

        #expect(store.pendingImages.count == 1)
    }

    @Test("IncomingImageStore clears pending images when reset")
    func storeResetsCleanly() {
        let store = IncomingImageStore()
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        store.pendingImages = [testImage]
        #expect(!store.pendingImages.isEmpty)

        store.pendingImages = []
        #expect(store.pendingImages.isEmpty)
    }
}
