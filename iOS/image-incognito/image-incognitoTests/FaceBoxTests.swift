//
//  FaceBoxTests.swift
//  image-incognitoTests
//
//  Unit tests for the FaceBox detection DTO.
//

import Testing
import UIKit
@testable import image_incognito

@Suite("FaceBox")
struct FaceBoxTests {

    @Test("Init stores the id and rect")
    func initStoresValues() {
        let id = UUID()
        let rect = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        let face = FaceBox(id: id, rect: rect)

        #expect(face.id == id)
        #expect(face.rect == rect)
    }

    @Test("Each FaceBox gets a unique id by default")
    func uniqueIds() {
        let face1 = FaceBox(rect: .zero)
        let face2 = FaceBox(rect: .zero)

        #expect(face1.id != face2.id)
    }

    @Test("FaceBox equality is value based")
    func equality() {
        let id = UUID()
        let rect = CGRect(x: 0.2, y: 0.2, width: 0.2, height: 0.2)

        #expect(FaceBox(id: id, rect: rect) == FaceBox(id: id, rect: rect))
        #expect(FaceBox(id: id, rect: rect) != FaceBox(rect: rect))
        #expect(FaceBox(id: id, rect: rect) != FaceBox(id: id, rect: .zero))
    }

    @Test("rect is mutable for detection post-processing")
    func rectMutation() {
        var face = FaceBox(rect: .zero)
        face.rect = CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1)

        #expect(face.rect == CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1))
    }
}
