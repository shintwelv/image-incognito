//
//  FaceBoxTests.swift
//  image-incognitoTests
//
//  Unit tests for the FaceBox domain entity.
//

import Testing
import UIKit
@testable import image_incognito

@Suite("FaceBox")
struct FaceBoxTests {

    @Test("Default init: isMasked is true and style is blurredGlass")
    func defaultInit() {
        let rect = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        let face = FaceBox(rect: rect)

        #expect(face.rect == rect)
        #expect(face.isMasked == true)
        #expect(face.style == .blurredGlass)
    }

    @Test("Custom init stores all provided values")
    func customInit() {
        let id = UUID()
        let rect = CGRect(x: 0.5, y: 0.5, width: 0.2, height: 0.2)
        let face = FaceBox(id: id, rect: rect, isMasked: false, style: .pixelArt)

        #expect(face.id == id)
        #expect(face.rect == rect)
        #expect(face.isMasked == false)
        #expect(face.style == .pixelArt)
    }

    @Test("isMasked can be toggled")
    func maskToggle() {
        var face = FaceBox(rect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5))

        #expect(face.isMasked == true)
        face.isMasked.toggle()
        #expect(face.isMasked == false)
        face.isMasked.toggle()
        #expect(face.isMasked == true)
    }

    @Test("Each FaceBox gets a unique id by default")
    func uniqueIds() {
        let face1 = FaceBox(rect: .zero)
        let face2 = FaceBox(rect: .zero)

        #expect(face1.id != face2.id)
    }

    @Test("style can be changed via mutation")
    func styleChange() {
        var face = FaceBox(rect: .zero)
        #expect(face.style == .blurredGlass)

        face.style = .solidClean
        #expect(face.style == .solidClean)

        face.style = .pixelArt
        #expect(face.style == .pixelArt)
    }
}
