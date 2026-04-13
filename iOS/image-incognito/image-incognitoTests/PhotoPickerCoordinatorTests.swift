//
//  PhotoPickerCoordinatorTests.swift
//  image-incognitoTests
//
//  Unit tests for PhotoPickerRepresentable image loading: verifies ordering and
//  filtering of concurrently decoded picker items.
//

import Testing
import UIKit
@testable import image_incognito

@Suite("PhotoPickerRepresentable")
struct PhotoPickerCoordinatorTests {

    @Test("loadImages preserves the original picker order even when loaders finish out of order")
    func loadImagesPreservesOriginalOrder() async {
        let first = makeTestImage(size: CGSize(width: 80, height: 40), color: .systemRed)
        let second = makeTestImage(size: CGSize(width: 40, height: 80), color: .systemGreen)
        let images = await PhotoPickerRepresentable.loadImages(from: [
            MockImageLoader(canLoad: true, image: first, delayNanoseconds: 50_000_000),
            MockImageLoader(canLoad: true, image: second, delayNanoseconds: 0),
        ])

        #expect(images.count == 2)
        #expect(images[0].size == first.size)
        #expect(images[1].size == second.size)
    }

    @Test("loadImages skips loaders that cannot produce UIImage values")
    func loadImagesSkipsUnsupportedItems() async {
        let image = makeTestImage(size: CGSize(width: 120, height: 90))
        let images = await PhotoPickerRepresentable.loadImages(from: [
            MockImageLoader(canLoad: false, image: nil),
            MockImageLoader(canLoad: true, image: image),
            MockImageLoader(canLoad: true, image: nil),
        ])

        #expect(images.count == 1)
        #expect(images[0].size == image.size)
    }

    @Test("loadImages returns an empty array when no loaders can produce an image")
    func loadImagesReturnsEmptyArrayWhenAllLoadersFail() async {
        let images = await PhotoPickerRepresentable.loadImages(from: [
            MockImageLoader(canLoad: false, image: nil),
            MockImageLoader(canLoad: true, image: nil),
        ])

        #expect(images.isEmpty)
    }
}

private struct MockImageLoader: PhotoPickerImageLoading {
    let canLoad: Bool
    let image: UIImage?
    let delayNanoseconds: UInt64

    init(
        canLoad: Bool,
        image: UIImage?,
        delayNanoseconds: UInt64 = 0
    ) {
        self.canLoad = canLoad
        self.image = image
        self.delayNanoseconds = delayNanoseconds
    }

    func canLoadImage() -> Bool {
        canLoad
    }

    func loadImage() async -> UIImage? {
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return image
    }
}
